import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Models/coffee_model.dart';
import '../../Models/order_model.dart';
import '../../Services/auth_service.dart';
import '../../Services/cloudinary_service.dart';
import '../../Services/coffee_service.dart';
import '../../Services/order_service.dart';
import '../../Services/payment_service.dart';
import '../Auth/login_screen.dart';
 import 'dart:convert';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1a0a00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d1a00),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.deepOrange, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Admin Panel',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepOrange),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.deepOrange,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.coffee, size: 18), text: 'Menu'),
            Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Orders'),
            Tab(icon: Icon(Icons.verified, size: 18), text: 'Payments'),
            Tab(icon: Icon(Icons.settings, size: 18), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CoffeeManagementTab(),
          _OrderManagementTab(),
          _PaymentVerificationTab(),
          _PaymentSettingsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _AddCoffeeDialog()),
              backgroundColor: Colors.deepOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                screenWidth < 360 ? 'Add' : 'Add Coffee',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

// ── Payment Settings Tab ──────────────────────────────────────────────────────
class _PaymentSettingsTab extends StatefulWidget {
  const _PaymentSettingsTab();

  @override
  State<_PaymentSettingsTab> createState() => _PaymentSettingsTabState();
}

class _PaymentSettingsTabState extends State<_PaymentSettingsTab> {
  final _jazzController = TextEditingController();
  final _jazzNameController = TextEditingController();
  final _easyController = TextEditingController();
  final _easyNameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    final numbers = await PaymentService().getPaymentNumbers();
    if (mounted) {
      setState(() {
        _jazzController.text = numbers['jazzcash'] ?? '';
        _jazzNameController.text = numbers['jazzcash_name'] ?? '';
        _easyController.text = numbers['easypaisa'] ?? '';
        _easyNameController.text = numbers['easypaisa_name'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await PaymentService().updatePaymentNumbers(
        jazzcash: _jazzController.text.trim(),
        jazzcashName: _jazzNameController.text.trim(),
        easypaisa: _easyController.text.trim(),
        easypaisaName: _easyNameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment numbers updated successfully ✅'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Account Numbers',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
              'These numbers are shown to customers when they choose JazzCash or EasyPaisa.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),

          // JazzCash
          _numberCard(
            icon: Icons.account_balance_wallet,
            color: Colors.red,
            title: 'JazzCash Number',
            controller: _jazzController,
            hint: 'e.g. 03001234567',
            nameController: _jazzNameController,
            nameHint: 'e.g. Muhammad Ali',
          ),
          const SizedBox(height: 16),

          // EasyPaisa
          _numberCard(
            icon: Icons.phone_android,
            color: Colors.green,
            title: 'EasyPaisa Number',
            controller: _easyController,
            hint: 'e.g. 03211234567',
            nameController: _easyNameController,
            nameHint: 'e.g. Muhammad Ali',
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_saving ? 'Saving...' : 'Save Numbers',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberCard({
    required IconData icon,
    required Color color,
    required String title,
    required TextEditingController controller,
    required String hint,
    required TextEditingController nameController,
    required String nameHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30),
              labelText: 'Phone Number',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: nameHint,
              hintStyle: const TextStyle(color: Colors.white30),
              labelText: 'Account Name',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              prefixIcon: Icon(Icons.person_outline, color: color, size: 18),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _jazzController.dispose();
    _jazzNameController.dispose();
    _easyController.dispose();
    _easyNameController.dispose();
    super.dispose();
  }
}

// ── Payment Verification Tab ──────────────────────────────────────────────────
class _PaymentVerificationTab extends StatelessWidget {
  const _PaymentVerificationTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentRecord>>(
      stream: PaymentService().getPendingProofs(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange));
        }
        final proofs = snap.data ?? [];
        if (proofs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified_outlined, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text('No pending payment proofs',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),
                SizedBox(height: 6),
                Text('All payments verified ✅',
                    style: TextStyle(color: Colors.white30, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: proofs.length,
          itemBuilder: (context, i) => _ProofCard(record: proofs[i]),
        );
      },
    );
  }
}

class _ProofCard extends StatelessWidget {
  final PaymentRecord record;
  const _ProofCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final methodColor =
        record.method == 'jazzcash' ? Colors.red : Colors.green;
    final methodName =
        record.method == 'jazzcash' ? 'JazzCash' : 'EasyPaisa';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: methodColor.withValues(alpha: 0.5)),
                ),
                child: Text(methodName,
                    style: TextStyle(
                        color: methodColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Pending Verification',
                    style: TextStyle(color: Colors.orange, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text('Order ID: ${record.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount: Rs. ${record.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.deepOrange, fontWeight: FontWeight.bold)),
              if (record.transactionId != null)
                Text('TXN: ${record.transactionId}',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),

          // Proof image — now loaded from Cloudinary URL
          if (record.proofImageUrl != null &&
              record.proofImageUrl!.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _viewFullImage(context, record.proofImageUrl!),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildProofImage(record.proofImageUrl!),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Tap to expand',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Approve / Reject buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red),
                  onPressed: () => _verify(context, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: () => _verify(context, true),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('Approve',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Renders proof image: Cloudinary URL → Image.network, otherwise legacy base64
  Widget _buildProofImage(String imageData) {
    if (CloudinaryService.isNetworkUrl(imageData)) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange)),
        errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white30, size: 40)),
      );
    }
    // Legacy base64 fallback
    try {
     
      final bytes = base64Decode(imageData);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return const Center(
          child: Icon(Icons.broken_image, color: Colors.white30, size: 40));
    }
  }

  void _viewFullImage(BuildContext context, String imageData) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: CloudinaryService.isNetworkUrl(imageData)
              ? Image.network(imageData,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.deepOrange)))
              : Image.memory(base64Decode(imageData)),
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context, bool approved) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2d1a00),
        title: Text(approved ? 'Approve Payment' : 'Reject Payment',
            style: const TextStyle(color: Colors.white)),
        content: Text(
            approved
                ? 'Approve this payment? The order will move to confirmed.'
                : 'Reject this payment? The customer will need to resubmit.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: approved ? Colors.green : Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(approved ? 'Approve' : 'Reject',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PaymentService().verifyPayment(record.id, approved);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approved
              ? 'Payment approved. Order confirmed ✅'
              : 'Payment rejected ❌'),
          backgroundColor: approved ? Colors.green : Colors.red,
        ));
      }
    }
  }
}

