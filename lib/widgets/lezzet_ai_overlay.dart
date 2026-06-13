import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'lezzet_ai_chat_view.dart';

class LezzetAiOverlay extends ConsumerStatefulWidget {
  const LezzetAiOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LezzetAiOverlay> createState() => _LezzetAiOverlayState();
}

class _LezzetAiOverlayState extends ConsumerState<LezzetAiOverlay> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final showFab = !SupabaseConfig.isConfigured ||
        authState.status == AuthStatus.authenticated;

    return Stack(
      children: [
        widget.child,
        if (_isOpen && showFab)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        if (_isOpen && showFab)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            top: MediaQuery.of(context).padding.top + 60,
            child: Material(
              color: Colors.transparent,
              child: LezzetAiChatView(
                onClose: _toggle,
              ),
            ),
          ),
        if (showFab)
          Positioned(
            right: 20,
            bottom: 100,
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isOpen ? 0 : 56,
                height: _isOpen ? 0 : 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isOpen
                    ? null
                    : const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
