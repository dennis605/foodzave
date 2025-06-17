import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Einfache Mock User Klasse für Demo-Zwecke
class MockUser {
  final String email;
  final String uid;
  final String displayName;
  
  MockUser({
    required this.email, 
    required this.uid,
    this.displayName = 'Demo User'
  });
}

class AuthService {
  FirebaseAuth? _auth;
  bool _isFirebaseAvailable = false;
  
  // Mock user für Demo-Zwecke
  MockUser? _mockUser;
  
  // Singleton-Pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      _isFirebaseAvailable = true;
    } catch (e) {
      _isFirebaseAvailable = false;
      _mockUser = MockUser(email: 'demo@foodzave.com', uid: 'demo-user-123');
      if (kDebugMode) {
        print('Firebase nicht verfügbar, verwende Mock-Authentifizierung');
      }
    }
  }
  
  // Stream für Authentifizierungsstatus
  Stream<User?> get authStateChanges {
    if (_isFirebaseAvailable && _auth != null) {
      return _auth!.authStateChanges();
    } else {
      // Mock stream für Demo - simuliere einen eingeloggten Benutzer
      return Stream.value(_createMockFirebaseUser());
    }
  }
  
  // Aktueller Benutzer
  User? get currentUser {
    if (_isFirebaseAvailable && _auth != null) {
      return _auth!.currentUser;
    } else {
      return _createMockFirebaseUser();
    }
  }
  
  // Erstelle einen Mock Firebase User
  User? _createMockFirebaseUser() {
    // Für Demo-Zwecke geben wir null zurück, damit die AuthScreen angezeigt wird
    return null;
  }
  
  // Registrierung mit E-Mail und Passwort
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    if (!_isFirebaseAvailable || _auth == null) {
      // Mock-Registrierung für Demo
      _mockUser = MockUser(email: email, uid: 'mock-${DateTime.now().millisecondsSinceEpoch}');
      return null;
    }
    
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei der Registrierung: $e');
      }
      rethrow;
    }
  }
  
  // Anmeldung mit E-Mail und Passwort
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    if (!_isFirebaseAvailable || _auth == null) {
      // Mock-Anmeldung für Demo
      _mockUser = MockUser(email: email, uid: 'mock-${DateTime.now().millisecondsSinceEpoch}');
      return null;
    }
    
    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei der Anmeldung: $e');
      }
      rethrow;
    }
  }
  
  // Abmeldung
  Future<void> signOut() async {
    if (!_isFirebaseAvailable || _auth == null) {
      // Mock-Abmeldung für Demo
      _mockUser = null;
      return;
    }
    
    try {
      await _auth!.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei der Abmeldung: $e');
      }
      rethrow;
    }
  }
  
  // Passwort zurücksetzen
  Future<void> resetPassword(String email) async {
    if (!_isFirebaseAvailable || _auth == null) {
      // Mock für Demo
      if (kDebugMode) {
        print('Mock: Passwort-Reset E-Mail würde an $email gesendet');
      }
      return;
    }
    
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Zurücksetzen des Passworts: $e');
      }
      rethrow;
    }
  }
  
  // Benutzereinstellungen speichern
  Future<void> saveUserSettings({
    required String userId,
    required int defaultReminderDays,
    required bool enableNotifications,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('default_reminder_days', defaultReminderDays);
      await prefs.setBool('enable_notifications', enableNotifications);
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Speichern der Benutzereinstellungen: $e');
      }
      rethrow;
    }
  }
  
  // Standard-Erinnerungstage abrufen
  Future<int> getDefaultReminderDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('default_reminder_days') ?? 3;  // Standard: 3 Tage
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Abrufen der Erinnerungstage: $e');
      }
      return 3;  // Standardwert im Fehlerfall
    }
  }
  
  // Benachrichtigungen aktiviert?
  Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('enable_notifications') ?? true;  // Standard: Aktiviert
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Abrufen der Benachrichtigungseinstellungen: $e');
      }
      return true;  // Standardwert im Fehlerfall
    }
  }
}