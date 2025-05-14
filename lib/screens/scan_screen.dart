import 'package:flutter/material.dart';
import 'package:foodzave/models/product.dart';
import 'package:foodzave/models/inventory_item.dart';
import 'package:foodzave/services/barcode_service.dart';
import 'package:foodzave/services/product_service.dart';
import 'package:foodzave/services/inventory_service.dart';
import 'package:intl/intl.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  
  bool _isLoading = false;
  String? _scannedBarcode;
  Product? _foundProduct;
  String _errorMessage = '';
  
  // Controller für das manuelle Hinzufügen
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  
  // MHD Eingabe
  DateTime _selectedExpiryDate = DateTime.now().add(const Duration(days: 7));
  int _selectedReminderDays = 3;
  
  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _isLoading = true;
      _scannedBarcode = null;
      _foundProduct = null;
      _errorMessage = '';
    });

    try {
      final barcode = await _barcodeService.scanBarcode();
      
      if (barcode == null) {
        setState(() {
          _errorMessage = 'Scanvorgang abgebrochen';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _scannedBarcode = barcode;
      });
      
      await _lookupProduct(barcode);
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Scannen: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _lookupProduct(String barcode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Zuerst in lokaler Datenbank suchen
      Product? product = await _productService.getProductByBarcode(barcode);
      
      if (product == null) {
        // Wenn nicht lokal vorhanden, dann online suchen
        product = await _productService.fetchProductFromOpenGtinDB(barcode);
        
        if (product != null) {
          // Neues Produkt in lokaler Datenbank speichern
          await _productService.saveProduct(product);
        }
      }
      
      if (product != null) {
        setState(() {
          _foundProduct = product;
          
          // Vorschlag für Erinnerungstage basierend auf Kategorie setzen
          _selectedReminderDays = _inventoryService.getSuggestedReminderDays(product?.category ?? '');
        });
        
        // Prüfen, ob es bereits Einträge für dieses Produkt gibt
        final existingItems = await _inventoryService.getInventoryItemsByProductId(product.id);
        
        if (existingItems.isNotEmpty) {
          _showExistingItemsDialog(existingItems);
        }
      } else {
        setState(() {
          _errorMessage = 'Produkt nicht gefunden. Bitte manuell eingeben.';
          _barcodeController.text = barcode;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler bei der Produktsuche: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showExistingItemsDialog(List<InventoryItem> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produkt bereits vorhanden'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text('Dieses Produkt ist bereits in deinem Bestand. Möchtest du:'),
                );
              }
              
              final item = items[index - 1];
              final expiryDateStr = DateFormat('dd.MM.yyyy').format(item.expiryDate);
              
              return ListTile(
                title: Text('Als verbraucht markieren'),
                subtitle: Text('MHD: $expiryDateStr'),
                leading: const Icon(Icons.check_circle_outline),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _inventoryService.markItemAsConsumed(item.id);
                  _showSnackBar('Produkt wurde als verbraucht markiert');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddExpiryDateDialog();
            },
            child: const Text('Neues MHD hinzufügen'),
          ),
        ],
      ),
    );
  }
  
  void _showAddExpiryDateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mindesthaltbarkeitsdatum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bitte wähle das Mindesthaltbarkeitsdatum aus:'),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedExpiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (picked != null && picked != _selectedExpiryDate) {
                  setState(() {
                    _selectedExpiryDate = picked;
                  });
                  Navigator.of(context).pop();
                  _showAddExpiryDateDialog();  // Dialog mit neuem Datum neu öffnen
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MHD:'),
                  Text(
                    DateFormat('dd.MM.yyyy').format(_selectedExpiryDate),
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
                  value: _selectedReminderDays,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedReminderDays = newValue;
                      });
                      Navigator.of(context).pop();
                      _showAddExpiryDateDialog();  // Dialog mit neuem Wert neu öffnen
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addProductToInventory();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addProductToInventory() async {
    if (_foundProduct == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _inventoryService.addInventoryItem(
        productId: _foundProduct!.id,
        expiryDate: _selectedExpiryDate,
        reminderDays: _selectedReminderDays,
      );
      
      _showSnackBar('Produkt wurde zum Bestand hinzugefügt');
      
      setState(() {
        _scannedBarcode = null;
        _foundProduct = null;
      });
    } catch (e) {
      _showSnackBar('Fehler beim Hinzufügen: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _addManualProduct() async {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final category = _categoryController.text.trim();
    final barcode = _barcodeController.text.trim();
    
    if (name.isEmpty || category.isEmpty) {
      _showSnackBar('Bitte fülle mindestens Name und Kategorie aus');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Manuelles Produkt erstellen
      final product = await _productService.createManualProduct(
        name: name,
        brand: brand,
        category: category,
        barcode: barcode,
      );
      
      // Produkt zum Bestand hinzufügen
      await _inventoryService.addInventoryItem(
        productId: product.id,
        expiryDate: _selectedExpiryDate,
        reminderDays: _selectedReminderDays,
      );
      
      _showSnackBar('Produkt wurde manuell hinzugefügt');
      
      // Felder zurücksetzen
      _nameController.clear();
      _brandController.clear();
      _categoryController.clear();
      _barcodeController.clear();
      
      setState(() {
        _scannedBarcode = null;
        _foundProduct = null;
      });
    } catch (e) {
      _showSnackBar('Fehler beim Hinzufügen: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Produkt scannen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Scanne den Barcode eines Produkts oder füge es manuell hinzu.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Barcode scannen'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_scannedBarcode != null)
                    Card(
                      margin: const EdgeInsets.only(top: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gescannter Barcode:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _scannedBarcode!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_foundProduct != null)
                    Card(
                      margin: const EdgeInsets.only(top: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gefundenes Produkt:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              _foundProduct!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            if (_foundProduct!.brand.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Marke: ${_foundProduct!.brand}'),
                              ),
                            if (_foundProduct!.category.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Kategorie: ${_foundProduct!.category}'),
                              ),
                            const SizedBox(height: 16.0),
                            ElevatedButton.icon(
                              onPressed: () => _showAddExpiryDateDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Mit MHD hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_errorMessage.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(top: 16.0),
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage.contains('manuell eingeben'))
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  'Produkt manuell hinzufügen:',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_errorMessage.contains('manuell eingeben'))
                    Card(
                      margin: const EdgeInsets.only(top: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name*',
                                hintText: 'z.B. Milch',
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Marke',
                                hintText: 'z.B. Markenname',
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Kategorie*',
                                hintText: 'z.B. Milchprodukte',
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextField(
                              controller: _barcodeController,
                              readOnly: _scannedBarcode != null,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                hintText: 'z.B. 4000000123456',
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ElevatedButton.icon(
                              onPressed: () => _showAddExpiryDateDialog(),
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('MHD festlegen'),
                            ),
                            const SizedBox(height: 8.0),
                            ElevatedButton.icon(
                              onPressed: _addManualProduct,
                              icon: const Icon(Icons.add),
                              label: const Text('Produkt hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}