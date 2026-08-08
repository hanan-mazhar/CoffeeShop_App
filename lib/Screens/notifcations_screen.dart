import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../Services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1a0a00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d1a00),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => NotificationService().markAllRead(uid),
            child: const Text('Mark All Read',
                style: TextStyle(color: Colors.deepOrange, fontSize: 13)),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text('Please login to view notifications',
                  style: TextStyle(color: Colors.white54)))
          : StreamBuilder<QuerySnapshot>(
              stream: NotificationService().getNotificationsStream(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No notifications yet',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 17)),
                        SizedBox(height: 8),
                        Text('Place an order to receive updates here',
                            style:
                                TextStyle(color: Colors.white30, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final doc  = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final isUnread = data['read'] != true;

                    return _NotifTile(
                      docId:    doc.id,
                      userId:   uid,
                      title:    data['title'] as String? ?? '',
                      body:     data['body']  as String? ?? '',
                      type:     data['type']  as String? ?? 'general',
                      isUnread: isUnread,
                      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String docId;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isUnread;
  final DateTime? createdAt;

  const _NotifTile({
    required this.docId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isUnread,
    this.createdAt,
  });

  IconData get _icon {
    switch (type) {
      case 'new_order':      return Icons.shopping_bag_outlined;
      case 'payment_proof':  return Icons.receipt_outlined;
      case 'order_status':   return Icons.local_shipping_outlined;
      case 'payment_approved': return Icons.check_circle_outline;
      case 'payment_rejected': return Icons.cancel_outlined;
      default:               return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (type) {
      case 'new_order':        return Colors.deepOrange;
      case 'payment_proof':    return Colors.amber;
      case 'order_status':     return Colors.blue;
      case 'payment_approved': return Colors.green;
      case 'payment_rejected': return Colors.red;
      default:                 return Colors.grey;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isUnread) {
          NotificationService().markRead(userId, docId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? Colors.deepOrange.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? Colors.deepOrange.withValues(alpha: 0.35)
                : Colors.white12,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(_timeAgo(createdAt),
                      style: const TextStyle(
                          color: Colors.white30, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}