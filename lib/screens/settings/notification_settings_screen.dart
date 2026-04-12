import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../theme/app_theme.dart';

// Notification settings provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettings {
  final bool likesEnabled;
  final bool commentsEnabled;
  final bool followsEnabled;
  final bool recipeSuggestionsEnabled;
  final bool pushEnabled;
  final bool emailEnabled;

  const NotificationSettings({
    this.likesEnabled = true,
    this.commentsEnabled = true,
    this.followsEnabled = true,
    this.recipeSuggestionsEnabled = true,
    this.pushEnabled = true,
    this.emailEnabled = false,
  });

  NotificationSettings copyWith({
    bool? likesEnabled,
    bool? commentsEnabled,
    bool? followsEnabled,
    bool? recipeSuggestionsEnabled,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationSettings(
      likesEnabled: likesEnabled ?? this.likesEnabled,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      followsEnabled: followsEnabled ?? this.followsEnabled,
      recipeSuggestionsEnabled: recipeSuggestionsEnabled ?? this.recipeSuggestionsEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'likesEnabled': likesEnabled,
    'commentsEnabled': commentsEnabled,
    'followsEnabled': followsEnabled,
    'recipeSuggestionsEnabled': recipeSuggestionsEnabled,
    'pushEnabled': pushEnabled,
    'emailEnabled': emailEnabled,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      likesEnabled: json['likesEnabled'] as bool? ?? true,
      commentsEnabled: json['commentsEnabled'] as bool? ?? true,
      followsEnabled: json['followsEnabled'] as bool? ?? true,
      recipeSuggestionsEnabled: json['recipeSuggestionsEnabled'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  static const _settingsKey = 'notification_settings';

  Future<void> _loadSettings() async {
    try {
      final box = Hive.box('settings');
      final data = box.get(_settingsKey);
      if (data != null) {
        final map = Map<String, dynamic>.from(data as Map);
        state = NotificationSettings.fromJson(map);
      }
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = Hive.box('settings');
      await box.put(_settingsKey, state.toJson());
    } catch (e) {
      // Ignore save errors
    }
  }

  void setLikesEnabled(bool value) {
    state = state.copyWith(likesEnabled: value);
    _saveSettings();
  }

  void setCommentsEnabled(bool value) {
    state = state.copyWith(commentsEnabled: value);
    _saveSettings();
  }

  void setFollowsEnabled(bool value) {
    state = state.copyWith(followsEnabled: value);
    _saveSettings();
  }

  void setRecipeSuggestionsEnabled(bool value) {
    state = state.copyWith(recipeSuggestionsEnabled: value);
    _saveSettings();
  }

  void setPushEnabled(bool value) {
    state = state.copyWith(pushEnabled: value);
    _saveSettings();
  }

  void setEmailEnabled(bool value) {
    state = state.copyWith(emailEnabled: value);
    _saveSettings();
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: ListView(
        children: [
          // Push Notifications Section
          _SectionHeader(title: 'Genel'),
          
          SwitchListTile(
            title: const Text('Push Bildirimleri'),
            subtitle: const Text('Anlık bildirimler al'),
            value: settings.pushEnabled,
            onChanged: notifier.setPushEnabled,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications, color: AppTheme.primaryColor),
            ),
          ),
          
          SwitchListTile(
            title: const Text('E-posta Bildirimleri'),
            subtitle: const Text('Önemli güncellemeleri e-posta ile al'),
            value: settings.emailEnabled,
            onChanged: notifier.setEmailEnabled,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.email, color: AppTheme.accentColor),
            ),
          ),
          
          const Divider(height: 32),
          
          // Activity Section
          _SectionHeader(title: 'Aktivite Bildirimleri'),
          
          SwitchListTile(
            title: const Text('Beğeniler'),
            subtitle: const Text('Paylaşımlarınız beğenildiğinde'),
            value: settings.likesEnabled,
            onChanged: settings.pushEnabled ? notifier.setLikesEnabled : null,
            secondary: const _IconBox(icon: Icons.favorite, color: Colors.red),
          ),
          
          SwitchListTile(
            title: const Text('Yorumlar'),
            subtitle: const Text('Paylaşımlarınıza yorum yapıldığında'),
            value: settings.commentsEnabled,
            onChanged: settings.pushEnabled ? notifier.setCommentsEnabled : null,
            secondary: const _IconBox(icon: Icons.comment, color: Colors.blue),
          ),
          
          SwitchListTile(
            title: const Text('Takipçiler'),
            subtitle: const Text('Yeni takipçi kazandığınızda'),
            value: settings.followsEnabled,
            onChanged: settings.pushEnabled ? notifier.setFollowsEnabled : null,
            secondary: const _IconBox(icon: Icons.person_add, color: Colors.green),
          ),
          
          const Divider(height: 32),
          
          // Recommendations Section
          _SectionHeader(title: 'Öneriler'),
          
          SwitchListTile(
            title: const Text('Tarif Önerileri'),
            subtitle: const Text('Yeni tarif önerileri geldiğinde'),
            value: settings.recipeSuggestionsEnabled,
            onChanged: settings.pushEnabled ? notifier.setRecipeSuggestionsEnabled : null,
            secondary: const _IconBox(icon: Icons.restaurant_menu, color: Colors.orange),
          ),
          
          const SizedBox(height: 24),
          
          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Push bildirimleri kapatıldığında aktivite bildirimleri de devre dışı kalır.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
