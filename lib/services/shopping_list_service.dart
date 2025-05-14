import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodzave/models/shopping_list_item.dart';
import 'package:foodzave/models/inventory_item.dart';
import 'package:foodzave/services/product_service.dart';

class ShoppingListService {
  // Singleton pattern
  static final ShoppingListService _instance = ShoppingListService._internal();
  factory ShoppingListService() => _instance;
  ShoppingListService._internal();
  
  final ProductService _productService = ProductService();
  final CollectionReference _shoppingListCollection = 
      FirebaseFirestore.instance.collection('shopping_list');
  
  /// Add item to shopping list
  Future<ShoppingListItem> addShoppingListItem({
    required String productId,
    int quantity = 1,
    String? note,
  }) async {
    // Check if the product already exists in the shopping list
    final existingItem = await _getExistingShoppingListItem(productId);
    
    if (existingItem != null) {
      // Update the existing item with an increased quantity
      final updatedItem = existingItem.incrementQuantity();
      await _shoppingListCollection.doc(existingItem.id).update({
        'quantity': updatedItem.quantity,
      });
      return updatedItem;
    } else {
      // Create a new shopping list item
      final String itemId = _shoppingListCollection.doc().id;
      
      final ShoppingListItem item = ShoppingListItem(
        id: itemId,
        productId: productId,
        quantity: quantity,
        note: note,
      );
      
      await _shoppingListCollection.doc(itemId).set(item.toMap());
      
      // Load the associated product if available
      final product = await _productService.getProductById(productId);
      return item.copyWith(product: product);
    }
  }
  
  /// Get an existing shopping list item for a product
  Future<ShoppingListItem?> _getExistingShoppingListItem(String productId) async {
    try {
      final querySnapshot = await _shoppingListCollection
        .where('productId', isEqualTo: productId)
        .where('isPurchased', isEqualTo: false)
        .limit(1)
        .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final item = ShoppingListItem.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>
        );
        
        final product = await _productService.getProductById(productId);
        return item.copyWith(product: product);
      }
      
      return null;
    } catch (e) {
      print('Error getting existing shopping list item: $e');
      return null;
    }
  }
  
  /// Get active (not purchased) shopping list items
  Future<List<ShoppingListItem>> getActiveShoppingList() async {
    try {
      final querySnapshot = await _shoppingListCollection
        .where('isPurchased', isEqualTo: false)
        .get();
      
      final List<ShoppingListItem> items = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final item = ShoppingListItem.fromMap(doc.data() as Map<String, dynamic>);
          final product = await _productService.getProductById(item.productId);
          return item.copyWith(product: product);
        })
      );
      
      return items;
    } catch (e) {
      print('Error getting active shopping list: $e');
      return [];
    }
  }
  
  /// Mark item as purchased
  Future<void> markItemAsPurchased(String itemId) async {
    try {
      await _shoppingListCollection.doc(itemId).update({
        'isPurchased': true,
        'purchasedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error marking item as purchased: $e');
      throw e;
    }
  }
  
  /// Remove item from shopping list
  Future<void> removeShoppingListItem(String itemId) async {
    try {
      await _shoppingListCollection.doc(itemId).delete();
    } catch (e) {
      print('Error removing shopping list item: $e');
      throw e;
    }
  }
  
  /// Update shopping list item quantity
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeShoppingListItem(itemId);
      return;
    }
    
    try {
      await _shoppingListCollection.doc(itemId).update({
        'quantity': quantity,
      });
    } catch (e) {
      print('Error updating item quantity: $e');
      throw e;
    }
  }
  
  /// Generate shopping list from consumed items
  Future<List<ShoppingListItem>> generateFromConsumedItems(List<InventoryItem> consumedItems) async {
    final List<ShoppingListItem> generatedItems = [];
    
    // Group consumed items by product ID
    final Map<String, int> productCounts = {};
    for (final item in consumedItems) {
      productCounts[item.productId] = (productCounts[item.productId] ?? 0) + 1;
    }
    
    // Create shopping list items for each product
    for (final entry in productCounts.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      
      // Add to shopping list
      final item = await addShoppingListItem(
        productId: productId,
        quantity: quantity,
      );
      
      generatedItems.add(item);
    }
    
    return generatedItems;
  }
}