import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Background Data: ${message.data}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ FIX 1: late hata diya — null safe kiya
  Function(Map<String, dynamic>)? onNotificationClick;

  // ✅ FIX 2: Pending data — HomeScreen mount hone se pehle aaye to store karo
  Map<String, dynamic>? _pendingData;

  // ✅ HomeScreen initState se yeh call karo
  void deliverPendingNotification() {
    if (_pendingData != null && onNotificationClick != null) {
      final data = _pendingData!;
      _pendingData = null;
      onNotificationClick!(data);
    }
  }

  Future<void> init({
    required Function(Map<String, dynamic>) onNotificationClicked,
  }) async {
    try {
      onNotificationClick = onNotificationClicked;

      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationClick(details);
        },
      );

      await _createNotificationChannel();
      _handleForegroundMessages();

      // ✅ FIX 3: Background click listener — yeh pehle missing tha
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Background notification clicked: ${message.data}');
        if (message.data.isNotEmpty) {
          if (onNotificationClick != null) {
            onNotificationClick!(message.data);
          } else {
            _pendingData = message.data;
          }
        }
      });

      _handleTerminatedState();

      print('✅ Notification Service Initialized');
    } catch (e) {
      print('❌ Notification Init Error: $e');
    }
  }

  void _handleNotificationClick(NotificationResponse details) {
    print('Notification clicked: ${details.payload}');
    if (details.payload != null && details.payload!.isNotEmpty) {
      try {
        final payloadData = Uri.parse('?${details.payload!}').queryParameters;
        if (onNotificationClick != null) {
          onNotificationClick!(payloadData);
        } else {
          _pendingData = payloadData;
        }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }
  }

  void _handleTerminatedState() async {
    RemoteMessage? message = await _fcm.getInitialMessage();
    if (message != null && message.data.isNotEmpty) {
      print('App opened from terminated state');
      // ✅ Hamesha _pendingData mein rakho
      // HomeScreen mount hone par deliver hoga
      _pendingData = message.data;
    }
  }

  Future<void> _createNotificationChannel() async {
    // Corrected Syntax: The <Type> goes BEFORE the ()
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_channel',
        'Emergency Notifications',
        description: 'High priority notifications with alarm sound',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_warning'),
        enableVibration: true,
      );

      // Now this will work because androidPlugin is correctly typed
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message data: ${message.data}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final payload = message.data.isEmpty
        ? ''
        : Uri(queryParameters: message.data).query.replaceFirst('?', '');

    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_warning'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? 'Alert',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  Future<String?> getToken() async => await _fcm.getToken();

  Future<void> deleteToken() async {
    try {
      await _localNotifications.cancelAll();
      await _fcm.deleteToken();
      print('✅ Token deleted successfully');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }
}
