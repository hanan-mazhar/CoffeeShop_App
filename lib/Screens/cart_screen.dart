import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Models/order_model.dart';
import '../Services/auth_service.dart';
import '../Services/cart_provider.dart';
import '../Services/cloudinary_service.dart';
import '../Services/order_service.dart';
import '../Services/payment_service.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;
  String _selectedPayment = 'cod'; // 'cod', 'jazzcash', 'easypaisa'

  // ── Place COD Order ────────────────────────────────────────────────────────
  Future<void> _placeOrderCOD(CartProvider cart) async {
    final user = AuthService().currentUser;
    if (user == null) { _snack('Please login first'); return; }

    final userData = await AuthService().getUserData(user.uid);
    if (!mounted) return;
    if (userData == null) { _snack('User data not found'); return; }
    if (userData.address.isEmpty) {
      _snack('Please add a delivery address in your profile');
      return;
    }

    if (!mounted) return;
    setState(() => _placing = true);

    try {
      final order = OrderModel(
        id: '',
        userId: user.uid,
        userName: userData.name,
        userAddress: userData.address,
        userPhone: userData.phone,
        items: List.from(cart.items),
        totalAmount: cart.totalAmount,
        status: 'pending',
        createdAt: DateTime.now(),
        paymentMethod: 'cod',
        paymentStatus: 'pending',
      );

      final orderId = await OrderService().placeOrder(order);
      if (!mounted) return;

      if (orderId != null) {
        cart.clearCart();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
      } else {
        _snack('Order could not be placed. Please try again.');
      }
    } catch (e) {
      if (mounted) _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  // ── Place JazzCash / EasyPaisa Order ──────────────────────────────────────
  Future<void> _placeOrderOnlinePayment(CartProvider cart) async {
    final user = AuthService().currentUser;
    if (user == null) { _snack('Please login first'); return; }

    final userData = await AuthService().getUserData(user.uid);
    if (!mounted) return;
    if (userData == null) { _snack('User data not found'); return; }
    if (userData.address.isEmpty) {
      _snack('Please add a delivery address in your profile');
      return;
    }

    // Get admin payment number
    final paymentNumbers = await PaymentService().getPaymentNumbers();
    final number = _selectedPayment == 'jazzcash'
        ? paymentNumbers['jazzcash']
        : paymentNumbers['easypaisa'];
    final accountName = _selectedPayment == 'jazzcash'
        ? paymentNumbers['jazzcash_name']
        : paymentNumbers['easypaisa_name'];

    if (number == null || number.isEmpty) {
      _snack('Payment number not configured. Please contact admin.');
      return;
    }

    // Show payment instructions dialog — returns transactionId + picked File
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentInstructionsDialog(
        method: _selectedPayment,
        number: number,
        accountName: accountName ?? '',
        amount: cart.totalAmount,
      ),
    );

    if (result == null || !mounted) return;

    if (!mounted) return;
    setState(() => _placing = true);

    try {
      // Upload proof image to Cloudinary
      String proofImageUrl = '';
      final File? proofFile = result['proofFile'] as File?;
      if (proofFile != null) {
        if (mounted) _snack('Uploading payment screenshot...');
        final url = await CloudinaryService.uploadImage(proofFile);
        if (url == null) {
          if (mounted) _snack('Image upload failed. Please try again.');
          return;
        }
        proofImageUrl = url;
      }

      if (!mounted) return;

      // Create order
      final order = OrderModel(
        id: '',
        userId: user.uid,
        userName: userData.name,
        userAddress: userData.address,
        userPhone: userData.phone,
        items: List.from(cart.items),
        totalAmount: cart.totalAmount,
        status: 'awaiting_payment',
        createdAt: DateTime.now(),
        paymentMethod: _selectedPayment,
        paymentStatus: 'proof_submitted',
      );

      final orderId = await OrderService().placeOrder(order);
      if (orderId == null) {
        if (mounted) _snack('Order could not be created. Please try again.');
        return;
      }

      // Submit payment proof
      await PaymentService().submitPaymentProof(
        orderId: orderId,
        userId: user.uid,
        method: _selectedPayment,
        transactionId: result['transactionId'] ?? '',
        proofImageUrl: proofImageUrl,
      );

      if (!mounted) return;
      cart.clearCart();
      _snack('Order placed! Waiting for payment verification ✅');
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));

    } catch (e) {
      if (mounted) _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _checkout(CartProvider cart) {
    if (_selectedPayment == 'cod') {
      _placeOrderCOD(cart);
    } else {
      _placeOrderOnlinePayment(cart);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.deepOrange));
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final sw = MediaQuery.of(context).size.width;

    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: sw * 0.2, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Your cart is empty!',
                style: TextStyle(color: Colors.white54, fontSize: sw * 0.05)),
            const SizedBox(height: 8),
            const Text('Order something ☕',
                style: TextStyle(color: Colors.white30, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Items ────────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(sw * 0.04),
            itemCount: cart.items.length,
            itemBuilder: (context, i) {
              final item = cart.items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(sw * 0.035),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildCartItemImage(item.coffeeImage, sw * 0.16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.coffeeName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: sw * 0.038),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('Rs. ${item.price.toStringAsFixed(0)} each',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _qtyBtn(Icons.remove,
                            () => cart.decreaseQuantity(item.coffeeId)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                        _qtyBtn(
                            Icons.add,
                            () => cart.addItem(OrderItem(
                                  coffeeId: item.coffeeId,
                                  coffeeName: item.coffeeName,
                                  coffeeImage: item.coffeeImage,
                                  price: item.price,
                                ))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Payment + Summary Footer ──────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(sw * 0.05, 16, sw * 0.05, 24),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Method',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _paymentTile(
                      value: 'cod',
                      icon: Icons.money,
                      label: 'Cash on\nDelivery',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _paymentTile(
                      value: 'jazzcash',
                      icon: Icons.account_balance_wallet,
                      label: 'JazzCash',
                      badge: '📱',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _paymentTile(
                      value: 'easypaisa',
                      icon: Icons.phone_android,
                      label: 'EasyPaisa',
                      badge: '💚',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Items:', style: TextStyle(color: Colors.white60)),
                  Text('${cart.itemCount}',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _placing ? null : () => _checkout(cart),
                  child: _placing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedPayment == 'cod'
                                  ? Icons.coffee
                                  : Icons.account_balance_wallet,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedPayment == 'cod'
                                  ? 'Place Order ☕'
                                  : 'Pay Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Smart image widget for cart items: Cloudinary/network → Image.network, else asset
  Widget _buildCartItemImage(String path, double size) {
    if (CloudinaryService.isNetworkUrl(path)) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _imgPlaceholder(size),
        errorBuilder: (_, _, _) => _imgPlaceholder(size),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imgPlaceholder(size),
    );
  }

  Widget _imgPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.deepOrange.withValues(alpha: 0.2),
      child: const Icon(Icons.coffee, color: Colors.deepOrange),
    );
  }

  Widget _paymentTile({
    required String value,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final selected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.deepOrange.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.deepOrange : Colors.white54,
                size: 24),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Text(badge, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: Colors.deepOrange, size: 16),
      ),
    );
  }
}

// ── Payment Instructions Dialog ───────────────────────────────────────────────
class _PaymentInstructionsDialog extends StatefulWidget {
  final String method;
  final String number;
  final String accountName;
  final double amount;

  const _PaymentInstructionsDialog({
    required this.method,
    required this.number,
    required this.accountName,
    required this.amount,
  });

  @override
  State<_PaymentInstructionsDialog> createState() =>
      _PaymentInstructionsDialogState();
}

class _PaymentInstructionsDialogState
    extends State<_PaymentInstructionsDialog> {
  final _txnController = TextEditingController();
  File? _proofImage;
  final bool _submitting = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_txnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter Transaction ID'),
          backgroundColor: Colors.deepOrange));
      return;
    }
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please attach payment screenshot'),
          backgroundColor: Colors.deepOrange));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, {
      'transactionId': _txnController.text.trim(),
      'proofFile': _proofImage,
    });
  }

  @override
  Widget build(BuildContext context) {
    final methodName =
        widget.method == 'jazzcash' ? 'JazzCash' : 'EasyPaisa';
    final methodColor =
        widget.method == 'jazzcash' ? Colors.red : Colors.green;

    return Dialog(
      backgroundColor: const Color(0xFF2d1a00),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: methodColor),
                const SizedBox(width: 8),
                Text('Pay via $methodName',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Instructions box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: methodColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: methodColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send payment to:',
                      style: TextStyle(color: methodColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(widget.number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  if (widget.accountName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, color: methodColor, size: 14),
                        const SizedBox(width: 4),
                        Text(widget.accountName,
                            style: TextStyle(
                                color: methodColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount:',
                          style: TextStyle(color: Colors.white60)),
                      Text('Rs. ${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Steps:',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _step('1', 'Open the $methodName app and send Rs. ${widget.amount.toStringAsFixed(0)}'),
            _step('2', 'Enter the Transaction ID below'),
            _step('3', 'Attach a screenshot of the payment'),
            _step('4', 'Tap Submit — admin will verify and confirm your order'),

            const SizedBox(height: 16),

            // Transaction ID field
            TextField(
              controller: _txnController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Transaction ID',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon:
                    const Icon(Icons.tag, color: Colors.deepOrange, size: 20),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepOrange)),
              ),
            ),
            const SizedBox(height: 12),

            // Screenshot picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: _proofImage != null ? 180 : 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          _proofImage != null ? Colors.green : Colors.white24),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_proofImage!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file,
                              color: Colors.deepOrange, size: 28),
                          SizedBox(height: 6),
                          Text('Tap to attach payment screenshot',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Submit Proof',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }
}