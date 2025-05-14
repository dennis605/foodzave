import 'package:flutter/material.dart';
import 'package:foodzave/models/inventory_item.dart';
import 'package:foodzave/services/inventory_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItem> _expiringItems = [];
  List<InventoryItem> _allActiveItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeItems = await _inventoryService.getActiveInventoryItems();
      final expiringItems = activeItems.where((item) => item.isAboutToExpire || item.isExpired).toList();
      
      // Sort by expiration date (soonest first)
      expiringItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      activeItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      setState(() {
        _expiringItems = expiringItems;
        _allActiveItems = activeItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Fehler beim Laden der Daten');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodZave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCard(),
                      const SizedBox(height: 20),
                      _buildExpiringSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final expiredCount = _allActiveItems.where((item) => item.isExpired).length;
    final aboutToExpireCount = _allActiveItems.where((item) => item.isAboutToExpire && !item.isExpired).length;
    final goodCount = _allActiveItems.length - expiredCount - aboutToExpireCount;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bestandsübersicht',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Bald ablaufend', aboutToExpireCount, Colors.orange),
            const SizedBox(height: 8),
            _buildStatusRow('Abgelaufen', expiredCount, Colors.red),
            const SizedBox(height: 8),
            _buildStatusRow('In Ordnung', goodCount, Colors.green),
            const SizedBox(height: 8),
            _buildStatusRow('Insgesamt', _allActiveItems.length, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(count.toString()),
      ],
    );
  }

  Widget _buildExpiringSection() {
    if (_expiringItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Keine ablaufenden Lebensmittel! 🎉',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bald ablaufende Lebensmittel',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...List.generate(
          _expiringItems.length > 5 ? 5 : _expiringItems.length,
          (index) {
            final item = _expiringItems[index];
            final product = item.product;
            
            final bool isExpired = item.isExpired;
            final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
              child: ListTile(
                title: Text(product?.name ?? 'Unbekanntes Produkt'),
                subtitle: Text(
                  isExpired
                      ? 'Abgelaufen seit ${-daysUntilExpiry} Tagen'
                      : 'Läuft in $daysUntilExpiry Tagen ab',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    await _inventoryService.markItemAsConsumed(item.id);
                    _loadData();
                  },
                  tooltip: 'Als verbraucht markieren',
                ),
              ),
            );
          },
        ),
        if (_expiringItems.length > 5)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to inventory tab
                  Navigator.of(context).pushNamed('/inventory');
                },
                child: const Text('Alle anzeigen'),
              ),
            ),
          ),
      ],
    );
  }
}