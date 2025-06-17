import 'dart:async';
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

// Mock Firebase User für Demo-Zwecke
class _MockFirebaseUser implements User {
  final MockUser _mockUser;
  
  _MockFirebaseUser(this._mockUser);
  
  @override
  String get uid => _mockUser.uid;
  
  @override
  String? get email => _mockUser.email;
  
  @override
  String? get displayName => _mockUser.displayName;
  
  @override
  bool get emailVerified => true;
  
  @override
  bool get isAnonymous => false;
  
  @override
  UserMetadata get metadata => throw UnimplementedError();
  
  @override
  String? get phoneNumber => null;
  
  @override
  String? get photoURL => null;
  
  @override
  List<UserInfo> get providerData => [];
  
  @override
  String? get refreshToken => null;
  
  @override
  String? get tenantId => null;
  
  @override
  Future<void> delete() => throw UnimplementedError();
  
  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();
  
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();
  
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();
  
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();
  
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();
  
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
  
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();
  
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<void> reload() => throw UnimplementedError();
  
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
  
  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();
  
  @override
  Future<void> updateDisplayName(String? displayName) => throw UnimplementedError();
  
  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();
  
  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();
  
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();
  
  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();
  
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => throw UnimplementedError();
  
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
  
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();
}

class AuthService {
  FirebaseAuth? _auth;
  bool _isFirebaseAvailable = false;
  
  // Mock user für Demo-Zwecke
  MockUser? _mockUser;
  
  // Stream Controller für Demo-Modus
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  
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
      // Für Demo-Modus: Stream initial mit null füllen (nicht angemeldet)
      _authStateController.add(null);
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
      // Für Demo-Modus verwenden wir den StreamController
      return _authStateController.stream;
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
    if (_mockUser != null) {
      // Erstelle einen Mock User für Demo-Zwecke
      // Da wir keinen echten Firebase User erstellen können, verwenden wir einen Trick
      // und geben einen Mock zurück, der die wichtigsten Eigenschaften hat
      return _MockFirebaseUser(_mockUser!);
    }
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
  
  // Demo-Anmeldung
  Future<void> signInAsDemo() async {
    _mockUser = MockUser(
      email: 'demo@foodzave.com',
      uid: 'demo-user-123',
      displayName: 'Demo Benutzer'
    );
    
    // Simuliere eine kurze Verzögerung für bessere UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Stream aktualisieren
    _authStateController.add(_createMockFirebaseUser());
    
    if (kDebugMode) {
      print('Demo-Modus aktiviert');
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