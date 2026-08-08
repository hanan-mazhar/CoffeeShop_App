import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Admin Payment Settings ─────────────────────────────────────────────────
  Future<Map<String, String>> getPaymentNumbers() async {
    try {
      final doc = await _db.collection('settings').doc('payment').get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'jazzcash': data['jazzcash'] ?? '',
          'jazzcash_name': data['jazzcash_name'] ?? '',
          'easypaisa': data['easypaisa'] ?? '',
          'easypaisa_name': data['easypaisa_name'] ?? '',
        };
      }
      return {
        'jazzcash': '',
        'jazzcash_name': '',
        'easypaisa': '',
        'easypaisa_name': ''
      };
    } catch (e) {
      return {
        'jazzcash': '',
        'jazzcash_name': '',
        'easypaisa': '',
        'easypaisa_name': ''
      };
    }
  }

  Future<void> updatePaymentNumbers({
    required String jazzcash,
    required String jazzcashName,
    required String easypaisa,
    required String easypaisaName,
  }) async {
    await _db.collection('settings').doc('payment').set({
      'jazzcash': jazzcash,
      'jazzcash_name': jazzcashName,
      'easypaisa': easypaisa,
      'easypaisa_name': easypaisaName,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<Map<String, String>> paymentNumbersStream() {
    return _db
        .collection('settings')
        .doc('payment')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'jazzcash': '',
          'jazzcash_name': '',
          'easypaisa': '',
          'easypaisa_name': ''
        };
      }
      final data = doc.data()!;
      return {
        'jazzcash': data['jazzcash'] ?? '',
        'jazzcash_name': data['jazzcash_name'] ?? '',
        'easypaisa': data['easypaisa'] ?? '',
        'easypaisa_name': data['easypaisa_name'] ?? '',
      };
    });
  }

  // ── Submit Payment Proof → notify admins ───────────────────────────────────
  Future<void> submitPaymentProof({
    required String orderId,
    required String userId,
    required String method,
    required String transactionId,
    required String proofImageUrl,
  }) async {
    // Get order amount and user name for notification
    String userName = '';
    double amount = 0;
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        userName = data['userName'] ?? '';
        amount = (data['totalAmount'] ?? 0).toDouble();
      }
    } catch (_) {}

    // Update Firestore
    await _db.collection('orders').doc(orderId).update({
      'paymentMethod': method,
      'paymentStatus': 'proof_submitted',
      'transactionId': transactionId,
      'proofImageUrl': proofImageUrl,
      'proofImageBase64': FieldValue.delete(),
      'proofSubmittedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Notify all admins
    await NotificationService().notifyAdminsPaymentProof(
      userName: userName,
      method: method,
      amount: amount,
    );
  }

  // ── Admin: Verify or Reject Payment → notify user ─────────────────────────
  Future<void> verifyPayment(String orderId, bool approved) async {
    // Get order details for notification
    String userId = '';
    double amount = 0;
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        userId = data['userId'] ?? '';
        amount = (data['totalAmount'] ?? 0).toDouble();
      }
    } catch (_) {}

    // Update Firestore
    await _db.collection('orders').doc(orderId).update({
      'paymentStatus': approved ? 'paid' : 'rejected',
      if (approved) 'status': 'confirmed',
      'verifiedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Notify user
    if (userId.isNotEmpty) {
      if (approved) {
        await NotificationService().notifyUserPaymentApproved(
          userId: userId,
          amount: amount,
        );
      } else {
        await NotificationService().notifyUserPaymentRejected(
          userId: userId,
          amount: amount,
        );
      }
    }
  }

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<List<PaymentRecord>> getUserPayments(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .where((d) => d.data()['paymentMethod'] != 'cod')
          .map((doc) => PaymentRecord.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<PaymentRecord>> getPendingProofs() {
    return _db
        .collection('orders')
        .where('paymentStatus', isEqualTo: 'proof_submitted')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PaymentRecord.fromMap(doc.data(), doc.id))
            .toList());
  }
}

class PaymentRecord {
  final String id;
  final String userId;
  final double amount;
  final String method;
  final String status;
  final String? transactionId;
  final String? proofImageUrl;
  final DateTime createdAt;

  PaymentRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.proofImageUrl,
    required this.createdAt,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> map, String id) {
    return PaymentRecord(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['totalAmount'] ?? 0).toDouble(),
      method: map['paymentMethod'] ?? 'cod',
      status: map['paymentStatus'] ?? 'pending',
      transactionId: map['transactionId'],
      proofImageUrl: map['proofImageUrl'] ?? map['proofImageBase64'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
