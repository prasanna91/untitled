import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/env_config.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_service.dart';
import 'main_home.dart' show MainHome;
import 'splash_screen.dart';
import 'offline_screen.dart';

class MyApp extends StatefulWidget {
  final String webUrl;
  final bool isBottomMenu;
  final bool isSplash;
  final String splashLogo;
  final String splashBg;
  final int splashDuration;
  final String splashTagline;
  final String splashAnimation;
  final bool isDomainUrl;
  final String backgroundColor;
  final String activeTabColor;
  final String textColor;
  final String iconColor;
  final String iconPosition;
  final String taglineColor;
  final String spbgColor;
  final bool isLoadIndicator;
  final String bottomMenuItems;
  final String taglineFont;
  final double taglineSize;
  final bool taglineBold;
  final bool taglineItalic;
  final bool
      initializeFirebaseAfterSplash; // NEW: Flag to initialize Firebase after splash

  const MyApp(
      {super.key,
      required this.webUrl,
      required this.isBottomMenu,
      required this.isSplash,
      required this.splashLogo,
      required this.splashBg,
      required this.splashDuration,
      required this.splashAnimation,
      required this.bottomMenuItems,
      required this.isDomainUrl,
      required this.backgroundColor,
      required this.activeTabColor,
      required this.textColor,
      required this.iconColor,
      required this.iconPosition,
      required this.taglineColor,
      required this.spbgColor,
      required this.isLoadIndicator,
      required this.splashTagline,
      required this.taglineFont,
      required this.taglineSize,
      required this.taglineBold,
      required this.taglineItalic,
      required this.initializeFirebaseAfterSplash}); // NEW: Add to constructor

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showSplash = false;
  bool isOnline = true;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    setState(() {
      showSplash = widget.isSplash;
      isOnline = _connectivityService.isConnected;
    });

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((connected) {
      if (mounted) {
        setState(() {
          isOnline = connected;
        });
      }
    });

    if (showSplash) {
      Future.delayed(Duration(seconds: widget.splashDuration), () {
        if (mounted) {
          setState(() {
            showSplash = false;
          });

          // NEW: Initialize Firebase after splash screen if needed
          if (widget.initializeFirebaseAfterSplash) {
            _initializeFirebaseAfterSplash();
          }
        }
      });
    } else {
      // NEW: If no splash, initialize Firebase immediately
      if (widget.initializeFirebaseAfterSplash) {
        _initializeFirebaseAfterSplash();
      }
    }
  }

  // NEW: Initialize Firebase after splash screen
  Future<void> _initializeFirebaseAfterSplash() async {
    try {
      debugPrint("🔄 Initializing Firebase after splash screen...");

      // Import Firebase services here to avoid circular dependencies
      await _initializeFirebaseServices();

      debugPrint("✅ Firebase initialized successfully after splash");
    } catch (e) {
      debugPrint("❌ Firebase initialization after splash failed: $e");
      // Don't crash the app, just log the error
    }
  }

  // NEW: Initialize Firebase services
  Future<void> _initializeFirebaseServices() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        // Load Firebase options from service
        final options = await loadFirebaseOptionsFromJson();
        await Firebase.initializeApp(options: options);
      }

      // Initialize Firebase messaging
      if (EnvConfig.pushNotify) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
        await _initializeFirebaseMessagingWithRetry();
      }
    } catch (e) {
      debugPrint("❌ Firebase services initialization failed: $e");
      rethrow;
    }
  }

  // NEW: Firebase messaging initialization with retry
  Future<void> _initializeFirebaseMessagingWithRetry() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.getToken();
      debugPrint("✅ Firebase messaging initialized successfully");
    } catch (e) {
      debugPrint("❌ Firebase messaging initialization failed: $e");
      // Retry once after delay
      await Future.delayed(const Duration(seconds: 2));
      try {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getToken();
        debugPrint("✅ Firebase messaging initialized successfully on retry");
      } catch (retryError) {
        debugPrint(
            "❌ Firebase messaging initialization failed on retry: $retryError");
        // Continue without Firebase messaging
      }
    }
  }

  // NEW: Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      debugPrint("🔔 Handling background message: ${message.messageId}");
    } catch (e) {
      debugPrint("❌ Background message handler error: $e");
    }
  }

  void _handleRetryConnection() {
    // This will trigger a rebuild and show the main app if connection is restored
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: showSplash
          ? SplashScreen(
              splashLogo: widget.splashLogo,
              splashBg: widget.splashBg,
              splashAnimation: widget.splashAnimation,
              spbgColor: widget.spbgColor,
              taglineColor: widget.taglineColor,
              splashTagline: EnvConfig.splashTagline,
              taglineFont: widget.taglineFont,
              taglineSize: widget.taglineSize,
              taglineBold: widget.taglineBold,
              taglineItalic: widget.taglineItalic,
            )
          : !isOnline
              ? OfflineScreen(
                  onRetry: _handleRetryConnection,
                  appName: EnvConfig.appName,
                )
              : MainHome(
                  webUrl: widget.webUrl,
                  isBottomMenu: widget.isBottomMenu,
                  bottomMenuItems: widget.bottomMenuItems,
                  isDomainUrl: widget.isDomainUrl,
                  backgroundColor: widget.backgroundColor,
                  activeTabColor: widget.activeTabColor,
                  textColor: widget.textColor,
                  iconColor: widget.iconColor,
                  iconPosition: widget.iconPosition,
                  taglineColor: widget.taglineColor,
                  isLoadIndicator: widget.isLoadIndicator,
                ),
    );
  }
}
