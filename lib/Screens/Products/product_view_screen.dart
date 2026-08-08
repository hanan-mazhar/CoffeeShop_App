import 'package:coffee_shop/Models/coffee_model.dart';
import 'package:coffee_shop/Models/order_model.dart';
import 'package:coffee_shop/Services/cart_provider.dart';
import 'package:coffee_shop/Services/cloudinary_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductViewScreen extends StatefulWidget {
  final CoffeeModel coffee;
  const ProductViewScreen({super.key, required this.coffee});

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  int _qty = 1;

  void _addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    for (int i = 0; i < _qty; i++) {
      cart.addItem(OrderItem(
        coffeeId: widget.coffee.id,
        coffeeName: widget.coffee.name,
        coffeeImage: widget.coffee.image,
        price: widget.coffee.price,
      ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.coffee.name} added to cart!'),
        backgroundColor: Colors.deepOrange,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  /// Returns the correct ImageProvider based on whether the image is a
  /// Cloudinary URL or a local asset path.
  ImageProvider _imageProvider(String path) {
    if (CloudinaryService.isNetworkUrl(path)) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height / 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: _imageProvider(widget.coffee.image),
                    fit: BoxFit.cover,
                    onError: (_, _) {}, // silently fall through to child
                  ),
                ),
                // Fallback shown while network image loads or on error
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CloudinaryService.isNetworkUrl(widget.coffee.image)
                      ? Image.network(
                          widget.coffee.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      color: Colors.deepOrange.withValues(alpha: 0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.deepOrange),
                                      ),
                                    ),
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.deepOrange.withValues(alpha: 0.2),
                            child: const Center(
                              child: Icon(Icons.coffee,
                                  color: Colors.deepOrange, size: 64),
                            ),
                          ),
                        )
                      : Image.asset(
                          widget.coffee.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.deepOrange.withValues(alpha: 0.2),
                            child: const Center(
                              child: Icon(Icons.coffee,
                                  color: Colors.deepOrange, size: 64),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: Container(
                  alignment: Alignment.center,
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.black54,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              // Floating cart badge
              Positioned(
                top: 40,
                right: 20,
                child: Consumer<CartProvider>(
                  builder: (_, cart, _) => cart.itemCount > 0
                      ? GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/cart'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_cart,
                                    color: Colors.white, size: 18),
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
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.coffee.type,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 4)),
                  const SizedBox(height: 6),
                  Text(widget.coffee.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Qty and price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        height: 47,
                        width: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                  () { if (_qty > 1) _qty--; }),
                              child: const Icon(CupertinoIcons.minus,
                                  color: Colors.white),
                            ),
                            Text('$_qty',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            GestureDetector(
                              onTap: () => setState(() => _qty++),
                              child: const Icon(Icons.add,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Text(
                          'Rs ${(widget.coffee.price * _qty).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.coffee.description,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 1,
                          height: 1.5)),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _addToCart,
                      child: const Text('Add to Cart',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
