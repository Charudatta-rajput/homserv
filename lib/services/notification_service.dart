import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    await FirebaseMessaging.instance.requestPermission();
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    print('📩 Background message: ${message.data}');
  }

  static void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        DateTime.now().millisecond,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'booking_channel',
            'Booking Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  static Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}