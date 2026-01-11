import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// In-app Notifications for Niramana Setu
// - Shared mock list
// - Badge helpers
// - Glassmorphism list UI

class AppNotification {
  final String id;
  final String title;
  final String role; // Engineer / Manager / Owner
  final DateTime timestamp;
  final IconData icon;
  bool unread;

  AppNotification({
    required this.id,
    required this.title,
    required this.role,
    required this.timestamp,
    required this.icon,
    this.unread = true,
  });
}

// Shared mock list (can be replaced by repository later)
final List<AppNotification> notificationsMock = [
  AppNotification(
    id: 'NTF-001',
    title: 'DPR approved by Engineer',
    role: 'Manager',
    timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
    icon: Icons.assignment_turned_in_rounded,
  ),
  AppNotification(
    id: 'NTF-002',
    title: 'Material request rejected',
    role: 'Manager',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    icon: Icons.cancel_schedule_send_rounded,
  ),
  AppNotification(
    id: 'NTF-003',
    title: 'Issue assigned for verification',
    role: 'Manager',
    timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 20)),
    icon: Icons.report_gmailerrorred_rounded,
    unread: false,
  ),
  AppNotification(
    id: 'NTF-004',
    title: 'New project update shared',
    role: 'Owner',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    icon: Icons.notifications_active_rounded,
    unread: false,
  ),
];

// Badge helpers
int getUnreadCount({String? role}) {
  if (role == null) return notificationsMock.where((n) => n.unread).length;
  return notificationsMock.where((n) => n.unread && n.role.toLowerCase() == role.toLowerCase()).length;
}

void markAllRead({String? role}) {
  for (final n in notificationsMock) {
    if (role == null || n.role.toLowerCase() == role.toLowerCase()) {
      n.unread = false;
    }
  }
}

String formatRelative(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${t.day.toString().padLeft(2, '0')}-${t.month.toString().padLeft(2, '0')}-${t.year}';
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List<AppNotification>.from(notificationsMock)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              markAllRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            child: const Text('Mark all read'),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NotificationCard(n: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification n;
  const _NotificationCard({required this.n});

  Color get roleColor {
    switch (n.role.toLowerCase()) {
      case 'engineer':
        return const Color(0xFF2563EB);
      case 'manager':
        return const Color(0xFF7C3AED);
      case 'owner':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: const Color(0xFF7A5AF8).withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF136DEC), Color(0xFF7A5AF8)]),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF136DEC).withValues(alpha: 0.25), blurRadius: 14),
                      ],
                    ),
                    child: Icon(n.icon, color: Colors.white),
                  ),
                  if (n.unread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.35), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: roleColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(n.role, style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Text(formatRelative(n.timestamp), style: const TextStyle(color: Color(0xFF4B5563))),
                      ],
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

class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF136DEC), Color(0xFF7A5AF8), Colors.white]
              .map((c) => c.withValues(alpha: 0.12))
              .toList(),
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

// Usage notes:
// - To open the center: Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
// - To show a badge on dashboards: use getUnreadCount() and draw a small red circle with the count near your bell icon.
