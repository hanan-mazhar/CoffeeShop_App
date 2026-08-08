import 'package:coffee_shop/Screens/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../../Models/user_model.dart';
import '../../Services/auth_service.dart';
// import '../Auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _loading = true;
  bool _editing = false;

  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final user = await _authService.getUserData(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _nameC.text = user?.name ?? '';
          _phoneC.text = user?.phone ?? '';
          _addressC.text = user?.address ?? '';
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    final success = await _authService.updateProfile(
      uid: uid,
      name: _nameC.text.trim(),
      phone: _phoneC.text.trim(),
      address: _addressC.text.trim(),
    );
    await _loadUser();
    setState(() {
      _editing = false;
      _loading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Profile updated successfully!' : 'Something went wrong'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.deepOrange.withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 60, color: Colors.deepOrange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_user?.name ?? 'User',
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(_user?.email ?? '',
              style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5)),
            ),
            child: Text(
              _user?.role == 'admin' ? '👑 Admin' : '☕ Coffee Lover',
              style: const TextStyle(color: Colors.deepOrange, fontSize: 13),
            ),
          ),
          const SizedBox(height: 30),

          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Information',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(_editing ? Icons.close : Icons.edit,
                          color: Colors.deepOrange),
                      onPressed: () => setState(() => _editing = !_editing),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),

                _buildProfileField('Name', _nameC, Icons.person_outline, _editing),
                const SizedBox(height: 16),
                _buildProfileField('Phone', _phoneC, Icons.phone_outlined, _editing,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildProfileField(
                    'Address', _addressC, Icons.location_on_outlined, _editing,
                    maxLines: 2),

                if (_editing) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveProfile,
                      child: const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // My Orders button
          _buildMenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'View order history and status',
            onTap: () => Navigator.pushNamed(context, '/my_orders'),
          ),
          const SizedBox(height: 12),

          // Logout button
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _logout,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileField(
      String label, TextEditingController controller, IconData icon, bool editable,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        editable
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                ),
              )
            : Row(
                children: [
                  Icon(icon, color: Colors.deepOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Not provided' : controller.text,
                      style: TextStyle(
                          color: controller.text.isEmpty
                              ? Colors.white30
                              : Colors.white70,
                          fontSize: 15),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.deepOrange,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    super.dispose();
  }
}
