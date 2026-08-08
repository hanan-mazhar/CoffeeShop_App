import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/coffee_model.dart';
import '../../Models/order_model.dart';
import '../../Services/cart_provider.dart';
import '../../Services/cloudinary_service.dart';
import '../../Services/coffee_service.dart';
import 'product_view_screen.dart';

class CoffeeGrid extends StatelessWidget {
  final String? filterType;
  final List<CoffeeModel>? searchResults;

  const CoffeeGrid({super.key, this.filterType, this.searchResults});

  @override
  Widget build(BuildContext context) {
    if (searchResults != null) {
      return _buildGrid(context, searchResults!);
    }

    final stream = filterType != null && filterType != 'All'
        ? CoffeeService().getCoffeesByType(filterType!)
        : CoffeeService().getCoffees();

    return StreamBuilder<List<CoffeeModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange));
        }
        final coffees = snap.data ?? [];
        if (coffees.isEmpty) {
          return const Center(
              child: Text('No coffee items found',
                  style: TextStyle(color: Colors.white54)));
        }
        return _buildGrid(context, coffees);
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<CoffeeModel> coffees) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth > 600 ? 3 : 2;
    final childAspect = screenWidth > 600 ? 0.75 : 0.72;

    return GridView.builder(
      padding: EdgeInsets.all(screenWidth * 0.03),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: screenWidth * 0.025,
        mainAxisSpacing: screenWidth * 0.025,
        childAspectRatio: childAspect,
      ),
      itemCount: coffees.length,
      itemBuilder: (context, i) => _CoffeeCard(coffee: coffees[i]),
    );
  }
}

class _CoffeeCard extends StatelessWidget {
  final CoffeeModel coffee;
  const _CoffeeCard({required this.coffee});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imgHeight = screenWidth > 600 ? 150.0 : 120.0;
    final titleSize = screenWidth > 600 ? 17.0 : 14.0;
    final priceSize = screenWidth > 600 ? 18.0 : 15.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductViewScreen(coffee: coffee))),
      child: Card(
        elevation: 8,
        color: const Color.fromARGB(31, 237, 226, 226),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildCoffeeImage(coffee.image, imgHeight),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coffee.name,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(coffee.type,
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: titleSize - 3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rs ${coffee.price.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: priceSize,
                                fontWeight: FontWeight.w600)),
                        GestureDetector(
                          onTap: () {
                            Provider.of<CartProvider>(context, listen: false)
                                .addItem(OrderItem(
                              coffeeId: coffee.id,
                              coffeeName: coffee.name,
                              coffeeImage: coffee.image,
                              price: coffee.price,
                            ));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content:
                                  Text('${coffee.name} added to cart!'),
                              backgroundColor: Colors.deepOrange,
                              duration: const Duration(seconds: 1),
                            ));
                          },
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                                color: Colors.deepOrangeAccent,
                                borderRadius: BorderRadius.circular(30)),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Smart image: Cloudinary/network URL → Image.network, else Image.asset
  Widget _buildCoffeeImage(String path, double height) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: Colors.deepOrange.withValues(alpha: 0.2),
      child: const Center(
          child: Icon(Icons.coffee, color: Colors.deepOrange, size: 40)),
    );

    if (CloudinaryService.isNetworkUrl(path)) {
      return Image.network(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
