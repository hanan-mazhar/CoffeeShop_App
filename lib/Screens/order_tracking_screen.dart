import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/order_model.dart';
import '../Services/auth_service.dart';
import '../Services/order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getUserOrders(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.coffee_outlined, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No orders yet',
                      style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Place your first order!',
                      style: TextStyle(color: Colors.white30, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(0, 6).toUpperCase()}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const Divider(color: Colors.white12, height: 20),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.coffeeName} x${item.quantity}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.deepOrange, fontSize: 14)),
                    ],
                  ),
                )),
            const Divider(color: Colors.white12, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white30, size: 14),
                const SizedBox(width: 4),
                const Text('Track Order', style: TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ---- Order Tracking Detail Screen ----
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Track Your Order', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<OrderModel?>(
        stream: OrderService().getOrder(orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          final order = snap.data;
          if (order == null) {
            return const Center(child: Text('Order not found', style: TextStyle(color: Colors.white54)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange.withValues(alpha: 0.3), Colors.brown.withValues(alpha: 0.3)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      _statusIcon(order.status),
                      const SizedBox(height: 12),
                      Text(_statusTitle(order.status),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_statusDesc(order.status),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Progress tracker
                const Text('Delivery Progress',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _TrackingSteps(currentStatus: order.status),
                const SizedBox(height: 24),

                // Order details
                const Text('Order Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                      _infoRow('Date', DateFormat('dd MMM yyyy').format(order.createdAt)),
                      _infoRow('Time', DateFormat('hh:mm a').format(order.createdAt)),
                      _infoRow('Delivery to', order.userAddress),
                      const Divider(color: Colors.white12),
                      ...order.items.map((item) => _infoRow(
                          '${item.coffeeName} x${item.quantity}',
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}')),
                      const Divider(color: Colors.white12),
                      _infoRow('Total', '\$${order.totalAmount.toStringAsFixed(2)}',
                          bold: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusIcon(String status) {
    final icons = {
      'pending': Icons.hourglass_empty,
      'confirmed': Icons.check_circle_outline,
      'preparing': Icons.coffee_maker,
      'out_for_delivery': Icons.delivery_dining,
      'delivered': Icons.check_circle,
    };
    return Icon(icons[status] ?? Icons.info_outline, color: Colors.deepOrange, size: 60);
  }

  String _statusTitle(String status) {
    const titles = {
      'pending': 'Order Received',
      'confirmed': 'Order Confirmed',
      'preparing': 'Being Prepared',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered!',
    };
    return titles[status] ?? status;
  }

  String _statusDesc(String status) {
    const descs = {
      'pending': 'Your order has been received, will be confirmed soon',
      'confirmed': 'Your order has been confirmed!',
      'preparing': 'Your coffee is being prepared ☕',
      'out_for_delivery': 'Your delivery is on the way 🛵',
      'delivered': 'Enjoy your coffee! ☕😊',
    };
    return descs[status] ?? '';
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

class _TrackingSteps extends StatelessWidget {
  final String currentStatus;
  const _TrackingSteps({required this.currentStatus});

  static const steps = [
    {'status': 'pending', 'label': 'Order Placed', 'icon': Icons.receipt_outlined},
    {'status': 'confirmed', 'label': 'Confirmed', 'icon': Icons.thumb_up_outlined},
    {'status': 'preparing', 'label': 'Preparing', 'icon': Icons.coffee_maker_outlined},
    {'status': 'out_for_delivery', 'label': 'On The Way', 'icon': Icons.delivery_dining},
    {'status': 'delivered', 'label': 'Deliver!', 'icon': Icons.celebration_outlined},
  ];

  int get currentIndex {
    final statuses = steps.map((s) => s['status'] as String).toList();
    return statuses.indexOf(currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = i <= currentIndex;
        final active = i == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? Colors.deepOrange
                        : Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                        color: active ? Colors.deepOrange : Colors.white12,
                        width: active ? 2 : 1),
                  ),
                  child: Icon(step['icon'] as IconData,
                      color: done ? Colors.white : Colors.white30, size: 20),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: i < currentIndex ? Colors.deepOrange : Colors.white12,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                step['label'] as String,
                style: TextStyle(
                  color: done ? Colors.white : Colors.white38,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': Colors.orange,
      'confirmed': Colors.blue,
      'preparing': Colors.purple,
      'out_for_delivery': Colors.teal,
      'delivered': Colors.green,
    };
    final labels = {
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'out_for_delivery': 'On Way',
      'delivered': 'Delivered',
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(labels[status] ?? status,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
