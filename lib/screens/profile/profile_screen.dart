import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase_config.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../data/feed_repository.dart';
import '../../data/auth_repository.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../post/create_post_screen.dart';
import 'edit_profile_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!SupabaseConfig.isConfigured) {
      return const _DemoProfileScreen();
    }

    final user = authState.user;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Center(
          child: Text(
            'Giriş yapmanız gerekiyor',
            style: TextStyle(color: context.appTextPrimary),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(currentUserProfileProvider);
    final userPostsAsync = ref.watch(userPostsProvider(user.id));

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profilim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appCardFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: context.appIconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.appCardFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar and Info Row
                    profileAsync.when(
                      data: (profile) => _ProfileHeader(
                        name: profile?.displayName ?? profile?.username ?? 'Kullanıcı',
                        handle: '@${profile?.username ?? 'kullanici'}',
                        bio: profile?.bio ?? 'Lezzet tutkunusu 👨‍🍳',
                        avatarUrl: profile?.avatarUrl,
                      ),
                      loading: () => const _ProfileHeader(
                        name: 'Yükleniyor...',
                        handle: '@kullanici',
                        bio: '',
                      ),
                      error: (error, stackTrace) => _ProfileHeader(
                        name: user.email?.split('@').first ?? 'Kullanıcı',
                        handle: '@kullanici',
                        bio: '',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats
                    _ProfileStatsSection(
                      profileAsync: profileAsync,
                      userPostsAsync: userPostsAsync,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Badges Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROZETLER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.appSectionLabel,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _BadgeItemNew(
                          icon: Icons.star_rounded,
                          label: 'Şef',
                          backgroundColor: context.appCardFill,
                          iconBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          iconColor: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 12),
                        _BadgeItemNew(
                          icon: Icons.emoji_events_rounded,
                          label: 'En İyi',
                          backgroundColor: context.appCardFill,
                          iconBackgroundColor: const Color(0xFFEAB308).withValues(alpha: 0.2),
                          iconColor: const Color(0xFFEAB308),
                        ),
                        const SizedBox(width: 12),
                        _BadgeItemNew(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Trend',
                          backgroundColor: context.appCardFill,
                          iconBackgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.2),
                          iconColor: const Color(0xFFFB923C),
                        ),
                        const SizedBox(width: 12),
                        _BadgeItemNew(
                          icon: Icons.diamond_rounded,
                          label: 'Premium',
                          backgroundColor: context.appCardFill,
                          iconBackgroundColor: context.appOverlayStrong,
                          iconColor: context.appIconColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Posts Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'PAYLAŞIMLARIM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appSectionLabel,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          _UserPostsList(userId: user.id),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Tarif Yükle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _SettingsItem(
              icon: Icons.person_outline_rounded,
              title: 'Profili Düzenle',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _SettingsItem(
              icon: Icons.workspace_premium_outlined,
              title: 'Premiuma Geç',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amberStar.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.amberStar,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Ayarları',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _SettingsItem(
              icon: Icons.dark_mode_outlined,
              title: 'Tema Seçimi',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Koyu',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.language_outlined,
              title: 'Dil Seçimi',
              trailing: Text(
                'Türkçe',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 8),
            Divider(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 8),
            _SettingsItem(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              iconColor: AppTheme.errorColor,
              titleColor: AppTheme.errorColor,
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: context.appSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Çıkış Yap',
                      style: TextStyle(color: context.appTextPrimary),
                    ),
                    content: Text(
                      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'İptal',
                          style: TextStyle(color: AppTheme.textTertiary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(authProvider.notifier).signOut();
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'LezzetPot v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppTheme.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? context.appTextPrimary,
          fontSize: 15,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: AppTheme.textTertiary.withValues(alpha: 0.5),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.emoji,
    required this.label,
    required this.gradientColors,
    required this.borderColor,
  });

  final String emoji;
  final String label;
  final List<Color> gradientColors;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItemNew extends StatelessWidget {
  const _BadgeItemNew({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.isHighlighted = false,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final bool isHighlighted;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted 
              ? Colors.transparent 
              : AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor ??
                  (isHighlighted ? Colors.white : context.appTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.handle,
    required this.bio,
    this.avatarUrl,
  });

  final String name;
  final String handle;
  final String bio;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: avatarUrl == null ? AppTheme.inputColor : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.greenOnline,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.appSurface,
                    width: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                handle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                ),
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatsSection extends StatelessWidget {
  const _ProfileStatsSection({
    required this.profileAsync,
    required this.userPostsAsync,
  });

  final AsyncValue<UserProfile?> profileAsync;
  final AsyncValue<List<Post>> userPostsAsync;

  @override
  Widget build(BuildContext context) {
    final followersCount = profileAsync.valueOrNull?.followersCount ?? 0;
    final followingCount = 0;

    return userPostsAsync.when(
      data: (posts) => _StatsRow(
        postsCount: posts.length,
        likesCount: posts.fold<int>(0, (sum, post) => sum + post.likesCount),
        followersCount: followersCount,
        followingCount: followingCount,
      ),
      loading: () => _StatsRow(
        postsCount: profileAsync.valueOrNull?.postsCount ?? 0,
        likesCount: 0,
        followersCount: followersCount,
        followingCount: followingCount,
      ),
      error: (error, stackTrace) => _StatsRow(
        postsCount: profileAsync.valueOrNull?.postsCount ?? 0,
        likesCount: 0,
        followersCount: followersCount,
        followingCount: followingCount,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.postsCount,
    required this.likesCount,
    required this.followersCount,
    required this.followingCount,
  });

  final int postsCount;
  final int likesCount;
  final int followersCount;
  final int followingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            value: postsCount,
            label: 'Tarif',
            icon: Icons.restaurant_outlined,
          ),
        ),
        Expanded(
          child: _StatItem(
            value: likesCount,
            label: 'Beğeni',
            icon: Icons.favorite_outline,
          ),
        ),
        Expanded(
          child: _StatItem(
            value: followersCount,
            label: 'Takipçi',
            icon: Icons.people_outline,
          ),
        ),
        Expanded(
          child: _StatItem(
            value: followingCount,
            label: 'Takip',
            icon: Icons.person_add_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  String _formatValue(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.appCardFill,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(
            icon,
            size: 14,
            color: context.appIconColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            _formatValue(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPostsList extends ConsumerWidget {
  const _UserPostsList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPostsAsync = ref.watch(userPostsProvider(userId));

    return userPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.inputColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: AppTheme.textTertiary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz paylaşım yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk tarifini paylaşarak başla!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = posts[index];
              return _ProfilePostTile(
                post: post,
                onLike: () {
                  ref.read(feedNotifierProvider.notifier).toggleLike(post.id);
                },
              );
            }, childCount: posts.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.textTertiary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePostTile extends StatelessWidget {
  const _ProfilePostTile({required this.post, required this.onLike});

  final Post post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.inputColor,
                child: Icon(
                  Icons.restaurant,
                  size: 34,
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.deepNavy.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onLike,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.red.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.chat_bubble_outline,
                        color: context.appSectionLabel,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
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

class _DemoProfileScreen extends StatelessWidget {
  const _DemoProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profilim',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: const Column(
                  children: [
                    _ProfileHeader(
                      name: 'Demo Kullanıcı',
                      handle: '@demo',
                      bio: 'Demo modunda geziniyorsun 🍳',
                    ),
                    SizedBox(height: 20),
                    _StatsRow(
                      postsCount: 4,
                      likesCount: 128,
                      followersCount: 56,
                      followingCount: 23,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Demo modunda profil ve paylaşım özellikleri sınırlıdır.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
