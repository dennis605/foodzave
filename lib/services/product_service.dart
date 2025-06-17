import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodzave/models/product.dart';

class ProductService {
  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();
  
  // Firestore reference
  final CollectionReference _productsCollection = 
      FirebaseFirestore.instance.collection('products');
  
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
    try {
      await _productsCollection.doc(product.id).set(product.toMap());
    } catch (e) {
      print('Error saving product: $e');
      rethrow;
    }
  }
  
  /// Retrieves product from Firestore by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final querySnapshot = await _productsCollection
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
    try {
      final docSnapshot = await _productsCollection.doc(productId).get();
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
    try {
      final querySnapshot = await _productsCollection
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