import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import '../providers/supabase_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeedRepository(client);
});

class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient? _client;
  final _uuid = const Uuid();

  SupabaseClient get _supabase {
    if (_client == null) {
      throw Exception('Supabase not configured');
    }
    return _client!;
  }

  /// Get feed posts
  Future<List<Post>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    final data = await _supabase.rpc(
      'get_feed_posts',
      params: {
        'p_user_id': currentUserId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return (data as List).map((e) {
      final map = e as Map<String, dynamic>;
      return Post(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        imageUrl: map['image_url'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        ingredientKeys: List<String>.from(map['ingredient_keys'] ?? []),
        recipeId: map['recipe_id'] as String?,
        recipeTitle: map['recipe_title'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
        isLiked: map['is_liked'] as bool? ?? false,
        user: UserProfile(
          id: map['user_id'] as String,
          email: '',
          username: map['user_username'] as String?,
          displayName: map['user_display_name'] as String?,
          avatarUrl: map['user_avatar_url'] as String?,
        ),
      );
    }).toList();
  }

  /// Get user's posts
  Future<List<Post>> getUserPosts(String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _supabase
        .from('posts')
        .select('''
          id,
          user_id,
          image_url,
          title,
          description,
          ingredient_keys,
          recipe_id,
          recipe_title,
          created_at,
          profiles!posts_user_id_fkey (
            username,
            display_name,
            avatar_url
          ),
          likes (count),
          comments (count)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final currentUserId = _supabase.auth.currentUser?.id;

    // Check which posts current user has liked
    List<String> likedPostIds = [];
    if (currentUserId != null && data.isNotEmpty) {
      final postIds = (data as List).map((e) => e['id'] as String).toList();
      final likes = await _supabase
          .from('likes')
          .select('post_id')
          .eq('user_id', currentUserId)
          .inFilter('post_id', postIds);
      likedPostIds = (likes as List).map((e) => e['post_id'] as String).toList();
    }

    return (data as List).map((e) {
      final map = e as Map<String, dynamic>;
      final postId = map['id'] as String;
      final profile = map['profiles'] as Map<String, dynamic>?;
      final likesData = map['likes'] as List?;
      final commentsData = map['comments'] as List?;
      
      return Post(
        id: postId,
        userId: map['user_id'] as String,
        imageUrl: map['image_url'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        ingredientKeys: List<String>.from(map['ingredient_keys'] ?? []),
        recipeId: map['recipe_id'] as String?,
        recipeTitle: map['recipe_title'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        likesCount: likesData?.isNotEmpty == true 
            ? (likesData!.first['count'] as num?)?.toInt() ?? 0 
            : 0,
        commentsCount: commentsData?.isNotEmpty == true 
            ? (commentsData!.first['count'] as num?)?.toInt() ?? 0 
            : 0,
        isLiked: likedPostIds.contains(postId),
        user: profile != null ? UserProfile(
          id: map['user_id'] as String,
          email: '',
          username: profile['username'] as String?,
          displayName: profile['display_name'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
        ) : null,
      );
    }).toList();
  }

  /// Create a new post
  Future<Post> createPost({
    required File imageFile,
    required String title,
    String? description,
    List<String>? ingredientKeys,
    String? recipeId,
    String? recipeTitle,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Upload image
    final imageUrl = await _uploadPostImage(imageFile, user.id);

    // Create post
    final postId = _uuid.v4();
    final now = DateTime.now();

    await _supabase.from('posts').insert({
      'id': postId,
      'user_id': user.id,
      'image_url': imageUrl,
      'title': title,
      'description': description,
      'ingredient_keys': ingredientKeys ?? [],
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    return Post(
      id: postId,
      userId: user.id,
      imageUrl: imageUrl,
      title: title,
      description: description,
      ingredientKeys: ingredientKeys ?? [],
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      createdAt: now,
    );
  }

  /// Upload post image to storage
  Future<String> _uploadPostImage(File imageFile, String userId) async {
    final bytes = await imageFile.readAsBytes();
    final fileName = '$userId/${_uuid.v4()}.jpg';

    await _supabase.storage.from(SupabaseConfig.postImagesBucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _supabase.storage
        .from(SupabaseConfig.postImagesBucket)
        .getPublicUrl(fileName);
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('posts').delete().eq('id', postId).eq('user_id', user.id);
  }

  /// Like a post
  Future<void> likePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('likes').insert({
      'user_id': user.id,
      'post_id': postId,
    });
  }

  /// Unlike a post
  Future<void> unlikePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('likes')
        .delete()
        .eq('user_id', user.id)
        .eq('post_id', postId);
  }

  /// Toggle like
  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    if (currentlyLiked) {
      await unlikePost(postId);
      return false;
    } else {
      await likePost(postId);
      return true;
    }
  }
}

/// Feed posts provider
final feedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getFeedPosts();
});

/// User posts provider
final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getUserPosts(userId);
});

/// Feed state notifier for pagination and refresh
class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  FeedNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPosts();
  }

  final FeedRepository _repository;
  int _offset = 0;
  bool _hasMore = true;
  static const _pageSize = 20;

  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    _offset = 0;
    _hasMore = true;

    try {
      final posts = await _repository.getFeedPosts(limit: _pageSize, offset: 0);
      _offset = posts.length;
      _hasMore = posts.length >= _pageSize;
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    
    final currentPosts = state.valueOrNull ?? [];
    
    try {
      final newPosts = await _repository.getFeedPosts(limit: _pageSize, offset: _offset);
      _offset += newPosts.length;
      _hasMore = newPosts.length >= _pageSize;
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e) {
      // Keep current posts on error
    }
  }

  Future<void> refresh() async {
    await loadPosts();
  }

  Future<void> toggleLike(String postId) async {
    final currentPosts = state.valueOrNull ?? [];
    final index = currentPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = currentPosts[index];
    final newLiked = await _repository.toggleLike(postId, post.isLiked);
    
    final updatedPost = post.copyWith(
      isLiked: newLiked,
      likesCount: post.likesCount + (newLiked ? 1 : -1),
    );

    final newPosts = [...currentPosts];
    newPosts[index] = updatedPost;
    state = AsyncValue.data(newPosts);
  }

  Future<void> createPost({
    required File imageFile,
    required String title,
    String? description,
    List<String>? ingredientKeys,
    String? recipeId,
    String? recipeTitle,
  }) async {
    final newPost = await _repository.createPost(
      imageFile: imageFile,
      title: title,
      description: description,
      ingredientKeys: ingredientKeys,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
    );

    final currentPosts = state.valueOrNull ?? [];
    state = AsyncValue.data([newPost, ...currentPosts]);
  }
}

final feedNotifierProvider = StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repository);
});
