import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../feed/feed_screen.dart';
import '../recipe_book/recipe_book_screen.dart';
import '../posts/posts_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    FeedScreen(),
    RecipeBookScreen(),
    PostsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        strings: strings,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.strings,
    required this.onTap,
  });

  final int currentIndex;
  final AppStrings strings;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: context.appCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: strings.home,
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavBarItem(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              label: strings.recipeBook,
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavBarItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: strings.posts,
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBarItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: strings.profile,
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.1 : 1.0,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? context.appIconColor
                    : context.appTextMuted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? context.appIconColor : context.appTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
