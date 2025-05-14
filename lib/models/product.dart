import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final bool isManuallyAdded;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    this.imageUrl = '',
    this.isManuallyAdded = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'imageUrl': imageUrl,
      'isManuallyAdded': isManuallyAdded,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isManuallyAdded: map['isManuallyAdded'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    String? category,
    String? imageUrl,
    bool? isManuallyAdded,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isManuallyAdded: isManuallyAdded ?? this.isManuallyAdded,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}