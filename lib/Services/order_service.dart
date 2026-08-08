import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/order_model.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Place new order → notify admins ───────────────────────────────────────
  Future<String?> placeOrder(OrderModel order) async {
    try {
      final ref = await _db.collection('orders').add(order.toMap());

      // Notify all admins about new order
      await NotificationService().notifyAdminsNewOrder(
        userName: order.userName,
        amount: order.totalAmount,
        orderId: ref.id,
      );

      return ref.id;
    } catch (e) {
      return null;
    }
  }

  // ── Get user orders ───────────────────────────────────────────────────────
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final orders = snap.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // ── Get single order ──────────────────────────────────────────────────────
  Stream<OrderModel?> getOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return OrderModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // ── Admin: Get all orders ─────────────────────────────────────────────────
  Stream<List<OrderModel>> getAllOrders() {
    return _db.collection('orders').snapshots().map((snap) {
      final orders = snap.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // ── Admin: Update order status → notify user ──────────────────────────────
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      // Get order first to find userId
      final doc = await _db.collection('orders').doc(orderId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final userId = data['userId'] as String? ?? '';

      // Update status in Firestore
      await _db
          .collection('orders')
          .doc(orderId)
          .update({'status': status});

      // Notify user about status change
      if (userId.isNotEmpty) {
        await NotificationService().notifyUserOrderStatus(
          userId: userId,
          status: status,
          orderId: orderId,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
