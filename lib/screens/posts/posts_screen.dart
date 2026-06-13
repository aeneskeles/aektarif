import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase_config.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../data/feed_repository.dart';
import '../../models/post.dart';
import '../post/create_post_screen.dart';
import 'post_detail_screen.dart';

class PostsScreen extends ConsumerWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.posts,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.postsSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (!SupabaseConfig.isConfigured)
            SliverFillRemaining(
              child: _PostsEmptyState(strings: strings),
            )
          else
            feedState.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: _PostsEmptyState(strings: strings),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _PostCard(
                            post: post,
                            strings: strings,
                            onLike: () {
                              ref
                                  .read(feedNotifierProvider.notifier)
                                  .toggleLike(post.id);
                            },
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: posts.length,
                    ),
                  ),
                );
              },
              loading: () => SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: _PostsEmptyState(strings: strings),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (SupabaseConfig.isConfigured) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            );
          }
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          strings.share,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PostsEmptyState extends StatelessWidget {
  const _PostsEmptyState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.noPostsYet,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.beFirstToPost,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appTextMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.strings,
    required this.onLike,
    required this.onTap,
  });

  final Post post;
  final AppStrings strings;
  final VoidCallback onLike;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      image: post.user?.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(post.user!.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: post.user?.avatarUrl == null
                          ? context.appInput
                          : null,
                    ),
                    child: post.user?.avatarUrl == null
                        ? Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.user?.displayName ?? strings.anonymousUser,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${post.user?.username ?? 'anonymous'} · ${strings.formatTimeAgo(post.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (post.recipeTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_rounded,
                        size: 13,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.recipeTitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ClipRRect(
              child: Image.network(
                post.imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 280,
                  color: context.appInput,
                  child: Icon(
                    Icons.restaurant,
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    size: 48,
                  ),
                ),
              ),
            ),
            if (post.description != null && post.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  post.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appTextPrimary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  _ActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likesCount}',
                    isActive: post.isLiked,
                    activeColor: Colors.red,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentsCount}',
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? activeColor ?? AppTheme.primaryColor
        : context.appTextMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? AppTheme.primaryColor).withValues(alpha: 0.2)
              : context.appOverlay,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
