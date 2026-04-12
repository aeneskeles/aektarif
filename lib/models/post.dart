import 'user_profile.dart';

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.title,
    this.description,
    this.ingredientKeys = const [],
    this.recipeId,
    this.recipeTitle,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.user,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String title;
  final String? description;
  final List<String> ingredientKeys;
  final String? recipeId;
  final String? recipeTitle;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final UserProfile? user;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ingredientKeys: List<String>.from(json['ingredient_keys'] ?? []),
      recipeId: json['recipe_id'] as String?,
      recipeTitle: json['recipe_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      user: json['user'] != null
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'title': title,
      'description': description,
      'ingredient_keys': ingredientKeys,
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? title,
    String? description,
    List<String>? ingredientKeys,
    String? recipeId,
    String? recipeTitle,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    UserProfile? user,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredientKeys: ingredientKeys ?? this.ingredientKeys,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      user: user ?? this.user,
    );
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.user,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final UserProfile? user;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
