import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/lezzet_ai_chat_view.dart';

class ChefAssistantScreen extends StatelessWidget {
  const ChefAssistantScreen({super.key});

  static const _backgroundColor = Color(0xFF0A1628);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _backgroundColor,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: LezzetAiChatView(
            mode: LezzetAiChatMode.fullScreen,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
