import 'package:flutter/material.dart';
import 'package:foodzave/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte gib E-Mail und Passwort ein.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      if (_isLogin) {
        await _authService.signInWithEmailAndPassword(email, password);
      } else {
        await _authService.registerWithEmailAndPassword(email, password);
        
        // Optional: Benutzer automatisch anmelden nach Registrierung
        if (_authService.currentUser != null) {
          // Standardeinstellungen für neuen Benutzer speichern
          await _authService.saveUserSettings(
            userId: _authService.currentUser!.uid,
            defaultReminderDays: 3,
            enableNotifications: true,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'Benutzer nicht gefunden.';
            break;
          case 'wrong-password':
            _errorMessage = 'Falsches Passwort.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'Diese E-Mail wird bereits verwendet.';
            break;
          case 'weak-password':
            _errorMessage = 'Das Passwort ist zu schwach.';
            break;
          case 'invalid-email':
            _errorMessage = 'Ungültige E-Mail-Adresse.';
            break;
          default:
            _errorMessage = 'Ein Fehler ist aufgetreten: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ein unerwarteter Fehler ist aufgetreten.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte gib deine E-Mail-Adresse ein.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _authService.resetPassword(email);
      setState(() {
        _errorMessage = '';
      });
      _showSnackBar('Eine E-Mail zum Zurücksetzen des Passworts wurde gesendet.');
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Zurücksetzen des Passworts.';
      });
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
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Demo-Modus Button ganz oben
              OutlinedButton(
                onPressed: _isLoading ? null : _enterDemoMode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.preview, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Demo-Modus',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // App-Logo
              Icon(
                Icons.eco_outlined,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'FoodZave',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lebensmittel retten, Ressourcen schonen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              // Formular
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitForm(),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Anmelde-/Registrierungsbutton
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isLogin ? 'Anmelden' : 'Registrieren'),
              ),
              const SizedBox(height: 16),
              // Passwort vergessen
              if (_isLogin)
                TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: const Text('Passwort vergessen?'),
                ),
              const SizedBox(height: 16),
              // Zwischen Anmeldung und Registrierung wechseln
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin
                      ? 'Noch kein Konto?'
                      : 'Bereits ein Konto?'),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = '';
                            });
                          },
                    child: Text(
                      _isLogin ? 'Registrieren' : 'Anmelden',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _enterDemoMode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _authService.signInAsDemo();
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Starten des Demo-Modus.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}