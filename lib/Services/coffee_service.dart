import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/coffee_model.dart';

class CoffeeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all coffees (stream)
  Stream<List<CoffeeModel>> getCoffees() {
    return _db.collection('coffees').snapshots().map((snap) =>
        snap.docs.map((doc) => CoffeeModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Get coffees by type
  Stream<List<CoffeeModel>> getCoffeesByType(String type) {
    return _db
        .collection('coffees')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CoffeeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Admin: Add coffee
  Future<bool> addCoffee(CoffeeModel coffee) async {
    try {
      await _db.collection('coffees').add(coffee.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Admin: Update coffee
  Future<bool> updateCoffee(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('coffees').doc(id).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Admin: Delete coffee
  Future<bool> deleteCoffee(String id) async {
    try {
      await _db.collection('coffees').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Seed initial data (run once)
  // NOTE: After Cloudinary integration, seed data uses asset paths as fallback.
  // Upload real images via admin panel to replace with Cloudinary URLs.
  Future<void> seedInitialData() async {
    final existing = await _db.collection('coffees').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final coffees = [
      {
        'name': 'Espresso',
        'image': 'assets/images/Coffee1.jpg',
        'price': 3.50,
        'type': 'Hot Coffee',
        'description': 'Strong and bold espresso shot.',
        'isAvailable': true
      },
      {
        'name': 'Cappuccino',
        'image': 'assets/images/Coffee2.jpg',
        'price': 4.20,
        'type': 'Hot Coffee',
        'description': 'Espresso with steamed milk and foam.',
        'isAvailable': true
      },
      {
        'name': 'Iced Latte',
        'image': 'assets/images/Coffee3.jpg',
        'price': 4.50,
        'type': 'Cold Coffee',
        'description': 'Cold milk with espresso and ice.',
        'isAvailable': true
      },
      {
        'name': 'Cold Brew',
        'image': 'assets/images/Coffee4.jpg',
        'price': 3.80,
        'type': 'Cold Coffee',
        'description': 'Smooth coffee brewed with cold water.',
        'isAvailable': true
      },
      {
        'name': 'Mocha',
        'image': 'assets/images/Coffee5.jpg',
        'price': 2.90,
        'type': 'Hot Coffee',
        'description': 'Rich espresso with chocolate flavor.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee6.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee7.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee8.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee9.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee10.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee11.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee12.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee13.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
      {
        'name': 'Choco Coffee',
        'image': 'assets/images/Coffee14.jpg',
        'price': 5.20,
        'type': 'Desserts',
        'description': 'Soft chocolate dessert coffee.',
        'isAvailable': true
      },
    ];

    for (var c in coffees) {
      await _db.collection('coffees').add(c);
    }
  }
}
