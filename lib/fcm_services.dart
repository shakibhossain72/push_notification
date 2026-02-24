import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:test/notification_screen.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('🔑 FCM Token: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get FCM token: $e');
      }
    }

    await _initLocalNotification();
    _initPushNotifications();
  }

  Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Get.to(() => NotificationsScreen());
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    Get.to(() => NotificationsScreen(), arguments: message);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;

    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void _initPushNotifications() {
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }
}









// final code.......................................................


// // fcm_service.dart
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'package:test/notification_screen.dart';

// class FcmService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initNotifications() async {
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//     );

//     try {
//       final token = await FirebaseMessaging.instance.getToken();
//       if (token != null) {
//         if (kDebugMode) {
//           print('🔑 FCM Token: $token');
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Failed to get FCM token: $e');
//       }
//     }

//     await _initLocalNotification();
//     _initPushNotifications();
//   }

//   Future<void> _initLocalNotification() async {
//     const AndroidInitializationSettings androidInit =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidInit,
//     );

//     await _localNotifications.initialize(
//       settings: initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         Get.to(() => NotificationsScreen());
//       },
//     );

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'Used for important notifications',
//       importance: Importance.high,
//     );

//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }

//   void _handleMessage(RemoteMessage? message) {
//     if (message == null) return;
//     Get.to(() => NotificationsScreen(), arguments: message);
//   }

//   // ✅ এখানে data এবং notification উভয় থেকে title/body নিন
//  void _showForegroundNotification(RemoteMessage message) {
//   String? title;
//   String? body;

//   if (message.notification != null) {
//     title = message.notification!.title;
//     body = message.notification!.body;
//   } else if (message.data.isNotEmpty) {
//     title = message.data['title'];
//     body = message.data['body'];
//   }

//   if (title == null && body == null) return;

//   _localNotifications.show(
//     id: message.messageId.hashCode,  
//     title: title ?? 'Notification',
//     body: body ?? '',
//     notificationDetails: const NotificationDetails( 
//       android: AndroidNotificationDetails(
//         'high_importance_channel',
//         'High Importance Notifications',
//         importance: Importance.max,
//         priority: Priority.high,
//         icon: '@mipmap/ic_launcher',
//       ),
//     ),
//   );
// }

//   void _initPushNotifications() {
//     FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
//     FirebaseMessaging.onMessage.listen(_showForegroundNotification);
//   }
// }