import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton-Pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // Stream für Authentifizierungsstatus
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Aktueller Benutzer
  User? get currentUser => _auth.currentUser;
  
  // Registrierung mit E-Mail und Passwort
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
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
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
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
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei der Abmeldung: $e');
      }
      rethrow;
    }
  }
  
  // Passwort zurücksetzen
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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