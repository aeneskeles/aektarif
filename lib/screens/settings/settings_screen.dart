import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../profile/edit_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context, AppStrings strings) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.aboutApp,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.aboutAppDescription,
              style: TextStyle(
                fontSize: 14,
                color: context.appTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.appVersionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appSectionLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              strings.close,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final settings = ref.watch(appSettingsProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      strings.settings,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          image: profile?.avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profile!.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: profile?.avatarUrl == null
                              ? Colors.white
                              : null,
                        ),
                        child: profile?.avatarUrl == null
                            ? Center(
                                child: Text(
                                  (profile?.displayName ?? 'K')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.displayName ?? strings.user,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${profile?.username ?? 'kullanici'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(title: strings.account),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: strings.editProfile,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  title: strings.goPremium,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      strings.newBadge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () {},
                ),
                const SizedBox(height: 28),
                _SectionHeader(title: strings.appearance),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.theme,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.appTextMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ThemeOption(
                              icon: Icons.wb_sunny_outlined,
                              label: strings.lightTheme,
                              isSelected:
                                  settings.themeVariant == AppThemeVariant.light,
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeVariant(AppThemeVariant.light),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ThemeOption(
                              icon: Icons.water_drop_outlined,
                              label: strings.blueTheme,
                              isSelected:
                                  settings.themeVariant == AppThemeVariant.blue,
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeVariant(AppThemeVariant.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ThemeOption(
                              icon: Icons.nightlight_outlined,
                              label: strings.darkTheme,
                              isSelected:
                                  settings.themeVariant == AppThemeVariant.dark,
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeVariant(AppThemeVariant.dark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(title: strings.language),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _LanguageOption(
                          flag: 'TR',
                          label: strings.turkish,
                          isSelected: settings.languageCode == 'tr',
                          onTap: () => ref
                              .read(appSettingsProvider.notifier)
                              .setLanguage('tr'),
                        ),
                      ),
                      Expanded(
                        child: _LanguageOption(
                          flag: 'GB',
                          label: strings.english,
                          isSelected: settings.languageCode == 'en',
                          onTap: () => ref
                              .read(appSettingsProvider.notifier)
                              .setLanguage('en'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(title: strings.appSection),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: strings.aboutApp,
                  onTap: () => _showAboutDialog(context, strings),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.appSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          strings.logoutConfirmTitle,
                          style: TextStyle(color: context.appTextPrimary),
                        ),
                        content: Text(
                          strings.logoutConfirmMessage,
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              strings.cancel,
                              style: TextStyle(color: AppTheme.textTertiary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                            ),
                            child: Text(strings.logout),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppTheme.errorColor,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          strings.logout,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: context.appSectionLabel,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.appTextSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.appTextPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : context.appOverlay,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : context.appTextSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.appTextSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flag,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : context.appTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.appTextSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
