import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../Services/cloudinary_service.dart';
import '../Services/payment_service.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a0a00),
        body: Center(
          child: Text('Please login to view payment history.',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a0a00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d1a00),
        title: const Text('Payment History',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<List<PaymentRecord>>(
        stream: PaymentService().getUserPayments(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange));
          }

          final payments = snap.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No payment history yet',
                      style: TextStyle(color: Colors.white54, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Your payments will appear here',
                      style: TextStyle(color: Colors.white30, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, i) {
              final p = payments[i];
              return _PaymentCard(record: p);
            },
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentRecord record;
  const _PaymentCard({required this.record});

  static const _statusColors = {
    'pending': Colors.orange,
    'proof_submitted': Colors.amber,
    'paid': Colors.green,
    'rejected': Colors.red,
  };

  static const _statusLabels = {
    'pending': 'Pending',
    'proof_submitted': 'Verification Pending',
    'paid': 'Verified ✓',
    'rejected': 'Rejected ✗',
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[record.status] ?? Colors.grey;
    final methodName = record.method == 'jazzcash'
        ? 'JazzCash'
        : record.method == 'easypaisa'
            ? 'EasyPaisa'
            : 'Cash on Delivery';
    final methodIcon = record.method == 'jazzcash'
        ? Icons.account_balance_wallet
        : record.method == 'easypaisa'
            ? Icons.phone_android
            : Icons.money;
    final methodColor =
        record.method == 'jazzcash' ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(methodIcon, color: methodColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${record.id.length >= 8 ? record.id.substring(0, 8).toUpperCase() : record.id.toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(methodName,
                        style: TextStyle(
                            color: methodColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    Text(_formatDate(record.createdAt),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${record.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                        _statusLabels[record.status] ?? record.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),

          if (record.transactionId != null &&
              record.transactionId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text('TXN: ${record.transactionId}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],

          // Show proof thumbnail — now uses Cloudinary URL via Image.network
          if (record.proofImageUrl != null &&
              record.proofImageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.image_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                const Text('Payment screenshot submitted',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _viewProof(context, record.proofImageUrl!),
                  child: const Text('View',
                      style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _viewProof(BuildContext context, String imageData) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: CloudinaryService.isNetworkUrl(imageData)
              ? Image.network(
                  imageData,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.deepOrange)),
                  errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white30, size: 60)),
                )
              : const Center(
                  child: Text('Image not available',
                      style: TextStyle(color: Colors.white54))),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
