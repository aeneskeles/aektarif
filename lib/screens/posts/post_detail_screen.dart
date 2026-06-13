import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../theme/app_theme.dart';
import '../../models/post.dart';
import '../../data/feed_repository.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<PostComment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(feedRepositoryProvider);
      final comments = await repository.getComments(_post.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorumlar yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repository = ref.read(feedRepositoryProvider);
      final newComment = await repository.addComment(_post.id, content);
      
      setState(() {
        _comments.add(newComment);
        _post = _post.copyWith(commentsCount: _post.commentsCount + 1);
        _isSending = false;
      });
      _commentController.clear();
      
      // Update feed state
      ref.read(feedNotifierProvider.notifier).refresh();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum gönderilemedi: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ref.read(feedNotifierProvider.notifier).toggleLike(_post.id);
      setState(() {
        _post = _post.copyWith(
          isLiked: !_post.isLiked,
          likesCount: _post.likesCount + (_post.isLiked ? -1 : 1),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paylaşım',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Image
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      _post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.chipColor,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  ),

                  // Post Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.chipColor,
                              backgroundImage: _post.user?.avatarUrl != null
                                  ? NetworkImage(_post.user!.avatarUrl!)
                                  : null,
                              child: _post.user?.avatarUrl == null
                                  ? const Icon(Icons.person, color: AppTheme.textTertiary)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _post.user?.displayName ?? _post.user?.username ?? 'Anonim',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    timeago.format(_post.createdAt, locale: 'tr'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          _post.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        // Description
                        if (_post.description != null && _post.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _post.description!,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Like & Comment counts
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Row(
                                children: [
                                  Icon(
                                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: _post.isLiked ? Colors.red : AppTheme.textSecondary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_post.likesCount}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppTheme.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_post.commentsCount}',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Comments section title
                        Text(
                          'Yorumlar',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Comments list
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 40,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Henüz yorum yok',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'İlk yorumu sen yap!',
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return _CommentTile(comment: comment);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.chipColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _commentController,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        hintStyle: TextStyle(color: AppTheme.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send,
                          color: AppTheme.primaryColor,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.chipColor,
            backgroundImage: comment.user?.avatarUrl != null
                ? NetworkImage(comment.user!.avatarUrl!)
                : null,
            child: comment.user?.avatarUrl == null
                ? const Icon(Icons.person, size: 16, color: AppTheme.textTertiary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user?.displayName ?? comment.user?.username ?? 'Anonim',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt, locale: 'tr'),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
