import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/user_session.dart';
import 'api_client.dart';

/// Runs in the background isolate when a push arrives while the app isn't
/// in the foreground. Must be a top-level function (FCM requirement).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here — Android shows the system notification for
  // background/terminated messages automatically as long as the payload
  // has a "notification" block (which fcm_helper.php always sends).
}

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Call once, early in main() after Firebase.initializeApp().
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    const channel = AndroidNotificationChannel(
      'scholivax_default',
      'Scholivax notifications',
      description: 'Circulars, attendance and other school updates.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Foreground messages don't show a system notification by themselves
    // on Android — show one manually so the teacher/parent/student sees it
    // even while the app is open.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scholivax_default',
            'Scholivax notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Registers this device's push token with the backend. Call right
  /// after login, and again whenever Firebase hands the app a refreshed
  /// token — both are wired up in [registerAndKeepInSync].
  static Future<void> registerAndKeepInSync(UserSession session) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _register(session, token);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _register(session, newToken);
    });
  }

  static Future<void> _register(UserSession session, String fcmToken) async {
    try {
      await ApiClient.post(
        session.baseUrl,
        '/api/device/register',
        {'fcm_token': fcmToken},
        token: session.token,
      );
    } catch (_) {
      // Best-effort — a failed registration just means push won't arrive
      // on this device until the next successful login/token refresh.
    }
  }

  /// Call on logout so this device stops receiving pushes for the account
  /// that just signed out.
  static Future<void> unregister(UserSession session) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiClient.post(
          session.baseUrl,
          '/api/device/unregister',
          {'fcm_token': token},
          token: session.token,
        );
      }
    } catch (_) {
      // Fine to ignore — worst case this device keeps getting pushes for
      // an account it's logged out of until the token naturally rotates.
    }
  }
}
