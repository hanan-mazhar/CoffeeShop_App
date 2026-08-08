import 'package:flutter/material.dart';
import '../../Services/auth_service.dart';
import '../home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscure = true;

  void _signup() async {
    if (_nameC.text.isEmpty || _emailC.text.isEmpty || _passC.text.isEmpty) {
      _showSnack('Please fill all required fields');
      return;
    }

    setState(() => _loading = true);
    final error = await _authService.signUp(
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      password: _passC.text.trim(),
      phone: _phoneC.text.trim(),
      address: _addressC.text.trim(),
    );
    setState(() => _loading = false);

    if (error != null) {
      _showSnack(error);
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.deepOrange));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.brown.shade900],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),

                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.deepOrange, width: 2),
                        ),
                        child: const Icon(Icons.person_add, color: Colors.deepOrange, size: 45),
                      ),
                      const SizedBox(height: 14),
                      const Text('Create Account',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const Text('Create your account',
                          style: TextStyle(color: Colors.white60, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                _buildField('Your name', _nameC, Icons.person_outline),
                const SizedBox(height: 16),
                _buildField('Email', _emailC, Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField('Phone Number', _phoneC, Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildField('Delivery Address', _addressC, Icons.location_on_outlined,
                    maxLines: 2),
                const SizedBox(height: 16),

                // Password field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _passC,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password (minimum 6 characters)',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepOrange),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ",
                          style: TextStyle(color: Colors.white60)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Login',
                            style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: Icon(icon, color: Colors.deepOrange),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    super.dispose();
  }
}
