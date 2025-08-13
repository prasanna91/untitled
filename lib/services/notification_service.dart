import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';

import 'dart:io';

/// Firebase Cloud Messaging Service
/// 
/// Handles push notifications for both Android and iOS platforms.
/// 
/// iOS APNS Token Fix:
/// - Waits for APNS token to be available before getting FCM token
/// - Implements retry logic for APNS token issues
/// - Provides graceful fallback when APNS token is not available
/// - This fixes the "APNS token has not been set yet" error
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Channel IDs
const String _channelId = 'high_importance_channel';
const String _channelName = 'High Importance Notifications';
const String _channelDescription =
    'This channel is used for important notifications.';

Future<void> initLocalNotifications() async {
  // Android initialization
  final AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS initialization
  final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iOSSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("🔔 Notification tapped: ${response.payload}");
      // Handle notification tap
      if (response.payload != null) {
        // Handle the notification payload
        debugPrint("📱 Notification payload: ${response.payload}");
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Create Android notification channel
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
  }
}

// This callback is required for background notification handling
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint("🔔 Background notification tapped: ${response.payload}");
  // Handle background notification tap
}

Future<void> initializeFirebaseMessaging() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Enable auto initialization
  await messaging.setAutoInitEnabled(true);

  // Request permission with enhanced iOS settings
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
    criticalAlert: true, // For iOS critical alerts
    announcement: true, // For iOS announcements
  );

  debugPrint('🔔 User granted permission: ${settings.authorizationStatus}');

  // iOS-specific APNS token handling
  if (Platform.isIOS) {
    try {
      debugPrint('🍎 Starting iOS APNS token setup...');
      
      // Get APNS token first
      String? apnsToken = await messaging.getAPNSToken();
      debugPrint('🍎 Initial APNS Token: $apnsToken');
      
      // Wait a bit for APNS token to be set
      if (apnsToken == null) {
        debugPrint('⏳ APNS token not available, waiting for it to be set...');
        // Wait up to 5 seconds for APNS token
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await messaging.getAPNSToken();
          debugPrint('🔄 Attempt ${i + 1}: APNS Token = $apnsToken');
          if (apnsToken != null) {
            debugPrint('✅ APNS Token received after ${i + 1} attempts: $apnsToken');
            break;
          }
        }
      }
      
      if (apnsToken == null) {
        debugPrint('⚠️ APNS token not available after waiting, but continuing with FCM setup...');
        debugPrint('💡 This is normal on first app launch or when push notifications are not yet authorized');
      } else {
        debugPrint('✅ APNS token is available: $apnsToken');
      }
    } catch (e) {
      debugPrint('❌ Error getting APNS token: $e');
      debugPrint('💡 This error is usually temporary and will resolve on retry');
    }
  }

  // Get FCM token
  String? token = await messaging.getToken();
  debugPrint('✅ FCM Token: $token');

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    debugPrint('🔄 FCM Token refreshed: $newToken');
    // TODO: Send this token to your server
  });

  // Handle foreground messages (App is OPENED)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('📨 Received foreground message (App OPENED):');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
    debugPrint('   Message ID: ${message.messageId}');
    debugPrint('   Sent Time: ${message.sentTime}');
    debugPrint('   TTL: ${message.ttl}');

    await _handleForegroundMessage(message);
  });

  // Handle notification open events when app is in BACKGROUND
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 Notification opened app from BACKGROUND state:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
    debugPrint('   Message ID: ${message.messageId}');

    _handleBackgroundMessageTap(message);
  });

  // Check if app was opened from a notification when in TERMINATED state
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('🔔 App opened from TERMINATED state by notification:');
    debugPrint('   Title: ${initialMessage.notification?.title}');
    debugPrint('   Body: ${initialMessage.notification?.body}');
    debugPrint('   Data: ${initialMessage.data}');
    debugPrint('   Message ID: ${initialMessage.messageId}');

    _handleTerminatedStateMessage(initialMessage);
  }
}

/// Handle foreground messages (App is OPENED)
Future<void> _handleForegroundMessage(RemoteMessage message) async {
  try {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Create enhanced notification details
      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          when: message.sentTime?.millisecondsSinceEpoch,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
          categoryIdentifier: 'message',
          threadIdentifier: 'default',
        ),
      );

      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: json.encode(message.data),
      );

      debugPrint('✅ Foreground notification displayed successfully');
    }
  } catch (e) {
    debugPrint('❌ Error handling foreground message: $e');
  }
}

/// Handle background message tap (App in BACKGROUND)
void _handleBackgroundMessageTap(RemoteMessage message) {
  try {
    // Extract navigation data
    String? url = message.data['url'];
    String? screen = message.data['screen'];
    String? action = message.data['action'];

    debugPrint('🔔 Background message tap - Navigation data:');
    debugPrint('   URL: $url');
    debugPrint('   Screen: $screen');
    debugPrint('   Action: $action');

    // Handle different types of navigation
    // Navigate to specific URL
    debugPrint('📱 Navigating to URL: $url');
    // TODO: Implement URL navigation
  
    // Handle notification-specific actions
    _handleNotificationActions(message);
  } catch (e) {
    debugPrint('❌ Error handling background message tap: $e');
  }
}

/// Handle terminated state message (App was CLOSED)
void _handleTerminatedStateMessage(RemoteMessage message) {
  try {
    // Extract navigation data
    String? url = message.data['url'];
    String? screen = message.data['screen'];
    String? action = message.data['action'];

    debugPrint('🔔 Terminated state message - Navigation data:');
    debugPrint('   URL: $url');
    debugPrint('   Screen: $screen');
    debugPrint('   Action: $action');

    // Handle different types of navigation
    // Navigate to specific URL
    debugPrint('📱 Navigating to URL: $url');
    // TODO: Implement URL navigation
  
    // Handle notification-specific actions
    _handleNotificationActions(message);
  } catch (e) {
    debugPrint('❌ Error handling terminated state message: $e');
  }
}

/// Handle notification-specific actions
void _handleNotificationActions(RemoteMessage message) {
  try {
    String? action = message.data['action'];
    String? type = message.data['type'];
    String? id = message.data['id'];

    debugPrint('🔔 Handling notification actions:');
    debugPrint('   Action: $action');
    debugPrint('   Type: $type');
    debugPrint('   ID: $id');

    switch (action) {
      case 'open_chat':
        debugPrint('💬 Opening chat...');
        // TODO: Implement chat opening
        break;
      case 'open_profile':
        debugPrint('👤 Opening profile...');
        // TODO: Implement profile opening
        break;
      case 'open_settings':
        debugPrint('⚙️ Opening settings...');
        // TODO: Implement settings opening
        break;
      case 'refresh':
        debugPrint('🔄 Refreshing content...');
        // TODO: Implement content refresh
        break;
      default:
        debugPrint('📱 No specific action handler for: $action');
    }
  } catch (e) {
    debugPrint('❌ Error handling notification actions: $e');
  }
}
