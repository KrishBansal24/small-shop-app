import 'package:mongo_dart/mongo_dart.dart';

class UserModel {
  ObjectId? id;
  String phone;
  String? name;
  String? shopName;
  DateTime createdAt;

  UserModel({
    this.id,
    required this.phone,
    this.name,
    this.shopName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'phone': phone,
      'name': name,
      'shop_name': shopName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'],
      phone: map['phone'],
      name: map['name'],
      shopName: map['shop_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
