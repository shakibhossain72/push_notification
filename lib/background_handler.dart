 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
 
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
 
  if (kDebugMode) {
    print('📩 Background message received: ${message.messageId}');
  }
 
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
 
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
  );
 
   flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
 
  String? title;
  String? body;
 
  if (message.notification != null) {
    title = message.notification!.title;
    body = message.notification!.body;
  } else if (message.data.isNotEmpty) {
    title = message.data['title'];
    body = message.data['body'];
  }
 
  if (title != null || body != null) {
   await flutterLocalNotificationsPlugin.show(
  id: message.messageId.hashCode,
  title: title ?? 'Notification',
  body: body ?? '',
  notificationDetails: const NotificationDetails(
    android: AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  ),
);
  }
}








// final code.......................................................


// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();

//   if (kDebugMode) {
//     print('📩 Background message received: ${message.messageId}');
//   }

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'high_importance_channel',
//     'High Importance Notifications',
//     description: 'Used for important notifications',
//     importance: Importance.high,
//   );

//    flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   String? title;
//   String? body;

//   if (message.notification != null) {
//     title = message.notification!.title;
//     body = message.notification!.body;
//   } else if (message.data.isNotEmpty) {
//     title = message.data['title'];
//     body = message.data['body'];
//   }

//   if (title != null || body != null) {
//    await flutterLocalNotificationsPlugin.show(
//   id: message.messageId.hashCode,
//   title: title ?? 'Notification',
//   body: body ?? '',
//   notificationDetails: const NotificationDetails(
//     android: AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       channelDescription: 'Used for important notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//     ),
//   ),
// );
//   }
// }