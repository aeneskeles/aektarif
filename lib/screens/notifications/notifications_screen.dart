import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase_config.dart';
import '../../theme/app_theme.dart';

// Simple notification state for demo
final notificationsReadProvider = StateProvider<bool>((ref) => false);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRead = ref.watch(notificationsReadProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton(
            onPressed: allRead ? null : () {
              ref.read(notificationsReadProvider.notifier).state = true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text(
              'Tümünü Okundu İşaretle',
              style: TextStyle(
                color: allRead ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
      body: !SupabaseConfig.isConfigured
          ? _buildDemoMode(context)
          : _buildNotificationsList(context, ref),
    );
  }

  Widget _buildDemoMode(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 50,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Demo Modu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bildirim özellikleri Supabase yapılandırıldığında kullanılabilir olacak.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, WidgetRef ref) {
    final allRead = ref.watch(notificationsReadProvider);
    
    // Demo notifications
    final demoNotifications = [
      _NotificationItem(
        icon: Icons.favorite,
        iconColor: Colors.red,
        title: 'Yeni beğeni',
        subtitle: 'chef_ali paylaşımınızı beğendi',
        time: '2 dk önce',
        isRead: allRead,
      ),
      _NotificationItem(
        icon: Icons.comment,
        iconColor: AppTheme.primaryColor,
        title: 'Yeni yorum',
        subtitle: 'anne_mutfagi: "Harika görünüyor!"',
        time: '1 saat önce',
        isRead: allRead,
      ),
      _NotificationItem(
        icon: Icons.person_add,
        iconColor: AppTheme.accentColor,
        title: 'Yeni takipçi',
        subtitle: 'lezzet_duragi sizi takip etmeye başladı',
        time: '3 saat önce',
        isRead: true,
      ),
      _NotificationItem(
        icon: Icons.restaurant,
        iconColor: AppTheme.secondaryColor,
        title: 'Yeni tarif önerisi',
        subtitle: 'Malzemelerinize uygun 5 yeni tarif var',
        time: 'Dün',
        isRead: true,
      ),
    ];

    if (demoNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bildirim Yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz bildiriminiz bulunmuyor',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: demoNotifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = demoNotifications[index];
        return _NotificationTile(notification: notification);
      },
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
  });
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final _NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: notification.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            notification.icon,
            color: notification.iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.subtitle),
            const SizedBox(height: 4),
            Text(
              notification.time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          // TODO: Navigate to related content
        },
      ),
    );
  }
}
