import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:foodzave/models/inventory_item.dart';
import 'package:foodzave/services/auth_service.dart';

class NotificationService {
  // Singleton-Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();
  
  // Initialisierung
  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/app_icon');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Hier kann optional die Aktion beim Tippen auf die Benachrichtigung definiert werden
        },
      );
    } catch (e) {
      print('Benachrichtigungsdienst-Initialisierung fehlgeschlagen: $e');
      // Für Web/Demo-Zwecke ignorieren wir Fehler
    }
  }
  
  // Berechtigung für Benachrichtigungen anfragen
  Future<bool> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    return result ?? false;
  }
  
  // Erinnerung für ein Inventar-Element planen
  Future<void> scheduleExpiryReminder(InventoryItem item) async {
    final notificationsEnabled = await _authService.getNotificationsEnabled();
    if (!notificationsEnabled || item.product == null) return;
    
    // Berechne den Zeitpunkt für die Benachrichtigung
    final reminderDate = item.expiryDate.subtract(Duration(days: item.reminderDays));
    
    // Falls das Erinnerungsdatum in der Vergangenheit liegt, keine Benachrichtigung planen
    if (reminderDate.isBefore(DateTime.now())) return;
    
    // Eindeutige ID für die Benachrichtigung (basierend auf der Item-ID)
    final int notificationId = item.id.hashCode;
    
    final productName = item.product?.name ?? 'Ein Produkt';
    
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'expiry_reminders',
      'Ablaufbenachrichtigungen',
      channelDescription: 'Benachrichtigungen über bald ablaufende Lebensmittel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/app_icon',
    );
    
    final DarwinNotificationDetails iosDetails =
        const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Lebensmittel läuft bald ab',
      '$productName läuft in ${item.reminderDays} Tagen ab.',
      tz.TZDateTime.from(reminderDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: item.id,
    );
  }
  
  // Benachrichtigung für ein Element abbrechen
  Future<void> cancelReminderForItem(String itemId) async {
    final int notificationId = itemId.hashCode;
    await _notificationsPlugin.cancel(notificationId);
  }
  
  // Alle Benachrichtigungen abbrechen
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Sofortige Testbenachrichtigung anzeigen
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_notifications',
      'Testbenachrichtigungen',
      channelDescription: 'Benachrichtigungen zum Testen',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/app_icon',
    );
    
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notificationsPlugin.show(
      0,
      'Test-Benachrichtigung',
      'Dies ist eine Test-Benachrichtigung von FoodZave.',
      notificationDetails,
    );
  }
}