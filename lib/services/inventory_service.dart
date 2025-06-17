import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodzave/models/inventory_item.dart';
import 'package:foodzave/models/product.dart';
import 'package:foodzave/services/product_service.dart';

class InventoryService {
  // Singleton pattern
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal() {
    _initializeFirebase();
  }
  
  final ProductService _productService = ProductService();
  CollectionReference? _inventoryCollection;
  bool _isFirebaseAvailable = false;
  
  // Mock data für Demo-Zwecke
  final List<InventoryItem> _mockInventoryItems = [];
  
  
  void _initializeFirebase() {
    try {
      _inventoryCollection = FirebaseFirestore.instance.collection('inventory');
      _isFirebaseAvailable = true;
    } catch (e) {
      _isFirebaseAvailable = false;
      _initializeMockData();
      print('Firebase nicht verfügbar, verwende Mock-Daten für Inventory');
    }
  }
  
  void _initializeMockData() {
    // Erstelle einige Demo-Produkte und Inventory-Items
    final demoProducts = [
      Product(
        id: 'demo-1',
        barcode: '1234567890123',
        name: 'Vollmilch',
        brand: 'Demomilch',
        category: 'Milchprodukte',
      ),
      Product(
        id: 'demo-2',
        barcode: '2345678901234',
        name: 'Äpfel',
        brand: 'Obstgarten',
        category: 'Obst',
      ),
      Product(
        id: 'demo-3',
        barcode: '3456789012345',
        name: 'Brot',
        brand: 'Bäckerei',
        category: 'Backwaren',
      ),
    ];
    
    // Erstelle Demo-Inventory-Items
    _mockInventoryItems.addAll([
      InventoryItem(
        id: 'inv-1',
        productId: 'demo-1',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        reminderDays: 2,
        product: demoProducts[0],
      ),
      InventoryItem(
        id: 'inv-2',
        productId: 'demo-2',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        reminderDays: 3,
        product: demoProducts[1],
      ),
      InventoryItem(
        id: 'inv-3',
        productId: 'demo-3',
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        reminderDays: 3,
        product: demoProducts[2],
      ),
    ]);
  }
  
  /// Add new item to inventory
  Future<InventoryItem> addInventoryItem({
    required String productId,
    required DateTime expiryDate,
    int reminderDays = 3,
  }) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      final String itemId = 'mock-${DateTime.now().millisecondsSinceEpoch}';
      final product = await _productService.getProductById(productId);
      
      final InventoryItem item = InventoryItem(
        id: itemId,
        productId: productId,
        expiryDate: expiryDate,
        reminderDays: reminderDays,
        product: product,
      );
      
      _mockInventoryItems.add(item);
      return item;
    }
    
    final String itemId = _inventoryCollection!.doc().id;
    
    final InventoryItem item = InventoryItem(
      id: itemId,
      productId: productId,
      expiryDate: expiryDate,
      reminderDays: reminderDays,
    );
    
    await _inventoryCollection!.doc(itemId).set(item.toMap());
    
    // Load the associated product if available
    final product = await _productService.getProductById(productId);
    return item.copyWith(product: product);
  }
  
  /// Get all inventory items
  Future<List<InventoryItem>> getAllInventoryItems() async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      return List.from(_mockInventoryItems);
    }
    
    try {
      final querySnapshot = await _inventoryCollection!.get();
      
      final List<InventoryItem> items = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final item = InventoryItem.fromMap(doc.data() as Map<String, dynamic>);
          final product = await _productService.getProductById(item.productId);
          return item.copyWith(product: product);
        })
      );
      
      return items;
    } catch (e) {
      print('Error getting inventory items: $e');
      return [];
    }
  }
  
  /// Get inventory items that are not consumed
  Future<List<InventoryItem>> getActiveInventoryItems() async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      return _mockInventoryItems.where((item) => !item.isConsumed).toList();
    }
    
    try {
      final querySnapshot = await _inventoryCollection!
        .where('isConsumed', isEqualTo: false)
        .get();
      
      final List<InventoryItem> items = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final item = InventoryItem.fromMap(doc.data() as Map<String, dynamic>);
          final product = await _productService.getProductById(item.productId);
          return item.copyWith(product: product);
        })
      );
      
      return items;
    } catch (e) {
      print('Error getting active inventory items: $e');
      return [];
    }
  }
  
  /// Get inventory items that are about to expire
  Future<List<InventoryItem>> getExpiringItems() async {
    try {
      final items = await getActiveInventoryItems();
      return items.where((item) => item.isAboutToExpire).toList();
    } catch (e) {
      print('Error getting expiring items: $e');
      return [];
    }
  }
  
  /// Get inventory items by product ID
  Future<List<InventoryItem>> getInventoryItemsByProductId(String productId) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      return _mockInventoryItems
          .where((item) => item.productId == productId && !item.isConsumed)
          .toList();
    }
    
    try {
      final querySnapshot = await _inventoryCollection!
        .where('productId', isEqualTo: productId)
        .where('isConsumed', isEqualTo: false)
        .get();
      
      final List<InventoryItem> items = querySnapshot.docs
        .map((doc) => InventoryItem.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
      
      // Load the product once for all items
      final product = await _productService.getProductById(productId);
      
      // Attach the product to all items
      return items.map((item) => item.copyWith(product: product)).toList();
    } catch (e) {
      print('Error getting items by product ID: $e');
      return [];
    }
  }
  
  /// Mark item as consumed
  Future<void> markItemAsConsumed(String itemId) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      final index = _mockInventoryItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _mockInventoryItems[index] = _mockInventoryItems[index].markAsConsumed();
      }
      return;
    }
    
    try {
      await _inventoryCollection!.doc(itemId).update({
        'isConsumed': true,
        'consumedDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error marking item as consumed: $e');
      rethrow;
    }
  }
  
  /// Delete item from inventory
  Future<void> deleteInventoryItem(String itemId) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      _mockInventoryItems.removeWhere((item) => item.id == itemId);
      return;
    }
    
    try {
      await _inventoryCollection!.doc(itemId).delete();
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }
  
  /// Update expiry date or reminder days
  Future<void> updateInventoryItem({
    required String itemId,
    DateTime? expiryDate,
    int? reminderDays,
  }) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      final index = _mockInventoryItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _mockInventoryItems[index] = _mockInventoryItems[index].copyWith(
          expiryDate: expiryDate,
          reminderDays: reminderDays,
        );
      }
      return;
    }
    
    final Map<String, dynamic> updates = {};
    
    if (expiryDate != null) {
      updates['expiryDate'] = Timestamp.fromDate(expiryDate);
    }
    
    if (reminderDays != null) {
      updates['reminderDays'] = reminderDays;
    }
    
    if (updates.isNotEmpty) {
      try {
        await _inventoryCollection!.doc(itemId).update(updates);
      } catch (e) {
        print('Error updating inventory item: $e');
        rethrow;
      }
    }
  }
  
  /// Get suggested reminder days based on product category
  int getSuggestedReminderDays(String category) {
    // Default values based on food category
    switch (category.toLowerCase()) {
      case 'milchprodukte':
      case 'milch':
      case 'joghurt':
      case 'käse':
        return 2; // Dairy products spoil faster
      
      case 'fleisch':
      case 'wurst':
      case 'fisch':
        return 1; // Meat products are very perishable
      
      case 'obst':
      case 'gemüse':
      case 'früchte':
        return 2; // Fruits and vegetables
      
      case 'konserven':
      case 'tiefkühlkost':
        return 7; // Canned and frozen foods last longer
      
      default:
        return 3; // Default reminder time
    }
  }
}