// ── Coffee Management Tab ─────────────────────────────────────────────────────
class _CoffeeManagementTab extends StatelessWidget {
  const _CoffeeManagementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoffeeModel>>(
      stream: CoffeeService().getCoffees(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange));
        }
        final coffees = snap.data ?? [];
        if (coffees.isEmpty) {
          return const Center(
              child: Text('No coffee items. Add one!',
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coffees.length,
          itemBuilder: (context, i) =>
              _AdminCoffeeCard(coffee: coffees[i]),
        );
      },
    );
  }
}

class _AdminCoffeeCard extends StatelessWidget {
  final CoffeeModel coffee;
  const _AdminCoffeeCard({required this.coffee});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildCoffeeImage(coffee.image, 65),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coffee.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(coffee.type,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                Text('Rs. ${coffee.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.deepOrange, fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: coffee.isAvailable,
                  activeThumbColor: Colors.deepOrange,
                  onChanged: (val) => CoffeeService()
                      .updateCoffee(coffee.id, {'isAvailable': val}),
                ),
              ),
              Text(
                coffee.isAvailable ? 'On' : 'Off',
                style: TextStyle(
                    color:
                        coffee.isAvailable ? Colors.green : Colors.red,
                    fontSize: 10),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.orange, size: 20),
            onPressed: () => showDialog(
                context: context,
                builder: (_) => _EditCoffeeDialog(coffee: coffee)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  /// Smart image widget: Cloudinary URL → Image.network, asset → Image.asset
  static Widget _buildCoffeeImage(String path, double size) {
    if (CloudinaryService.isNetworkUrl(path)) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(size),
        errorBuilder: (_, _, _) => _placeholder(size),
      );
    }
    if (path.startsWith('/')) {
      return Image.file(File(path),
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size));
    }
    return Image.asset(path,
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(size));
  }

  static Widget _placeholder(double size) {
    return Container(
        width: size,
        height: size,
        color: Colors.deepOrange.withValues(alpha: 0.2),
        child: const Icon(Icons.coffee, color: Colors.deepOrange));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2d1a00),
        title: const Text('Confirm Delete',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${coffee.name}"? This cannot be undone.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              CoffeeService().deleteCoffee(coffee.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Add Coffee Dialog ─────────────────────────────────────────────────────────
class _AddCoffeeDialog extends StatefulWidget {
  const _AddCoffeeDialog();

  @override
  State<_AddCoffeeDialog> createState() => _AddCoffeeDialogState();
}

class _AddCoffeeDialogState extends State<_AddCoffeeDialog> {
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  final _descC = TextEditingController();
  String _type = 'Hot Coffee';
  String _imagePath = 'assets/images/Coffee1.jpg';
  File? _pickedFile;
  bool _saving = false;
  bool _uploading = false;

  final _assetImages = [
    'assets/images/Coffee1.jpg',
    'assets/images/Coffee2.jpg',
    'assets/images/Coffee3.jpg',
    'assets/images/Coffee4.jpg',
    'assets/images/Coffee5.jpg',
    'assets/images/Coffee6.jpg',
    'assets/images/Coffee7.jpg',
    'assets/images/Coffee8.jpg',
    'assets/images/Coffee9.jpg',
    'assets/images/Coffee10.jpg',
    'assets/images/Coffee11.jpg',
    'assets/images/Coffee12.jpg',
    'assets/images/Coffee13.jpg',
    'assets/images/Coffee14.jpg',
  ];

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2d1a00),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Image Source',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepOrange),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker()
                    .pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null && mounted) {
                  setState(() {
                    _pickedFile = File(picked.path);
                    _imagePath = picked.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepOrange),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker()
                    .pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null && mounted) {
                  setState(() {
                    _pickedFile = File(picked.path);
                    _imagePath = picked.path;
                  });
                }
              },
            ),
            const Divider(color: Colors.white12),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Or choose a default image:',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _assetImages.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _pickedFile = null;
                      _imagePath = _assetImages[i];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _imagePath == _assetImages[i]
                              ? Colors.deepOrange
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(_assetImages[i],
                          width: 70, height: 70, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (_nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter coffee name'),
          backgroundColor: Colors.deepOrange));
      return;
    }
    if (_priceC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter price'),
          backgroundColor: Colors.deepOrange));
      return;
    }
    setState(() => _saving = true);

    String finalImagePath = _imagePath;

    // If user picked a file from gallery/camera, upload to Cloudinary
    if (_pickedFile != null) {
      setState(() => _uploading = true);
      final url = await CloudinaryService.uploadImage(_pickedFile!);
      setState(() => _uploading = false);
      if (url != null) {
        finalImagePath = url;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image upload failed. Using default image.'),
              backgroundColor: Colors.orange));
        }
        finalImagePath = _assetImages[0];
      }
    }

    final coffee = CoffeeModel(
      id: '',
      name: _nameC.text.trim(),
      image: finalImagePath,
      price: double.tryParse(_priceC.text) ?? 0,
      type: _type,
      description: _descC.text.trim(),
    );
    await CoffeeService().addCoffee(coffee);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('Add New Coffee',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.deepOrange.withValues(alpha: 0.5),
                      width: 1.5),
                ),
                child: _uploading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.deepOrange),
                            SizedBox(height: 8),
                            Text('Uploading to Cloudinary...',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      )
                    : _pickedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_pickedFile!,
                                fit: BoxFit.cover, width: double.infinity))
                        : _imagePath.startsWith('assets')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(_imagePath, fit: BoxFit.cover),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit,
                                              color: Colors.white, size: 28),
                                          SizedBox(height: 4),
                                          Text('Tap to change image',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: Colors.deepOrange, size: 40),
                                  SizedBox(height: 8),
                                  Text('Tap to select image',
                                      style: TextStyle(
                                          color: Colors.white60, fontSize: 14)),
                                  Text('Gallery • Camera • Default',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                ],
                              ),
              ),
            ),
            const SizedBox(height: 14),
            _field(_nameC, 'Coffee Name', Icons.coffee),
            const SizedBox(height: 10),
            _field(_priceC, 'Price (Rs.)', Icons.attach_money,
                keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _field(_descC, 'Description', Icons.description, maxLines: 2),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                dropdownColor: const Color(0xFF2d1a00),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                items: ['Hot Coffee', 'Cold Coffee', 'Desserts', 'Snacks']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
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
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Add',
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

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.deepOrange)),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose();
    _priceC.dispose();
    _descC.dispose();
    super.dispose();
  }
}

