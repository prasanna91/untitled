import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../config/env_config.dart';
import '../module/myapp.dart';
import '../module/offline_screen.dart';
import '../services/notification_service.dart';
import '../services/connectivity_service.dart';
import '../utils/menu_parser.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("🔔 Handling a background message: ${message.messageId}");
    print("📝 Message data: ${message.data}");
    print("📌 Notification: ${message.notification?.title}");
  }
}

/// Initialize Firebase messaging with retry logic for APNS token issues
Future<void> _initializeFirebaseMessagingWithRetry() async {
  try {
    await initializeFirebaseMessaging();
  } catch (e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('apns-token-not-set') ||
        errorStr.contains('apns token has not been set')) {
      debugPrint("🔄 APNS token not ready, waiting and retrying...");
      debugPrint(
          "💡 This is normal on iOS - APNS token takes a few seconds to become available");

      // Wait for APNS token to be available
      await Future.delayed(const Duration(seconds: 3));

      try {
        await initializeFirebaseMessaging();
        debugPrint("✅ Firebase messaging initialized successfully on retry");
      } catch (retryError) {
        debugPrint("❌ Firebase messaging still failed on retry: $retryError");
        // If it's still an APNS issue, we'll continue without Firebase
        if (retryError
                .toString()
                .toLowerCase()
                .contains('apns-token-not-set') ||
            retryError
                .toString()
                .toLowerCase()
                .contains('apns token has not been set')) {
          debugPrint(
              "⚠️ APNS token still not available, continuing without Firebase messaging");
          // Don't rethrow - let the app continue without Firebase
          return;
        }
        rethrow;
      }
    } else {
      rethrow;
    }
  }
}

class FirebaseErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const FirebaseErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  String get platformSpecificHelp {
    if (Platform.isIOS) {
      return """
Please check:
1. GoogleService-Info.plist is properly configured
2. Push notification capability is enabled
3. Valid provisioning profile with push enabled
4. Bundle ID matches Firebase configuration
5. APNS token is available (may take a few seconds on first launch)
6. Network connectivity for Firebase services""";
    } else {
      return """
Please check:
1. google-services.json is properly configured
2. Package name matches Firebase configuration
3. SHA-1 fingerprint is added to Firebase console
4. Firebase SDK is properly initialized""";
    }
  }

  String get platformName => Platform.isIOS ? "iOS" : "Android";

  String get platformSpecificError {
    final errorLower = error.toLowerCase();
    if (Platform.isIOS) {
      if (errorLower.contains('apns-token-not-set') ||
          errorLower.contains('apns token has not been set')) {
        return 'APNS token is not available yet. This usually resolves automatically within a few seconds. Please try again.';
      } else if (errorLower.contains('googleservice-info.plist')) {
        return 'GoogleService-Info.plist is missing or invalid. Please check your Firebase iOS app configuration.';
      } else if (errorLower.contains('bundle identifier')) {
        return 'Bundle identifier mismatch. Please ensure it matches your Firebase iOS app configuration.';
      } else if (errorLower.contains('provision')) {
        return 'Provisioning profile issue. Please ensure push notifications are enabled in your profile.';
      }
    } else {
      if (errorLower.contains('google-services.json')) {
        return 'google-services.json is missing or invalid. Please check your Firebase Android app configuration.';
      } else if (errorLower.contains('package name')) {
        return 'Package name mismatch. Please ensure it matches your Firebase Android app configuration.';
      } else if (errorLower.contains('sha-1') || errorLower.contains('sha1')) {
        return 'SHA-1 fingerprint missing. Please add it to your Firebase Android app configuration.';
      }
    }
    return error;
  }

  Widget _buildHelpButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$platformName Firebase Setup Help'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(platformSpecificHelp),
                  const SizedBox(height: 16),
                  const Text('Documentation Links:'),
                  const SizedBox(height: 8),
                  if (Platform.isIOS) ...[
                    _buildLink(
                      'iOS Firebase Setup Guide',
                      'https://firebase.google.com/docs/ios/setup',
                    ),
                    _buildLink(
                      'iOS Push Notification Setup',
                      'https://firebase.google.com/docs/cloud-messaging/ios/client',
                    ),
                  ] else ...[
                    _buildLink(
                      'Android Firebase Setup Guide',
                      'https://firebase.google.com/docs/android/setup',
                    ),
                    _buildLink(
                      'Android Push Notification Setup',
                      'https://firebase.google.com/docs/cloud-messaging/android/client',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.help_outline),
      label: const Text('Setup Help'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLink(String title, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          // You might want to add url_launcher package to handle URL opening
          debugPrint('Opening URL: $url');
        },
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF667eea),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF667eea),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          primary: const Color(0xFF667eea),
          secondary: const Color(0xFF4fd1c5),
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$platformName Firebase Initialization Failed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      platformSpecificError,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHelpButton(context),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('$platformName Firebase Setup Help'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(platformSpecificHelp),
                                  const SizedBox(height: 16),
                                  const Text('Documentation Links:'),
                                  const SizedBox(height: 8),
                                  if (Platform.isIOS) ...[
                                    _buildLink(
                                      'iOS Firebase Setup Guide',
                                      'https://firebase.google.com/docs/ios/setup',
                                    ),
                                    _buildLink(
                                      'iOS Push Notification Setup',
                                      'https://firebase.google.com/docs/cloud-messaging/ios/client',
                                    ),
                                  ] else ...[
                                    _buildLink(
                                      'Android Firebase Setup Guide',
                                      'https://firebase.google.com/docs/android/setup',
                                    ),
                                    _buildLink(
                                      'Android Push Notification Setup',
                                      'https://firebase.google.com/docs/cloud-messaging/android/client',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text(
                        'Setup Help',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        runApp(MyApp(
                          webUrl: EnvConfig.webUrl,
                          isSplash: EnvConfig.isSplash,
                          splashLogo: EnvConfig.splashUrl,
                          splashBg: EnvConfig.splashBg,
                          splashDuration: EnvConfig.splashDuration,
                          splashAnimation: EnvConfig.splashAnimation,
                          taglineColor: EnvConfig.splashTaglineColor,
                          spbgColor: EnvConfig.splashBgColor,
                          isBottomMenu: EnvConfig.isBottommenu,
                          bottomMenuItems: EnvConfig.bottommenuItems,
                          isDomainUrl: EnvConfig.isDomainUrl,
                          backgroundColor: EnvConfig.bottommenuBgColor,
                          activeTabColor: EnvConfig.bottommenuActiveTabColor,
                          textColor: EnvConfig.bottommenuTextColor,
                          iconColor: EnvConfig.bottommenuIconColor,
                          iconPosition: EnvConfig.bottommenuIconPosition,
                          isLoadIndicator: EnvConfig.isLoadIndicator,
                          splashTagline: EnvConfig.splashTagline,
                          taglineFont: EnvConfig.splashTaglineFont,
                          taglineSize:
                              double.tryParse(EnvConfig.splashTaglineSize) ??
                                  20.0,
                          taglineBold: EnvConfig.splashTaglineBold,
                          taglineItalic: EnvConfig.splashTaglineItalic,
                          initializeFirebaseAfterSplash:
                              false, // FIXED: Add missing parameter
                        ));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: const Text(
                        'Continue Without Firebase',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock orientation to portrait only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Initialize connectivity service
    await ConnectivityService().initialize();

    // Initialize local notifications first
    await initLocalNotifications();

    // CRITICAL FIX: Show splash screen FIRST, then initialize Firebase
    // This prevents crashes and shows brand logo immediately
    if (EnvConfig.isSplash) {
      debugPrint(
          "🔄 Showing splash screen first, Firebase will initialize after...");

      // Run app with splash screen immediately
      runApp(MyApp(
        webUrl: EnvConfig.webUrl,
        isSplash: EnvConfig.isSplash,
        splashLogo: EnvConfig.splashUrl,
        splashBg: EnvConfig.splashBg,
        splashDuration: EnvConfig.splashDuration,
        splashAnimation: EnvConfig.splashAnimation,
        taglineColor: EnvConfig.splashTaglineColor,
        spbgColor: EnvConfig.splashBgColor,
        isBottomMenu: EnvConfig.isBottommenu,
        bottomMenuItems: EnvConfig.bottommenuItems,
        isDomainUrl: EnvConfig.isDomainUrl,
        backgroundColor: EnvConfig.bottommenuBgColor,
        activeTabColor: EnvConfig.bottommenuActiveTabColor,
        textColor: EnvConfig.bottommenuTextColor,
        iconColor: EnvConfig.bottommenuIconColor,
        iconPosition: EnvConfig.bottommenuIconPosition,
        isLoadIndicator: EnvConfig.isLoadIndicator,
        splashTagline: EnvConfig.splashTagline,
        taglineFont: EnvConfig.splashTaglineFont,
        taglineSize: double.tryParse(EnvConfig.splashTaglineSize) ?? 20.0,
        taglineBold: EnvConfig.splashTaglineBold,
        taglineItalic: EnvConfig.splashTaglineItalic,
        initializeFirebaseAfterSplash:
            true, // NEW: Flag to initialize Firebase after splash
      ));

      // Initialize Firebase in background after splash
      _initializeFirebaseInBackground();
      return;
    }

    // If no splash screen, initialize Firebase immediately
    if (EnvConfig.pushNotify) {
      try {
        // Use the Firebase service that handles remote config files
        final options = await loadFirebaseOptionsFromJson();
        await Firebase.initializeApp(options: options);
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // Initialize Firebase messaging with retry logic
        await _initializeFirebaseMessagingWithRetry();

        debugPrint("✅ Firebase initialized successfully");
      } catch (e) {
        debugPrint("❌ Firebase initialization error: $e");

        // Check if it's an APNS token issue
        if (e.toString().contains('apns-token-not-set') ||
            e.toString().contains('APNS token has not been set')) {
          debugPrint("🔄 APNS token issue detected, retrying with delay...");

          // Wait a bit and retry once
          await Future.delayed(const Duration(seconds: 2));
          try {
            await _initializeFirebaseMessagingWithRetry();
            debugPrint("✅ Firebase initialized successfully on retry");
          } catch (retryError) {
            debugPrint(
                "❌ Firebase initialization failed on retry: $retryError");
            // For APNS token issues, continue without Firebase instead of showing error
            if (retryError
                    .toString()
                    .toLowerCase()
                    .contains('apns-token-not-set') ||
                retryError
                    .toString()
                    .toLowerCase()
                    .contains('apns token has not been set')) {
              debugPrint(
                  "⚠️ Continuing without Firebase due to APNS token issues");
              // Continue with app initialization
            } else {
              // Show Firebase error UI for other errors
              runApp(FirebaseErrorWidget(
                error: retryError.toString(),
                onRetry: () => initializeApp(),
              ));
              return;
            }
          }
        } else {
          // Show Firebase error UI for other errors
          runApp(FirebaseErrorWidget(
            error: e.toString(),
            onRetry: () => initializeApp(),
          ));
          return;
        }
      }
    } else {
      debugPrint(
          "🚫 Firebase not initialized (pushNotify: ${EnvConfig.pushNotify}, isWeb: $kIsWeb)");
    }

    if (EnvConfig.webUrl.isEmpty) {
      debugPrint("❗ Missing WEB_URL environment variable.");
      runApp(const MaterialApp(
        home: Scaffold(
          body: Center(child: Text("WEB_URL not configured.")),
        ),
      ));
      return;
    }

    debugPrint("""
      🛠 Runtime Config:
      - pushNotify: ${EnvConfig.pushNotify}
      - webUrl: ${EnvConfig.webUrl}
      - isSplash: ${EnvConfig.isSplash},
      - splashLogo: ${EnvConfig.splashUrl},
      - splashBg: ${EnvConfig.splashBg},
      - splashDuration: ${EnvConfig.splashDuration},
      - splashAnimation: ${EnvConfig.splashAnimation},
      - taglineColor: ${EnvConfig.splashTaglineColor},
      - spbgColor: ${EnvConfig.splashBgColor},
      - isBottomMenu: ${EnvConfig.isBottommenu},
      - bottomMenuItems: ${parseBottomMenuItems(EnvConfig.bottommenuItems)},
      - isDomainUrl: ${EnvConfig.isDomainUrl},
      - backgroundColor: ${EnvConfig.bottommenuBgColor},
      - activeTabColor: ${EnvConfig.bottommenuActiveTabColor},
      - textColor: ${EnvConfig.bottommenuTextColor},
      - iconColor: ${EnvConfig.bottommenuIconColor},
      - iconPosition: ${EnvConfig.bottommenuIconPosition},
      - Permissions:
        - Camera: ${EnvConfig.isCamera}
        - Location: ${EnvConfig.isLocation}
        - Mic: ${EnvConfig.isMic}
        - Notification: ${EnvConfig.isNotification}
        - Contact: ${EnvConfig.isContact}
      """);

    runApp(MyApp(
      webUrl: EnvConfig.webUrl,
      isSplash: EnvConfig.isSplash,
      splashLogo: EnvConfig.splashUrl,
      splashBg: EnvConfig.splashBg,
      splashDuration: EnvConfig.splashDuration,
      splashAnimation: EnvConfig.splashAnimation,
      taglineColor: EnvConfig.splashTaglineColor,
      spbgColor: EnvConfig.splashBgColor,
      isBottomMenu: EnvConfig.isBottommenu,
      bottomMenuItems: EnvConfig.bottommenuItems,
      isDomainUrl: EnvConfig.isDomainUrl,
      backgroundColor: EnvConfig.bottommenuBgColor,
      activeTabColor: EnvConfig.bottommenuActiveTabColor,
      textColor: EnvConfig.bottommenuTextColor,
      iconColor: EnvConfig.bottommenuIconColor,
      iconPosition: EnvConfig.bottommenuIconPosition,
      isLoadIndicator: EnvConfig.isLoadIndicator,
      splashTagline: EnvConfig.splashTagline,
      taglineFont: EnvConfig.splashTaglineFont,
      taglineSize: double.tryParse(EnvConfig.splashTaglineSize) ?? 20.0,
      taglineBold: EnvConfig.splashTaglineBold,
      taglineItalic: EnvConfig.splashTaglineItalic,
      initializeFirebaseAfterSplash:
          false, // NEW: No splash, Firebase already initialized
    ));
  } catch (e, stackTrace) {
    debugPrint("❌ Fatal error during initialization: $e");
    debugPrint("Stack trace: $stackTrace");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Error: $e")),
      ),
    ));
  }
}

// NEW: Initialize Firebase in background after splash screen
Future<void> _initializeFirebaseInBackground() async {
  try {
    debugPrint("🔄 Initializing Firebase in background after splash...");

    if (EnvConfig.pushNotify) {
      // Use the Firebase service that handles remote config files
      final options = await loadFirebaseOptionsFromJson();
      await Firebase.initializeApp(options: options);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Initialize Firebase messaging with retry logic
      await _initializeFirebaseMessagingWithRetry();

      debugPrint("✅ Firebase initialized successfully in background");
    } else {
      debugPrint(
          "🚫 Firebase not enabled (pushNotify: ${EnvConfig.pushNotify})");
    }
  } catch (e) {
    debugPrint("❌ Firebase initialization in background failed: $e");
    // Don't crash the app, just log the error
    // Firebase will be retried when MainHome initializes
  }
}

void main() {
  initializeApp();
}
