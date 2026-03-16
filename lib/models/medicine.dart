import 'package:flutter/material.dart';

class Medicine {
  final int id;
  final String name;
  final String genericName;
  final int categoryId;
  final String categoryName;
  final int supplierId;
  final String supplierName;
  final double price;
  final int quantity;
  final int minStockLevel;
  final DateTime expiryDate;
  final String batchNumber;
  final String description;
  final bool isLowStock;
  final bool isExpired;
  final bool isNearingExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.categoryId,
    required this.categoryName,
    required this.supplierId,
    required this.supplierName,
    required this.price,
    required this.quantity,
    required this.minStockLevel,
    required this.expiryDate,
    required this.batchNumber,
    required this.description,
    required this.isLowStock,
    required this.isExpired,
    required this.isNearingExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    // Handle price that might be string or number
    double parsedPrice = 0.0;
    if (json['price'] is String) {
      parsedPrice = double.parse(json['price'] as String);
    } else if (json['price'] is int) {
      parsedPrice = (json['price'] as int).toDouble();
    } else if (json['price'] is double) {
      parsedPrice = json['price'] as double;
    }

    return Medicine(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      name: json['name'] ?? '',
      genericName: json['generic_name'] ?? '',
      categoryId: json['category'] is String ? int.parse(json['category']) : json['category'] ?? 0,
      categoryName: json['category_name'] ?? '',
      supplierId: json['supplier'] is String ? int.parse(json['supplier']) : json['supplier'] ?? 0,
      supplierName: json['supplier_name'] ?? '',
      price: parsedPrice,
      quantity: json['quantity'] is String ? int.parse(json['quantity']) : json['quantity'] ?? 0,
      minStockLevel: json['min_stock_level'] is String ? int.parse(json['min_stock_level']) : json['min_stock_level'] ?? 10,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : DateTime.now(),
      batchNumber: json['batch_number'] ?? '',
      description: json['description'] ?? '',
      isLowStock: json['is_low_stock'] ?? false,
      isExpired: json['is_expired'] ?? false,
      isNearingExpiry: json['is_nearing_expiry'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'generic_name': genericName,
      'category': categoryId,
      'supplier': supplierId,
      'price': price.toString(),
      'quantity': quantity,
      'min_stock_level': minStockLevel,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'batch_number': batchNumber,
      'description': description,
    };
  }

  String get stockStatus {
    if (quantity <= 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Color get stockStatusColor {
    if (quantity <= 0) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  String get expiryStatus {
    if (isExpired) return 'Expired';
    if (isNearingExpiry) return 'Expiring Soon';
    return 'Valid';
  }

  Color get expiryStatusColor {
    if (isExpired) return Colors.red;
    if (isNearingExpiry) return Colors.orange;
    return Colors.green;
  }

  int get daysUntilExpiry {
    final today = DateTime.now();
    return expiryDate.difference(today).inDays;
  }
}