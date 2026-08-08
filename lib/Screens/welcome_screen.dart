import 'package:flutter/material.dart';
// Note: Ensure your file paths are correct
import 'Auth/login_screen.dart'; 
import 'Auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Material ki jagah Scaffold behtar hai
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Welcomecoffee.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo/Title
                const Text(
                  'CoffeeShop',
                  style: TextStyle(
                    fontSize: 52,
                    fontFamily: 'welcome', // Make sure this font is in pubspec.yaml
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(offset: Offset(0, 4), color: Colors.black54, blurRadius: 10)
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "☕ Pakistan's finest coffee", // Fixed syntax here
                  style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.2),
                ),
                
                const Spacer(flex: 3),

                // Tagline
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Order from home\nAnd wait for delivery!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      _buildButton(
                        context,
                        label: 'Login',
                        color: Colors.deepOrange,
                        isOutlined: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        label: 'Create New Account',
                        color: Colors.transparent,
                        isOutlined: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Button Widget for cleaner code
  Widget _buildButton(BuildContext context, {required String label, required Color color, required bool isOutlined, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined 
        ? OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.deepOrange, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
    );
  }
}