// ── Edit Coffee Dialog ────────────────────────────────────────────────────────
class _EditCoffeeDialog extends StatefulWidget {
  final CoffeeModel coffee;
  const _EditCoffeeDialog({required this.coffee});

  @override
  State<_EditCoffeeDialog> createState() => _EditCoffeeDialogState();
}

class _EditCoffeeDialogState extends State<_EditCoffeeDialog> {
  late TextEditingController _nameC, _priceC, _descC;
  late String _type;
  File? _pickedFile;
  late String _imagePath;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.coffee.name);
    _priceC = TextEditingController(text: widget.coffee.price.toString());
    _descC = TextEditingController(text: widget.coffee.description);
    _type = widget.coffee.type;
    _imagePath = widget.coffee.image;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() {
        _pickedFile = File(picked.path);
        _imagePath = picked.path;
      });
    }
  }

  void _save() async {
    setState(() => _saving = true);

    String finalImagePath = _imagePath;

    // Upload new image to Cloudinary if user picked one
    if (_pickedFile != null) {
      setState(() => _uploading = true);
      final url = await CloudinaryService.uploadImage(_pickedFile!);
      setState(() => _uploading = false);
      if (url != null) {
        finalImagePath = url;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image upload failed. Keeping existing image.'),
              backgroundColor: Colors.orange));
        }
        finalImagePath = widget.coffee.image;
      }
    }

    await CoffeeService().updateCoffee(widget.coffee.id, {
      'name': _nameC.text.trim(),
      'price': double.tryParse(_priceC.text) ?? widget.coffee.price,
      'description': _descC.text.trim(),
      'type': _type,
      'image': finalImagePath,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('Edit Coffee',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.deepOrange.withValues(alpha: 0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_uploading)
                        const Center(
                          child: CircularProgressIndicator(
                              color: Colors.deepOrange),
                        )
                      else if (_pickedFile != null)
                        Image.file(_pickedFile!, fit: BoxFit.cover)
                      else if (CloudinaryService.isNetworkUrl(_imagePath))
                        Image.network(
                          _imagePath,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.deepOrange)),
                          errorBuilder: (_, _, _) => Image.asset(
                              'assets/images/Coffee1.jpg',
                              fit: BoxFit.cover),
                        )
                      else if (_imagePath.startsWith('/'))
                        Image.file(File(_imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                                'assets/images/Coffee1.jpg',
                                fit: BoxFit.cover))
                      else
                        Image.asset(_imagePath, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                                color: Colors.deepOrange.withValues(alpha: 0.2))),
                      Container(color: Colors.black38),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library,
                                color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text('Change Image',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildField(_nameC, 'Name'),
            const SizedBox(height: 10),
            _buildField(_priceC, 'Price (Rs.)',
                keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _buildField(_descC, 'Description', maxLines: 2),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                dropdownColor: const Color(0xFF2d1a00),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.deepOrange),
                items: ['Hot Coffee', 'Cold Coffee', 'Desserts', 'Snacks']
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
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
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save',
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

  Widget _buildField(TextEditingController c, String label,
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.deepOrange)),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose();
    _priceC.dispose();
    _descC.dispose();
    super.dispose();
  }
}

