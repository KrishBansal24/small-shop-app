import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static Db? db;

  static DbCollection? productsCollection;
  static DbCollection? userCollection;
  static DbCollection? salesCollection;
  static String? connectionError = "Connection Not Attempted";

  // Encoded Password: shop123 (Simple password to rule out encoding errors)
  static const String mongoUrl =
      "mongodb+srv://shop_nibhendra_db:shop123@cluster0.ngpqwcw.mongodb.net/shop_db?appName=Cluster0";

  static connect() async {
    connectionError = "Connecting...";
    try {
      debugPrint("Connecting to MongoDB...");
      db = await Db.create(mongoUrl);
      await db!.open();
      inspect(db);
      userCollection = db!.collection("users");
      salesCollection = db!.collection("sales");
      productsCollection = db!.collection("products");
      connectionError = null;
      debugPrint("MongoDB Connection Success! Collections ready.");
    } catch (e) {
      connectionError = e.toString();
      debugPrint("MongoDB Connection Error: $e");
    }
  }

  // ... (Previous Auth Methods: login, signup, getUser, loginUser) ...

  // Login Method
  static Future<String> login(String username, String password) async {
    try {
      if (userCollection == null) {
        return "Database not connected: $connectionError";
      }
      var user = await userCollection!.findOne(where.eq('username', username));
      if (user != null && user['password'] == password) {
        return "success";
      }
      return "Invalid username or password";
    } catch (e) {
      debugPrint("Login Error: $e");
      return "Login Error: ${e.toString()}";
    }
  }

  // Signup Method
  static Future<String> signup(
    String name,
    String username,
    String password,
  ) async {
    try {
      if (userCollection == null) {
        return "Database not connected";
      }
      var user = await userCollection!.findOne(where.eq('username', username));
      if (user != null) {
        return "Username already exists";
      }
      await userCollection!.insert({
        '_id': ObjectId(),
        'name': name,
        'username': username,
        'password': password,
        'created_at': DateTime.now().toIso8601String(),
      });
      return "success";
    } catch (e) {
      debugPrint("Signup Error: $e");
      return "Signup Error: ${e.toString()}";
    }
  }

  static Future<Map<String, dynamic>?> getUser(String username) async {
    try {
      if (userCollection == null) return null;
      final user = await userCollection!.findOne(
        where.eq('username', username),
      );
      return user;
    } catch (e) {
      debugPrint("Get User Error: $e");
      return null;
    }
  }

  // Phone Auth Login/Signup
  static Future<void> loginUser(String phone) async {
    try {
      final user = await userCollection!.findOne(where.eq('phone', phone));
      if (user == null) {
        // Create new user
        await userCollection!.insert({
          '_id': ObjectId(),
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Login User Error: $e");
      rethrow;
    }
  }

  // --- Sales Methods ---

  static Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    try {
      if (db == null || !db!.isConnected) {
        await connect();
      }
      return await operation();
    } catch (e) {
      debugPrint("DB Operation Failed: $e. Retrying...");
      // Force reconnect
      try {
        await db?.close();
      } catch (_) {}
      await connect();
      return await operation();
    }
  }

  static Future<void> addSale(
    double amount,
    String description,
    String mode,
    String platform, {
    List<Map<String, dynamic>>? items,
  }) async {
    await _retryOperation(() async {
      await salesCollection!.insert({
        '_id': ObjectId(),
        'amount': amount,
        'description': description,
        'payment_mode': mode,
        'platform': platform,
        'items': items ?? [],
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  static Future<List<Map<String, dynamic>>> getSales() async {
    return await _retryOperation(() async {
      final sales = await salesCollection!
          .find(where.sortBy('created_at', descending: true).limit(20))
          .toList();
      return sales;
    });
  }

  static Future<List<Map<String, dynamic>>> getWeeklySales() async {
    return await _retryOperation(() async {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final sales = await salesCollection!
          .find(where.gte('created_at', sevenDaysAgo.toIso8601String()))
          .toList();
      return sales;
    });
  }

  static Future<String> deleteSale(ObjectId id) async {
    try {
      if (salesCollection == null) return "Database not connected";

      await salesCollection!.remove(where.id(id));
      return "success";
    } catch (e) {
      debugPrint("Delete Sale Error: $e");
      return "Delete Failed: $e";
    }
  }

  // --- Product / Inventory Methods ---

  static Future<void> addProduct(Map<String, dynamic> productMap) async {
    await _retryOperation(() async {
      await productsCollection!.insert(productMap);
    });
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    return await _retryOperation(() async {
      if (productsCollection == null) return [];
      final products = await productsCollection!
          .find(where.sortBy('name'))
          .toList();
      return products;
    });
  }

  static Future<void> updateProduct(Map<String, dynamic> productMap) async {
    try {
      final id = productMap['_id'] as ObjectId;
      await productsCollection!.update(where.id(id), productMap);
    } catch (e) {
      debugPrint("Update Product Error: $e");
      rethrow;
    }
  }

  static Future<void> deleteProduct(ObjectId id) async {
    try {
      await productsCollection!.remove(where.id(id));
    } catch (e) {
      debugPrint("Delete Product Error: $e");
      rethrow;
    }
  }

  static Future<void> updateStock(
    ObjectId productId,
    int quantityChange,
  ) async {
    await _retryOperation(() async {
      await productsCollection!.update(
        where.id(productId),
        modify.inc('stock', quantityChange),
      );
    });
  }

  static Future<String> updateUser(
    ObjectId id,
    String name,
    String shopName,
  ) async {
    try {
      if (userCollection == null) return "Database not connected";

      await userCollection!.update(
        where.id(id),
        modify.set('name', name).set('shop_name', shopName),
      );
      return "success";
    } catch (e) {
      debugPrint("Update User Error: $e");
      return "Update Failed: $e";
    }
  }
}
