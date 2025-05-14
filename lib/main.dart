import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foodzave/screens/home_screen.dart';
import 'package:foodzave/screens/scan_screen.dart';
import 'package:foodzave/screens/inventory_screen.dart';
import 'package:foodzave/screens/shopping_list_screen.dart';
import 'package:foodzave/screens/auth_screen.dart';
import 'package:foodzave/services/auth_service.dart';
import 'package:foodzave/services/notification_service.dart';
import 'package:foodzave/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialisiere den Benachrichtigungsdienst
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(const FoodZaveApp());
}

class FoodZaveApp extends StatelessWidget {
  const FoodZaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodZave',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user != null ? const MainScreen() : const AuthScreen();
        }
        // Während wir auf den Authentifizierungszustand warten, zeigen wir einen Ladebildschirm
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const ScanScreen(),
    const InventoryScreen(),
    const ShoppingListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einstellungen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('Angemeldet als: ${AuthService().currentUser?.email ?? ""}'),
              subtitle: const Text('Tippe zum Abmelden'),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Benachrichtigungen testen'),
              onTap: () async {
                await NotificationService().showTestNotification();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test-Benachrichtigung gesendet!'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Übersicht',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scannen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Bestand',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Einkaufsliste',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSettingsDialog,
        child: const Icon(Icons.settings),
      ),
    );
  }
}
