import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIRESTORE NOTIFICATION SYSTEM
//
// Firestore path:
//   notifications/{userId}/messages/{autoId}
//   { title, body, type, read: false, createdAt }
//
// startListening() → sirf NEW docs pe local popup show karta hai
//                    read: false rehne deta hai taake in-app list mein dikhe
//
// getNotificationsStream() → in-app bell screen ke liye saari notifications
// markRead() / markAllRead() → user ne dekh liya
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'coffee_orders';
  static const _channelName = 'Coffee Shop Orders';

  // Track which doc IDs we already popped — prevents re-popping on app restart
  final Set<String> _shown = {};

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(const InitializationSettings(
        android: android, iOS: ios));

    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Order & payment updates',
            importance: Importance.high,
          ));
    }
  }

  // ── Start listening — shows OS popup for NEW docs only ───────────────────
  // Does NOT mark as read → in-app list still shows unread badge
  void startListening(String userId) {
    debugPrint('[Notif] Listening for $userId');
    _shown.clear(); // reset on new login

    _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (_shown.contains(docId)) continue; // already shown this session
          _shown.add(docId);

          final data = change.doc.data() as Map<String, dynamic>;
          // Sirf unread pe popup
          if (data['read'] == true) continue;

          final title = data['title'] as String? ?? 'Coffee Shop';
          final body  = data['body']  as String? ?? '';
          _showLocal(title: title, body: body, id: docId.hashCode);
          // ❌ mark-as-read NAHI karte — in-app list mein rehne do
        }
      }
    });
  }

  // ── OS popup ─────────────────────────────────────────────────────────────
  Future<void> _showLocal({
    required String title,
    required String body,
    required int id,
  }) async {
    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Write notification to a specific user ─────────────────────────────────
  Future<void> _sendToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      await _db
          .collection('notifications')
          .doc(userId)
          .collection('messages')
          .add({
        'title':     title,
        'body':      body,
        'type':      type,
        'read':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[Notif] Sent to $userId → $title');
    } catch (e) {
      debugPrint('[Notif] Error: $e');
    }
  }

  // ── Write notification to ALL admins ─────────────────────────────────────
  Future<void> _sendToAdmins({
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      for (final doc in snap.docs) {
        await _sendToUser(userId: doc.id, title: title, body: body, type: type);
      }
    } catch (e) {
      debugPrint('[Notif] Admin send error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC TRIGGER METHODS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> notifyAdminsNewOrder({
    required String userName,
    required double amount,
    required String orderId,
  }) =>
      _sendToAdmins(
        title: '☕ New Order Received!',
        body:  '$userName ne Rs. ${amount.toStringAsFixed(0)} ka order diya',
        type:  'new_order',
      );

  Future<void> notifyAdminsPaymentProof({
    required String userName,
    required String method,
    required double amount,
  }) {
    final m = method == 'jazzcash' ? 'JazzCash' : 'EasyPaisa';
    return _sendToAdmins(
      title: '💳 Payment Proof Submitted',
      body:  '$userName ne $m proof bheja — Rs. ${amount.toStringAsFixed(0)}',
      type:  'payment_proof',
    );
  }

  Future<void> notifyUserOrderStatus({
    required String userId,
    required String status,
    required String orderId,
  }) {
    const msgs = {
      'confirmed':        ('✅ Order Confirm!',        'Tumhara order confirm ho gaya, tayyari ho rahi hai!'),
      'preparing':        ('👨‍🍳 Tayyari Ho Rahi Hai', 'Tumhari coffee fresh ban rahi hai!'),
      'out_for_delivery': ('🛵 Raste Mein Hai!',       'Order aa raha hai, ready raho!'),
      'delivered':        ('🎉 Order Deliver!',        'Coffee mil gayi! Mazay karo ☕'),
      'cancelled':        ('❌ Order Cancel',          'Tumhara order cancel ho gaya. Help ke liye contact karo.'),
    };
    final msg = msgs[status];
    if (msg == null) return Future.value();
    return _sendToUser(
      userId: userId,
      title:  msg.$1,
      body:   msg.$2,
      type:   'order_status',
    );
  }

  Future<void> notifyUserPaymentApproved({
    required String userId,
    required double amount,
  }) =>
      _sendToUser(
        userId: userId,
        title:  '✅ Payment Verify!',
        body:   'Rs. ${amount.toStringAsFixed(0)} payment verify ho gayi. Order confirm!',
        type:   'payment_approved',
      );

  Future<void> notifyUserPaymentRejected({
    required String userId,
    required double amount,
  }) =>
      _sendToUser(
        userId: userId,
        title:  '❌ Payment Reject',
        body:   'Rs. ${amount.toStringAsFixed(0)} ka proof reject hua. Dobara submit karo.',
        type:   'payment_rejected',
      );

  // ════════════════════════════════════════════════════════════════════════
  // IN-APP LIST HELPERS
  // ════════════════════════════════════════════════════════════════════════

  /// Saari notifications stream (unread + read) — NotificationsScreen ke liye
  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Unread count — bell badge ke liye
  Stream<int> unreadCountStream(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Single notification ko read mark karo
  Future<void> markRead(String userId, String docId) async {
    await _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .doc(docId)
        .update({'read': true});
  }

  /// Sab ko read mark karo
  Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}