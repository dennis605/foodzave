import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class InventoryItem {
  final String id;
  final String productId;
  final DateTime expiryDate;
  final DateTime addedDate;
  final bool isConsumed;
  final DateTime? consumedDate;
  final int reminderDays; // Days before expiry to show reminder

  // Reference to the associated product (not stored in Firebase)
  Product? product;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.expiryDate,
    DateTime? addedDate,
    this.isConsumed = false,
    this.consumedDate,
    this.reminderDays = 3,
    this.product,
  }) : addedDate = addedDate ?? DateTime.now();

  bool get isExpired => !isConsumed && DateTime.now().isAfter(expiryDate);
  
  bool get isAboutToExpire => 
    !isConsumed && 
    !isExpired && 
    DateTime.now().isAfter(expiryDate.subtract(Duration(days: reminderDays)));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'addedDate': Timestamp.fromDate(addedDate),
      'isConsumed': isConsumed,
      'consumedDate': consumedDate != null ? Timestamp.fromDate(consumedDate!) : null,
      'reminderDays': reminderDays,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      addedDate: (map['addedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isConsumed: map['isConsumed'] ?? false,
      consumedDate: (map['consumedDate'] as Timestamp?)?.toDate(),
      reminderDays: map['reminderDays'] ?? 3,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? productId,
    DateTime? expiryDate,
    DateTime? addedDate,
    bool? isConsumed,
    DateTime? consumedDate,
    int? reminderDays,
    Product? product,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate ?? this.addedDate,
      isConsumed: isConsumed ?? this.isConsumed,
      consumedDate: consumedDate ?? this.consumedDate,
      reminderDays: reminderDays ?? this.reminderDays,
      product: product ?? this.product,
    );
  }

  InventoryItem markAsConsumed() {
    return copyWith(
      isConsumed: true,
      consumedDate: DateTime.now(),
    );
  }
}