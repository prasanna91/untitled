# 🚀 QuikApp - Flutter Multi-Platform Application

A modern Flutter application with comprehensive CI/CD pipeline using Codemagic for automated builds and distribution.

## 📱 Features

- **Cross-Platform**: Android and iOS support
- **Dynamic Configuration**: Runtime configuration via Codemagic environment variables
- **Code Signing**: Automated certificate management for both platforms
- **Firebase Integration**: Push notifications and analytics support
- **OAuth Authentication**: Google and Apple Sign-In support
- **Customizable UI**: Dynamic splash screens, branding, and bottom navigation
- **Automated Distribution**: TestFlight and Play Store deployment ready

## 🏗️ Architecture

```
lib/
├── config/          # Environment configuration
├── module/          # Main app modules
├── services/        # Business logic services
├── chat/           # Chat functionality
├── utils/          # Utility functions
└── scripts/        # Build and deployment scripts
    ├── android/    # Android build scripts
    ├── ios-workflow/ # iOS build scripts
    ├── combined/   # Combined build scripts
    └── utils/      # Shared utilities
```

## 🔧 Codemagic CI/CD Workflows

### Available Workflows

1. **android-free** - Free Android build (APK only)
2. **android-paid** - Paid Android build with Firebase
3. **android-publish** - Production Android build (APK + AAB)
4. **ios-workflow** - Complete iOS build and distribution
5. **combined** - Universal build for both platforms

### Workflow Configuration

Each workflow is configured with:
- **Build Optimization**: Gradle, Xcode, and Flutter optimizations
- **Code Signing**: Automated certificate and keystore management
- **Environment Variables**: Dynamic configuration injection
- **Artifact Management**: Automated build artifact collection
- **Error Handling**: Comprehensive error reporting and recovery

## 🚀 Quick Start

### Prerequisites

- Flutter 3.32.2+
- Dart 3.0+
- Xcode 16.0+ (for iOS builds)
- Android SDK (for Android builds)
- Codemagic account

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd untitled

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Codemagic Setup

1. **Connect Repository**: Link your GitHub/GitLab repository to Codemagic
2. **Configure Variables**: Set required environment variables in Codemagic
3. **Select Workflow**: Choose appropriate workflow for your build needs
4. **Trigger Build**: Start build manually or configure automatic triggers

## 📋 Required Environment Variables

### Core Configuration
```yaml
PROJECT_ID: "your-project-id"
APP_NAME: "Your App Name"
VERSION_NAME: "1.0.0"
VERSION_CODE: "1"
WORKFLOW_ID: "workflow-name"
```

### App Information
```yaml
BUNDLE_ID: "com.example.app"
PKG_NAME: "com.example.app"
ORG_NAME: "Your Organization"
WEB_URL: "https://example.com"
EMAIL_ID: "your@email.com"
USER_NAME: "username"
```

### Feature Flags
```yaml
IS_CHATBOT: "true"
IS_SPLASH: "true"
IS_BOTTOMMENU: "true"
IS_GOOGLE_AUTH: "true"
IS_APPLE_AUTH: "true"
PUSH_NOTIFY: "true"
```

### Android Configuration
```yaml
KEY_STORE_URL: "https://example.com/keystore.jks"
CM_KEYSTORE_PASSWORD: "password"
CM_KEY_ALIAS: "alias"
CM_KEY_PASSWORD: "password"
FIREBASE_CONFIG_ANDROID: "https://example.com/google-services.json"
```

### iOS Configuration
```yaml
APPLE_TEAM_ID: "TEAM_ID"
CERT_P12_URL: "https://example.com/certificate.p12"
CERT_PASSWORD: "password"
PROFILE_URL: "https://example.com/profile.mobileprovision"
FIREBASE_CONFIG_IOS: "https://example.com/GoogleService-Info.plist"
APNS_KEY_ID: "KEY_ID"
APNS_AUTH_KEY_URL: "https://example.com/AuthKey.p8"
```

### App Store Connect (for TestFlight)
```yaml
IS_TESTFLIGHT: "true"
APP_STORE_CONNECT_KEY_IDENTIFIER: "KEY_ID"
APP_STORE_CONNECT_ISSUER_ID: "ISSUER_ID"
APP_STORE_CONNECT_API_KEY_URL: "https://example.com/AuthKey.p8"
```

## 🔐 Code Signing

### Android
- **Keystore**: Automatically downloaded from `KEY_STORE_URL`
- **Configuration**: Automatically added to `gradle.properties`
- **Signing**: Release builds automatically signed

### iOS
- **Certificates**: Automatically downloaded and imported to keychain
- **Provisioning Profiles**: Automatically installed
- **Code Signing**: Configured for both development and distribution

## 📱 Build Artifacts

### Android
- `app-release.apk` - Signed APK file
- `app-release.aab` - Android App Bundle
- `mapping.txt` - ProGuard mapping file
- `BUILD_SUMMARY.txt` - Build summary report

### iOS
- `Runner.ipa` - Signed IPA file
- `Runner.xcarchive` - Xcode archive
- `ARTIFACTS_SUMMARY.txt` - Build summary report

## 🛠️ Scripts

### Build Scripts
- **`lib/scripts/android/main.sh`** - Android build orchestration
- **`lib/scripts/ios-workflow/ios-workflow-main.sh`** - iOS build orchestration
- **`lib/scripts/combined/main.sh`** - Combined build orchestration

### Utility Scripts
- **`lib/scripts/utils/logging.sh`** - Consistent logging across scripts
- **`lib/scripts/utils/env_generator.sh`** - Dart environment file generation

## 📊 Build Process

### Android Build Flow
1. Environment setup and optimization
2. Keystore and Firebase configuration
3. App configuration updates
4. Clean previous builds
5. APK/AAB generation
6. Artifact collection and summary

### iOS Build Flow
1. Environment setup and optimization
2. Certificate and profile management
3. Firebase and APNS configuration
4. Project configuration updates
5. CocoaPods dependency installation
6. Flutter iOS build
7. Xcode archive creation
8. IPA export
9. App Store Connect upload (if enabled)

## 🚨 Troubleshooting

### Common Issues

1. **Build Failures**: Check environment variable configuration
2. **Code Signing Errors**: Verify certificate and profile URLs
3. **Firebase Issues**: Ensure configuration files are accessible
4. **Permission Errors**: Check script execution permissions

### Debug Mode

Enable verbose logging by setting:
```yaml
FLUTTER_VERBOSE: "true"
```

### Support

For build issues:
1. Check Codemagic build logs
2. Verify environment variable configuration
3. Review script execution logs
4. Check artifact generation

## 📈 Performance Optimization

### Build Optimizations
- **Gradle**: Parallel builds, caching, daemon optimization
- **Xcode**: Fast builds, parallel compilation, optimization flags
- **Flutter**: Pub cache, minimal verbosity, selective testing
- **CocoaPods**: Fast installation, parallel processing

### Memory Management
- Automatic cleanup of temporary files
- Build artifact validation
- Comprehensive error handling
- Resource optimization

## 🔄 Continuous Integration

### Automatic Triggers
- **Push to main**: Automatic builds
- **Pull requests**: Validation builds
- **Tags**: Release builds
- **Manual**: On-demand builds

### Build Matrix
- Multiple Flutter versions
- Different build configurations
- Platform-specific optimizations
- Automated testing

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Codemagic Documentation](https://docs.codemagic.io/)
- [iOS Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check Codemagic documentation

---

**Built with ❤️ using Flutter and Codemagic**
