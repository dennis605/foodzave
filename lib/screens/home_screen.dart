import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodZave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo-Modus: Daten aktualisiert')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildOverviewCard(),
            const SizedBox(height: 20),
            _buildExpiringSection(),
            const SizedBox(height: 20),
            _buildQuickActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, size: 32, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Willkommen bei FoodZave!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Verwalte deine Lebensmittel intelligent und vermeide Verschwendung. '
              'Diese Demo zeigt alle Hauptfunktionen der App.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bestandsübersicht (Demo)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Bald ablaufend', 2, Colors.orange),
            const SizedBox(height: 8),
            _buildStatusRow('Abgelaufen', 1, Colors.red),
            const SizedBox(height: 8),
            _buildStatusRow('In Ordnung', 5, Colors.green),
            const SizedBox(height: 8),
            _buildStatusRow('Insgesamt', 8, Colors.blue),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bald ablaufende Lebensmittel (Demo)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _buildExpiringItem('Vollmilch', 'Läuft in 2 Tagen ab', Colors.orange),
        _buildExpiringItem('Äpfel', 'Läuft in 3 Tagen ab', Colors.orange),
        _buildExpiringItem('Brot', 'Abgelaufen seit 1 Tag', Colors.red),
      ],
    );
  }

  Widget _buildExpiringItem(String name, String subtitle, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.1),
      child: ListTile(
        title: Text(name),
        subtitle: Text(subtitle),
        leading: Icon(Icons.food_bank, color: color),
        trailing: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name als verbraucht markiert (Demo)')),
            );
          },
          tooltip: 'Als verbraucht markieren',
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schnellaktionen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo: Barcode-Scanner würde sich öffnen')),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scannen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo: Bestand würde sich öffnen')),
                      );
                    },
                    icon: const Icon(Icons.inventory),
                    label: const Text('Bestand'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo: Einkaufsliste würde sich öffnen')),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Einkaufsliste'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}