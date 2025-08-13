import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

// Conditional import for Apple Sign-In
// This will be uncommented when IS_APPLE_AUTH=true
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Handle Google Sign-In
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    // Check if Google Auth is enabled
    if (!EnvConfig.isGoogleAuth) {
      debugPrint("❌ Google Sign-In is disabled in configuration");
      return null;
    }

    try {
      debugPrint("🔐 Starting Google Sign-In...");

      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("❌ User cancelled Google Sign-In");
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("✅ Google Sign-In successful for: ${googleUser.email}");

      return {
        'provider': 'google',
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
      };
    } catch (error) {
      debugPrint("❌ Google Sign-In error: $error");
      return null;
    }
  }

  /// Handle Apple Sign-In
  static Future<Map<String, dynamic>?> signInWithApple() async {
    // Check if Apple Auth is enabled
    if (!EnvConfig.isAppleAuth) {
      debugPrint("❌ Apple Sign-In is disabled in configuration");
      return null;
    }

    // Check if sign_in_with_apple package is available
    try {
      // This will only work if the package is uncommented in pubspec.yaml
      // import 'package:sign_in_with_apple/sign_in_with_apple.dart';

      debugPrint("🍎 Starting Apple Sign-In...");

      // Placeholder for Apple Sign-In implementation
      // Uncomment the following when sign_in_with_apple is enabled:
      /*
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint("✅ Apple Sign-In successful for: ${credential.email}");

      return {
        'provider': 'apple',
        'id': credential.userIdentifier,
        'email': credential.email,
        'displayName':
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim(),
        'accessToken': credential.authorizationCode,
        'identityToken': credential.identityToken,
      };
      */

      debugPrint("⚠️ Apple Sign-In package not available");
      return null;
    } catch (error) {
      debugPrint("❌ Apple Sign-In error: $error");
      return null;
    }
  }

  /// Send OAuth data to server
  static Future<bool> sendOAuthToServer(Map<String, dynamic> oauthData) async {
    try {
      debugPrint("📤 Sending OAuth data to server...");

      final response = await http.post(
        Uri.parse('${EnvConfig.webUrl}api/oauth/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(oauthData),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ OAuth data sent successfully");
        return true;
      } else {
        debugPrint("❌ Server error: ${response.statusCode}");
        return false;
      }
    } catch (error) {
      debugPrint("❌ Error sending OAuth data: $error");
      return false;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint("✅ Signed out successfully");
    } catch (error) {
      debugPrint("❌ Sign out error: $error");
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      return currentUser != null;
    } catch (error) {
      debugPrint("❌ Error checking sign-in status: $error");
      return false;
    }
  }
}
