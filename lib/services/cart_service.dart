import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
    String foodItemId,
    String name,
    double price,
    String imageUrl,
    int maxStock, {
    int quantity = 1,
  }) {
    if (_items.containsKey(foodItemId)) {
      final currentQuantity = _items[foodItemId]!.quantity;
      if (currentQuantity + quantity <= maxStock) {
        _items.update(
          foodItemId,
          (existingCartItem) => CartItem(
            foodItemId: existingCartItem.foodItemId,
            name: existingCartItem.name,
            price: existingCartItem.price,
            quantity: existingCartItem.quantity + quantity,
            imageUrl: existingCartItem.imageUrl,
            maxStock: existingCartItem.maxStock,
          ),
        );
      } else {
        throw Exception("Cannot add more. Exceeds available stock.");
      }
    } else {
      if (quantity <= maxStock) {
        _items.putIfAbsent(
          foodItemId,
          () => CartItem(
            foodItemId: foodItemId,
            name: name,
            price: price,
            quantity: quantity,
            imageUrl: imageUrl,
            maxStock: maxStock,
          ),
        );
      } else {
        throw Exception("Not enough stock available.");
      }
    }
    notifyListeners();
  }

  void removeItem(String foodItemId) {
    _items.remove(foodItemId);
    notifyListeners();
  }

  void updateQuantity(String foodItemId, int quantity) {
    if (!_items.containsKey(foodItemId)) return;
    
    final item = _items[foodItemId]!;
    if (quantity > 0 && quantity <= item.maxStock) {
      _items.update(
        foodItemId,
        (existingCartItem) => CartItem(
          foodItemId: existingCartItem.foodItemId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: quantity,
          imageUrl: existingCartItem.imageUrl,
          maxStock: existingCartItem.maxStock,
        ),
      );
    } else if (quantity <= 0) {
      _items.remove(foodItemId);
    } else {
      throw Exception("Cannot exceed available stock.");
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
