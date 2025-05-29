import 'package:catalogo_reinstreet/models/cart-item.dart';
import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeFromCart(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void increaseQuantity(int index) {
    _items[index].increaseQuantity();
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    _items[index].decreaseQuantity();
    notifyListeners();
  }

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
}
