import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'Services/auth_service.dart';
import 'Services/cart_provider.dart';
import 'Services/notification_service.dart';
import 'Screens/welcome_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/cart_screen.dart';
import 'Screens/order_tracking_screen.dart';
import 'Screens/Admin/admin_panel_screen.dart';
import 'Screens/Auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Notification service init (local notifications channel setup)
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const CoffeeShopApp(),
    ),
  );
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.deepOrange,
          secondary: Colors.orange,
        ),
        scaffoldBackgroundColor: const Color(0xFF1a0a00),
      ),
      home: const _AppRouter(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/cart': (_) => Scaffold(
              backgroundColor: const Color(0xFF1a0a00),
              appBar: AppBar(
                backgroundColor: const Color(0xFF2d1a00),
                title: const Text('Cart',
                    style: TextStyle(color: Colors.white)),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: const CartScreen(),
            ),
        '/my_orders': (_) => const MyOrdersScreen(),
        '/admin': (_) => const AdminPanelScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

// Auto-route based on auth state
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1a0a00),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.coffee, color: Colors.deepOrange, size: 60),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Colors.deepOrange),
                ],
              ),
            ),
          );
        }

        if (snap.data == null) return const WelcomeScreen();

        // User logged in → start Firestore notification listener
        return FutureBuilder(
          future: AuthService().getUserData(snap.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF1a0a00),
                body: Center(
                    child:
                        CircularProgressIndicator(color: Colors.deepOrange)),
              );
            }
            final user = userSnap.data;

            // ✅ Start listening to Firestore notifications (no server key needed!)
            NotificationService().startListening(snap.data!.uid);

            if (user?.role == 'admin') return const AdminPanelScreen();
            return const HomeScreen();
          },
        );
      },
    );
  }
}
