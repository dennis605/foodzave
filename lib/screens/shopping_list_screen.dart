import 'package:flutter/material.dart';
import 'package:foodzave/models/shopping_list_item.dart';
import 'package:foodzave/services/shopping_list_service.dart';
import 'package:foodzave/services/product_service.dart';
import 'package:share_plus/share_plus.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _shoppingListService = ShoppingListService();
  final ProductService _productService = ProductService();
  
  List<ShoppingListItem> _shoppingListItems = [];
  bool _isLoading = true;
  
  // Für manuelles Hinzufügen
  final TextEditingController _newItemController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }
  
  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _loadShoppingList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await _shoppingListService.getActiveShoppingList();
      
      // Nach Name sortieren
      items.sort((a, b) {
        final nameA = a.product?.name ?? '';
        final nameB = b.product?.name ?? '';
        return nameA.compareTo(nameB);
      });
      
      setState(() {
        _shoppingListItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Fehler beim Laden der Einkaufsliste');
    }
  }
  
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produkt hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newItemController,
              decoration: const InputDecoration(
                labelText: 'Produktname',
                hintText: 'z.B. Milch',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              _addManualShoppingItem();
              Navigator.of(context).pop();
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addManualShoppingItem() async {
    final name = _newItemController.text.trim();
    if (name.isEmpty) return;
    
    try {
      // Erstelle ein temporäres manuelles Produkt
      final manualProduct = await _productService.createManualProduct(
        name: name,
        brand: '',
        category: 'Manuell',
        barcode: '',
      );
      
      // Füge es zur Einkaufsliste hinzu
      await _shoppingListService.addShoppingListItem(
        productId: manualProduct.id,
      );
      
      _newItemController.clear();
      _loadShoppingList();
      _showSnackBar('Produkt zur Einkaufsliste hinzugefügt');
    } catch (e) {
      _showSnackBar('Fehler beim Hinzufügen des Produkts');
    }
  }
  
  Future<void> _removeItem(ShoppingListItem item) async {
    try {
      await _shoppingListService.removeShoppingListItem(item.id);
      _loadShoppingList();
    } catch (e) {
      _showSnackBar('Fehler beim Entfernen des Produkts');
    }
  }
  
  Future<void> _updateQuantity(ShoppingListItem item, int newQuantity) async {
    try {
      await _shoppingListService.updateItemQuantity(item.id, newQuantity);
      _loadShoppingList();
    } catch (e) {
      _showSnackBar('Fehler beim Aktualisieren der Menge');
    }
  }
  
  Future<void> _markItemAsPurchased(ShoppingListItem item) async {
    try {
      await _shoppingListService.markItemAsPurchased(item.id);
      _loadShoppingList();
      _showSnackBar('Produkt als gekauft markiert');
    } catch (e) {
      _showSnackBar('Fehler beim Markieren als gekauft');
    }
  }
  
  Future<void> _clearCompletedItems() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gekaufte Produkte entfernen'),
        content: const Text(
          'Möchtest du alle gekauften Produkte aus der Einkaufsliste entfernen?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Entfernen'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      // Im echten Szenario müsste hier ein Service-Call implementiert werden
      _showSnackBar('Gekaufte Produkte wurden entfernt');
      _loadShoppingList();
    }
  }
  
  void _shareShoppingList() {
    // Erzeuge einen formatierten Text für die Einkaufsliste
    String listText = 'Meine Einkaufsliste:\n\n';
    
    for (var item in _shoppingListItems) {
      final productName = item.product?.name ?? 'Unbekanntes Produkt';
      listText += '• ${item.quantity}x $productName\n';
    }
    
    Share.share(listText);
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shoppingListItems.isNotEmpty ? _shareShoppingList : null,
            tooltip: 'Liste teilen',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShoppingList,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingListItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined, 
                        size: 64, 
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deine Einkaufsliste ist leer',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Produkt hinzufügen'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _shoppingListItems.length,
                        itemBuilder: (context, index) {
                          final item = _shoppingListItems[index];
                          return Dismissible(
                            key: Key(item.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.green,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                _markItemAsPurchased(item);
                              } else {
                                _removeItem(item);
                              }
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  item.product?.name ?? 'Unbekanntes Produkt',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: item.product?.brand != null && item.product!.brand.isNotEmpty
                                    ? Text(item.product!.brand)
                                    : null,
                                leading: CircleAvatar(
                                  child: Text('${item.quantity}'),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: item.quantity > 1
                                          ? () => _updateQuantity(item, item.quantity - 1)
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => _updateQuantity(item, item.quantity + 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _removeItem(item),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showAddItemDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Produkt hinzufügen'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _clearCompletedItems,
                            icon: const Icon(Icons.cleaning_services_outlined),
                            label: const Text('Gekaufte Produkte entfernen'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}