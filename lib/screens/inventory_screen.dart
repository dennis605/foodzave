import 'package:flutter/material.dart';
import 'package:foodzave/models/inventory_item.dart';
import 'package:foodzave/services/inventory_service.dart';
import 'package:foodzave/services/shopping_list_service.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ShoppingListService _shoppingListService = ShoppingListService();
  
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  
  // Filter-Optionen
  String _searchQuery = '';
  String _selectedCategory = 'Alle';
  List<String> _categories = ['Alle'];
  String _sortBy = 'MHD';
  bool _showExpiredOnly = false;
  bool _showExpiringOnly = false;
  
  @override
  void initState() {
    super.initState();
    _loadInventory();
  }
  
  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await _inventoryService.getActiveInventoryItems();
      
      // Extrahiere alle Kategorien
      final allCategories = items
          .map((item) => item.product?.category ?? 'Unbekannt')
          .toSet()
          .toList();
      
      allCategories.sort();
      allCategories.insert(0, 'Alle');
      
      setState(() {
        _inventoryItems = items;
        _categories = allCategories;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Fehler beim Laden des Bestands');
    }
  }
  
  void _applyFilters() {
    List<InventoryItem> filteredList = List.from(_inventoryItems);
    
    // Filterung nach Suchbegriff
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        final product = item.product;
        if (product == null) return false;
        
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filterung nach Kategorie
    if (_selectedCategory != 'Alle') {
      filteredList = filteredList.where((item) => 
        item.product?.category == _selectedCategory
      ).toList();
    }
    
    // Filterung nach Status
    if (_showExpiredOnly) {
      filteredList = filteredList.where((item) => item.isExpired).toList();
    }
    
    if (_showExpiringOnly && !_showExpiredOnly) {
      filteredList = filteredList.where((item) => 
        item.isAboutToExpire && !item.isExpired
      ).toList();
    }
    
    // Sortierung
    switch (_sortBy) {
      case 'MHD':
        filteredList.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case 'Name':
        filteredList.sort((a, b) {
          final nameA = a.product?.name ?? '';
          final nameB = b.product?.name ?? '';
          return nameA.compareTo(nameB);
        });
        break;
      case 'Kategorie':
        filteredList.sort((a, b) {
          final categoryA = a.product?.category ?? '';
          final categoryB = b.product?.category ?? '';
          return categoryA.compareTo(categoryB);
        });
        break;
    }
    
    setState(() {
      _filteredItems = filteredList;
    });
  }
  
  void _showFilterOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter & Sortierung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sortieren nach:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'MHD', label: Text('MHD')),
                    ButtonSegment(value: 'Name', label: Text('Name')),
                    ButtonSegment(value: 'Kategorie', label: Text('Kategorie')),
                  ],
                  selected: {_sortBy},
                  onSelectionChanged: (Set<String> selection) {
                    setDialogState(() {
                      _sortBy = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Kategorie:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setDialogState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                  items: _categories
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Nur abgelaufene anzeigen'),
                  value: _showExpiredOnly,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setDialogState(() {
                        _showExpiredOnly = value;
                        if (value) {
                          _showExpiringOnly = false;
                        }
                      });
                    }
                  },
                ),
                CheckboxListTile(
                  title: const Text('Nur bald ablaufende anzeigen'),
                  value: _showExpiringOnly,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setDialogState(() {
                        _showExpiringOnly = value;
                        if (value) {
                          _showExpiredOnly = false;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Anwenden'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showItemOptionsDialog(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('Als verbraucht markieren'),
            onTap: () {
              Navigator.of(context).pop();
              _markAsConsumed(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Zur Einkaufsliste hinzufügen'),
            onTap: () {
              Navigator.of(context).pop();
              _addToShoppingList(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('MHD bearbeiten'),
            onTap: () {
              Navigator.of(context).pop();
              _editExpiryDate(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Löschen'),
            onTap: () {
              Navigator.of(context).pop();
              _deleteItem(item);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _markAsConsumed(InventoryItem item) async {
    try {
      await _inventoryService.markItemAsConsumed(item.id);
      
      // Einkaufsliste-Dialog anzeigen
      _showAddToShoppingListDialog(item);
      
      // Liste neu laden
      _loadInventory();
    } catch (e) {
      _showSnackBar('Fehler beim Markieren als verbraucht');
    }
  }
  
  void _showAddToShoppingListDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zur Einkaufsliste hinzufügen?'),
        content: Text(
          'Möchtest du ${item.product?.name ?? 'dieses Produkt'} zu deiner Einkaufsliste hinzufügen?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Nein'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addToShoppingList(item);
            },
            child: const Text('Ja, hinzufügen'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addToShoppingList(InventoryItem item) async {
    if (item.product != null) {
      try {
        await _shoppingListService.addShoppingListItem(
          productId: item.productId,
        );
        _showSnackBar('Zur Einkaufsliste hinzugefügt');
      } catch (e) {
        _showSnackBar('Fehler beim Hinzufügen zur Einkaufsliste');
      }
    }
  }
  
  Future<void> _editExpiryDate(InventoryItem item) async {
    DateTime selectedDate = item.expiryDate;
    int selectedReminderDays = item.reminderDays;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('MHD bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null && picked != selectedDate) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MHD:'),
                    Text(
                      DateFormat('dd.MM.yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Erinnerung vor (Tage):'),
                  DropdownButton<int>(
                    value: selectedReminderDays,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedReminderDays = newValue;
                        });
                      }
                    },
                    items: <int>[1, 2, 3, 5, 7, 14, 30]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _inventoryService.updateInventoryItem(
                    itemId: item.id,
                    expiryDate: selectedDate,
                    reminderDays: selectedReminderDays,
                  );
                  _loadInventory();
                  _showSnackBar('MHD wurde aktualisiert');
                } catch (e) {
                  _showSnackBar('Fehler beim Aktualisieren des MHDs');
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deleteItem(InventoryItem item) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produkt löschen'),
        content: Text(
          'Möchtest du ${item.product?.name ?? 'dieses Produkt'} wirklich aus deinem Bestand löschen?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      try {
        await _inventoryService.deleteInventoryItem(item.id);
        _loadInventory();
        _showSnackBar('Produkt wurde gelöscht');
      } catch (e) {
        _showSnackBar('Fehler beim Löschen des Produkts');
      }
    }
  }
  
  Color _getItemColor(InventoryItem item) {
    if (item.isExpired) {
      return Colors.red.shade50;
    } else if (item.isAboutToExpire) {
      return Colors.orange.shade50;
    } else {
      return Colors.transparent;
    }
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
        title: const Text('Mein Bestand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptionsDialog,
            tooltip: 'Filter & Sortierung',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Produkt suchen...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined, 
                                size: 64, 
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Keine Produkte gefunden',
                                style: TextStyle(fontSize: 18),
                              ),
                              if (_searchQuery.isNotEmpty || _selectedCategory != 'Alle' || 
                                  _showExpiredOnly || _showExpiringOnly)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedCategory = 'Alle';
                                      _showExpiredOnly = false;
                                      _showExpiringOnly = false;
                                      _applyFilters();
                                    });
                                  },
                                  child: const Text('Filter zurücksetzen'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadInventory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final product = item.product;
                              final daysUntilExpiry = item.expiryDate
                                  .difference(DateTime.now())
                                  .inDays;
                              
                              String expiryText;
                              if (item.isExpired) {
                                expiryText = 'Abgelaufen seit ${-daysUntilExpiry} Tagen';
                              } else if (daysUntilExpiry == 0) {
                                expiryText = 'Läuft heute ab';
                              } else {
                                expiryText = 'Läuft in $daysUntilExpiry Tagen ab';
                              }
                              
                              return Card(
                                color: _getItemColor(item),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    product?.name ?? 'Unbekanntes Produkt',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(expiryText),
                                      if (product != null && product.brand.isNotEmpty)
                                        Text(product.brand),
                                      if (product != null && product.category.isNotEmpty)
                                        Text(
                                          product.category,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: item.isExpired
                                        ? Colors.red
                                        : item.isAboutToExpire
                                            ? Colors.orange
                                            : Colors.green,
                                    child: Icon(
                                      item.isExpired
                                          ? Icons.warning
                                          : item.isAboutToExpire
                                              ? Icons.access_time
                                              : Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showItemOptionsDialog(item),
                                  ),
                                  onTap: () => _showItemOptionsDialog(item),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}