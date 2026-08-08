import 'package:coffee_shop/Screens/notifcations_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/auth_service.dart';
import '../Services/cart_provider.dart';
import '../Services/coffee_service.dart';
import '../Models/coffee_model.dart';
import 'Products/coffee_grid.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'order_tracking_screen.dart';
import '../Services/notification_service.dart';
// import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    CoffeeService().seedInitialData();
    // Set user in cart to prevent cart mixing between users
    final uid = AuthService().currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<CartProvider>(context, listen: false).setUser(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeTab(),
      const MyOrdersScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a0a00), Color(0xFF2d1a00), Color(0xFF1a0a00)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (_, cart, _) => CurvedNavigationBar(
          backgroundColor: Colors.transparent,
          color: const Color.fromARGB(200, 40, 20, 5),
          buttonBackgroundColor: Colors.deepOrange,
          height: 60,
          animationDuration: const Duration(milliseconds: 300),
          index: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            const Icon(Icons.home, color: Colors.white, size: 28),
            const Icon(Icons.receipt_long, color: Colors.white, size: 28),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                if (cart.itemCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
            const Icon(Icons.person, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

// ---- Home Tab with working search ----
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.sort, color: Colors.white60, size: isSmall ? 24 : 30),
              Row(
                children: [
                  Consumer<CartProvider>(
                    builder: (_, cart, _) => cart.itemCount > 0
                        ? GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/cart'),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shopping_cart,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${cart.itemCount}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                    child: StreamBuilder<int>(
                      stream: NotificationService().unreadCountStream(
                          AuthService().currentUser?.uid ?? ''),
                      builder: (context, snap) {
                        final count = snap.data ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_outlined,
                                color: Colors.white60,
                                size: isSmall ? 24 : 30),
                            if (count > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Welcome text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: StreamBuilder(
            stream: AuthService().authStateChanges,
            builder: (context, snap) {
              return FutureBuilder(
                future: snap.data != null
                    ? AuthService().getUserData(snap.data!.uid)
                    : null,
                builder: (context, userSnap) {
                  final name = userSnap.data?.name ?? 'Coffee Lover';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $name! 👋',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.bold)),
                      Text('What would you like today?',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: isSmall ? 13 : 15)),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ---- WORKING SEARCH BAR ----
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white70),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search your favorite coffee...',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                suffixIcon: null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // If searching — show filtered results directly
        if (_searchQuery.isNotEmpty)
          Expanded(child: _SearchResults(query: _searchQuery))
        else
          // Tab bar with categories
          Expanded(
            child: DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(
                        fontSize: isSmall ? 13 : 15,
                        fontWeight: FontWeight.w600),
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3.0, color: Colors.orange),
                      insets: EdgeInsets.symmetric(horizontal: 10.0),
                    ),
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Hot Coffee'),
                      Tab(text: 'Cold Coffee'),
                      Tab(text: 'Desserts'),
                      Tab(text: 'Snacks'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        CoffeeGrid(),
                        CoffeeGrid(filterType: 'Hot Coffee'),
                        CoffeeGrid(filterType: 'Cold Coffee'),
                        CoffeeGrid(filterType: 'Desserts'),
                        CoffeeGrid(filterType: 'Snacks'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---- Search Results Widget ----
class _SearchResults extends StatelessWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoffeeModel>>(
      stream: CoffeeService().getCoffees(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange));
        }
        final all = snap.data ?? [];
        final filtered = all
            .where((c) =>
                c.name.toLowerCase().contains(query) ||
                c.type.toLowerCase().contains(query) ||
                c.description.toLowerCase().contains(query))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, color: Colors.white24, size: 60),
                const SizedBox(height: 12),
                Text('No results for "$query"',
                    style: const TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        return CoffeeGrid(searchResults: filtered);
      },
    );
  }
}