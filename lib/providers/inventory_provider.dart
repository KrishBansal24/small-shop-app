import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/services/mongodb_service.dart';

class InventoryProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.stock <= p.lowStockThreshold).toList();

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final productMaps = await MongoDatabase.getProducts();
      _products = productMaps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(
    String name,
    double price,
    int stock,
    String category,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProduct = Product(
        id: ObjectId(),
        name: name,
        price: price,
        stock: stock,
        category: category,
      );

      await MongoDatabase.addProduct(newProduct.toMap());
      await fetchProducts(); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      await MongoDatabase.updateProduct(product.toMap());
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(ObjectId id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await MongoDatabase.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
