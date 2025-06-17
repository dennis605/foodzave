import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodzave/models/product.dart';

class ProductService {
  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal() {
    _initializeFirebase();
  }
  
  // Firestore reference
  CollectionReference? _productsCollection;
  bool _isFirebaseAvailable = false;
  
  // Mock products für Demo
  final List<Product> _mockProducts = [];
  
  void _initializeFirebase() {
    try {
      _productsCollection = FirebaseFirestore.instance.collection('products');
      _isFirebaseAvailable = true;
    } catch (e) {
      _isFirebaseAvailable = false;
      _initializeMockProducts();
      print('Firebase nicht verfügbar, verwende Mock-Daten für Products');
    }
  }
  
  void _initializeMockProducts() {
    _mockProducts.addAll([
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
    ]);
  }
  
  // OpenGTIN DB API URL
  final String _openGtinDbUrl = 'https://opengtindb.org/api/';
  final String _openGtinDbUserAgent = 'FoodZave/1.0';
  
  /// Retrieves product information from OpenGTINdb
  Future<Product?> fetchProductFromOpenGtinDB(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_openGtinDbUrl?cmd=query&queryid=400&ean=$barcode&output=json'),
        headers: {'User-Agent': _openGtinDbUserAgent},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == '0' && data['found'] == '1') {
          final productData = data['products'][0];
          return Product(
            id: productData['ean'],
            barcode: productData['ean'],
            name: productData['name'] ?? 'Unbekanntes Produkt',
            brand: productData['vendor'] ?? '',
            category: productData['maincat'] ?? '',
            imageUrl: '',
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching product data: $e');
      return null;
    }
  }

  /// Saves product to Firestore
  Future<void> saveProduct(Product product) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      final existingIndex = _mockProducts.indexWhere((p) => p.id == product.id);
      if (existingIndex != -1) {
        _mockProducts[existingIndex] = product;
      } else {
        _mockProducts.add(product);
      }
      return;
    }
    
    try {
      await _productsCollection!.doc(product.id).set(product.toMap());
    } catch (e) {
      print('Error saving product: $e');
      rethrow;
    }
  }
  
  /// Retrieves product from Firestore by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      try {
        return _mockProducts.firstWhere((product) => product.barcode == barcode);
      } catch (e) {
        return null;
      }
    }
    
    try {
      final querySnapshot = await _productsCollection!
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return Product.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>
        );
      }
      return null;
    } catch (e) {
      print('Error getting product by barcode: $e');
      return null;
    }
  }
  
  /// Retrieves product from Firestore by ID
  Future<Product?> getProductById(String productId) async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      try {
        return _mockProducts.firstWhere((product) => product.id == productId);
      } catch (e) {
        return null;
      }
    }
    
    try {
      final docSnapshot = await _productsCollection!.doc(productId).get();
      if (docSnapshot.exists) {
        return Product.fromMap(docSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }
  
  /// Creates a product entry from manual input
  Future<Product> createManualProduct({
    required String name,
    required String brand,
    required String category,
    required String barcode,
  }) async {
    final String id = FirebaseFirestore.instance.collection('products').doc().id;
    
    final Product product = Product(
      id: id,
      barcode: barcode,
      name: name,
      brand: brand,
      category: category,
      isManuallyAdded: true,
    );
    
    await saveProduct(product);
    return product;
  }
  
  /// Get all product categories (for dropdown menus)
  Future<List<String>> getProductCategories() async {
    if (!_isFirebaseAvailable) {
      // Mock implementation
      final categories = _mockProducts
        .map((product) => product.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
      
      categories.sort();
      return categories;
    }
    
    try {
      final querySnapshot = await _productsCollection!
        .get();
      
      final categories = querySnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      print('Error getting product categories: $e');
      return [];
    }
  }
}