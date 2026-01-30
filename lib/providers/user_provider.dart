import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _name = "Admin";
  String _shopName = "My Shop";

  String _id = "";
  String _username = "";
  String _phone = "+91 9878787900"; // Placeholder as per screenshot

  String get id => _id;
  String get username => _username;
  String get phone => _phone;
  String get name => _name;
  String get shopName => _shopName;

  void setUser(
    String id,
    String username,
    String name,
    String? shopName,
    String? phone,
  ) {
    _id = id;
    _username = username;
    _name = name.isNotEmpty ? name : "Admin";
    if (shopName != null && shopName.isNotEmpty) {
      _shopName = shopName;
    }
    if (phone != null && phone.isNotEmpty) {
      _phone = phone;
    }
    notifyListeners();
  }

  void updateProfile(String name, String shopName) {
    _name = name;
    _shopName = shopName;
    notifyListeners();
  }
}
