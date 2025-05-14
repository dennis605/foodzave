import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class ShoppingListItem {
  final String id;
  final String productId;
  final int quantity;
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime? purchasedAt;
  final String? note;

  // Reference to the associated product (not stored in Firebase)
  Product? product;

  ShoppingListItem({
    required this.id,
    required this.productId,
    this.quantity = 1,
    this.isPurchased = false,
    DateTime? createdAt,
    this.purchasedAt,
    this.note,
    this.product,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'isPurchased': isPurchased,
      'createdAt': Timestamp.fromDate(createdAt),
      'purchasedAt': purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : null,
      'note': note,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      quantity: map['quantity'] ?? 1,
      isPurchased: map['isPurchased'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      purchasedAt: (map['purchasedAt'] as Timestamp?)?.toDate(),
      note: map['note'],
    );
  }

  ShoppingListItem copyWith({
    String? id,
    String? productId,
    int? quantity,
    bool? isPurchased,
    DateTime? createdAt,
    DateTime? purchasedAt,
    String? note,
    Product? product,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      note: note ?? this.note,
      product: product ?? this.product,
    );
  }

  ShoppingListItem markAsPurchased() {
    return copyWith(
      isPurchased: true,
      purchasedAt: DateTime.now(),
    );
  }

  ShoppingListItem incrementQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  ShoppingListItem decrementQuantity() {
    if (quantity > 1) {
      return copyWith(quantity: quantity - 1);
    }
    return this;
  }
}