// ── Order Management Tab ──────────────────────────────────────────────────────
class _OrderManagementTab extends StatelessWidget {
  const _OrderManagementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService().getAllOrders(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return const Center(
              child: Text('No orders yet',
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, i) =>
              _AdminOrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  const _AdminOrderCard({required this.order});

  static const _statuses = [
    'pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'
  ];

  static const _statusLabels = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'preparing': 'Preparing',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
    'awaiting_payment': 'Awaiting Payment',
  };

  static const _statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': Colors.purple,
    'out_for_delivery': Colors.teal,
    'delivered': Colors.green,
    'awaiting_payment': Colors.amber,
  };

  static const _paymentStatusColors = {
    'pending': Colors.orange,
    'proof_submitted': Colors.amber,
    'paid': Colors.green,
    'rejected': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[order.status] ?? Colors.grey;
    final payColor =
        _paymentStatusColors[order.paymentStatus] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  'Order #${order.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _statusLabels[order.status] ?? order.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Icon(
                order.paymentMethod == 'cod'
                    ? Icons.money
                    : Icons.account_balance_wallet,
                color: payColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${order.paymentMethod.toUpperCase()} · ${order.paymentStatus.replaceAll('_', ' ').toUpperCase()}',
                style: TextStyle(color: payColor, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _infoRow(Icons.person_outline, order.userName),
          _infoRow(Icons.phone_outlined, order.userPhone),
          _infoRow(Icons.location_on_outlined, order.userAddress),
          const Divider(color: Colors.white12, height: 16),

          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('• ${item.coffeeName} x${item.quantity}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                        'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.deepOrange, fontSize: 12)),
                  ],
                ),
              )),

          const Divider(color: Colors.white12, height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.update, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 8),
                const Text('Update Status:',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _statuses.contains(order.status)
                        ? order.status
                        : 'pending',
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2d1a00),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.deepOrange),
                    items: _statuses
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabels[s] ?? s)))
                        .toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null &&
                          newStatus != order.status) {
                        OrderService()
                            .updateOrderStatus(order.id, newStatus);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                              'Status updated: ${_statusLabels[newStatus]}'),
                          backgroundColor: Colors.deepOrange,
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text.isEmpty ? 'Not provided' : text,
              style: TextStyle(
                  color:
                      text.isEmpty ? Colors.white30 : Colors.white60,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
