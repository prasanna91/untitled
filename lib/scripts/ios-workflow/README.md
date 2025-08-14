# 🚀 iOS Workflow - Enhanced Version

## Overview

This directory contains the upgraded iOS workflow scripts for Codemagic CI/CD, designed to provide a robust, feature-rich, and maintainable iOS build process. The workflow is structured into three distinct phases for better organization and error handling.

## 📁 Script Structure

```
lib/scripts/ios-workflow/
├── ios-workflow-main.sh    # Main orchestrator script
├── pre-build.sh            # Pre-build setup and configuration
├── build.sh                # Core build process
├── post-build.sh           # Post-build validation and distribution
└── README.md               # This documentation
```

## 🔧 Script Descriptions

### 1. `ios-workflow-main.sh` - Main Orchestrator
- **Purpose**: Coordinates the entire iOS workflow execution
- **Features**:
  - Script validation and execution
  - Phase-by-phase execution with error handling
  - Comprehensive workflow reporting
  - Error notification system
  - Workflow cleanup

### 2. `pre-build.sh` - Pre-Build Setup
- **Purpose**: Prepares the environment before building
- **Features**:
  - Build environment validation
  - Xcode and iOS SDK compatibility checks
  - Flutter dependencies installation
  - iOS signing setup (certificates, provisioning profiles)
  - Firebase and APNS configuration
  - iOS project configuration updates
  - Feature integration setup

### 3. `build.sh` - Core Build Process
- **Purpose**: Executes the actual iOS build
- **Features**:
  - Build configuration validation
  - iOS build environment setup
  - Comprehensive cleanup and optimization
  - CocoaPods dependency management
  - Flutter iOS build with retry logic
  - Xcode archive creation
  - IPA export with enhanced configuration
  - Build artifact validation

### 4. `post-build.sh` - Post-Build Processing
- **Purpose**: Handles post-build tasks and distribution
- **Features**:
  - IPA file validation and integrity checks
  - App Store compliance validation
  - TestFlight upload to App Store Connect
  - Comprehensive build reporting
  - Build notification system
  - Post-build cleanup

## 🚀 Key Features

### Enhanced Error Handling
- Comprehensive error trapping and reporting
- Phase-specific error handling
- Retry logic for critical operations
- Detailed error reports with troubleshooting steps

### Target-Only Mode Support
- Optimized for iOS app builds without framework bundle conflicts
- Configurable collision fix and framework bundle update settings
- Enhanced bundle identifier management

### Advanced Build Optimization
- Xcode build optimization flags
- CocoaPods parallel installation
- Flutter build acceleration
- Memory and cache optimization

### Comprehensive Validation
- IPA file integrity validation
- App Store compliance checking
- Bundle identifier verification
- Code signing validation

### Distribution Integration
- TestFlight upload automation
- App Store Connect API integration
- Enhanced ExportOptions.plist generation
- Provisioning profile management

## 📋 Environment Variables

### Required Variables
```bash
BUNDLE_ID="com.example.app"           # iOS bundle identifier
APP_NAME="MyApp"                      # App display name
VERSION_NAME="1.0.0"                  # App version
VERSION_CODE="1"                      # Build number
APPLE_TEAM_ID="ABC123DEF4"            # Apple Developer Team ID
```

### Optional Variables
```bash
BUILD_TYPE="release"                  # Build type (debug/release)
PROFILE_TYPE="app-store"              # Distribution profile type
TARGET_ONLY_MODE="true"               # Enable target-only mode
MAX_RETRIES="2"                       # Maximum build retry attempts
IS_TESTFLIGHT="true"                  # Enable TestFlight upload
SEND_BUILD_NOTIFICATIONS="true"       # Enable build notifications
```

### Code Signing Variables
```bash
CERT_P12_URL="https://..."            # Certificate download URL
CERT_PASSWORD="password"              # Certificate password
PROFILE_URL="https://..."             # Provisioning profile URL
PROVISIONING_PROFILE_NAME="Profile"   # Profile name
SIGNING_CERTIFICATE="iPhone Developer" # Certificate type
```

### Configuration Variables
```bash
FIREBASE_CONFIG_IOS="https://..."     # Firebase iOS config URL
APNS_AUTH_KEY_URL="https://..."       # APNS key download URL
APNS_KEY_ID="ABC123DEF4"              # APNS key identifier
APP_STORE_CONNECT_API_KEY_URL="https://..." # API key URL
APP_STORE_CONNECT_KEY_IDENTIFIER="ABC123DEF4" # API key ID
APP_STORE_CONNECT_ISSUER_ID="12345678-1234-1234-1234-123456789012" # Issuer ID
```

## 🚀 Usage

### Basic Usage
```bash
# Execute the complete workflow
bash lib/scripts/ios-workflow/ios-workflow-main.sh

# Execute individual phases
bash lib/scripts/ios-workflow/pre-build.sh
bash lib/scripts/ios-workflow/build.sh
bash lib/scripts/ios-workflow/post-build.sh
```

### Codemagic Integration
```yaml
# codemagic.yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    environment:
      vars:
        BUNDLE_ID: "com.example.app"
        APP_NAME: "MyApp"
        VERSION_NAME: "1.0.0"
        VERSION_CODE: "1"
        APPLE_TEAM_ID: "ABC123DEF4"
        TARGET_ONLY_MODE: "true"
        IS_TESTFLIGHT: "true"
      xcode: latest
      cocoapods: default
      flutter: stable
    scripts:
      - name: Execute iOS Workflow
        script: |
          bash lib/scripts/ios-workflow/ios-workflow-main.sh
    artifacts:
      - output/ios/*.ipa
      - output/ios/*.txt
```

## 🔍 Troubleshooting

### Common Issues

#### Build Failures
1. **Check environment variables**: Ensure all required variables are set
2. **Verify certificates**: Check certificate and provisioning profile URLs
3. **Review logs**: Check build logs for specific error messages
4. **Validate iOS project**: Ensure iOS project configuration is correct

#### IPA Export Issues
1. **Check signing configuration**: Verify certificates and profiles
2. **Validate ExportOptions.plist**: Ensure proper configuration
3. **Check bundle identifiers**: Verify bundle ID consistency
4. **Review provisioning profiles**: Ensure profile matches bundle ID

#### TestFlight Upload Issues
1. **Verify API credentials**: Check App Store Connect API key configuration
2. **Validate IPA**: Ensure IPA passes App Store validation
3. **Check network**: Verify upload connectivity
4. **Review permissions**: Ensure proper App Store Connect permissions

### Debug Mode
Enable debug mode by setting:
```bash
export FLUTTER_VERBOSE=true
export XCODE_VERBOSE=true
export COCOAPODS_VERBOSE=true
```

## 📊 Output Files

### Build Artifacts
- `output/ios/*.ipa` - Compiled iOS application packages
- `output/ios/BUILD_SUMMARY.txt` - Build process summary
- `output/ios/BUILD_REPORT.txt` - Detailed build report
- `output/ios/WORKFLOW_SUMMARY.txt` - Complete workflow summary

### Error Reports
- `output/ios/WORKFLOW_ERROR.txt` - Error details and troubleshooting
- Build logs with comprehensive error information

## 🔄 Updates and Maintenance

### Script Updates
- Scripts are designed to be idempotent and safe to run multiple times
- All changes are logged for audit purposes
- Error handling prevents partial state corruption

### Version Compatibility
- Compatible with Flutter 3.x+
- Supports Xcode 14+
- Works with iOS 12.0+ deployment target
- Compatible with Codemagic CI/CD platform

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review build logs for specific error messages
3. Verify environment variable configuration
4. Check iOS project settings and certificates

## 📝 Changelog

### Version 2.0 (Current)
- **Major**: Restructured into three-phase workflow
- **Major**: Enhanced error handling and reporting
- **Major**: Improved build optimization and retry logic
- **Major**: Comprehensive validation and compliance checking
- **Major**: Enhanced TestFlight and App Store Connect integration

### Version 1.0 (Previous)
- Basic iOS build workflow
- Simple error handling
- Basic code signing support

---

**Note**: This workflow follows Codemagic best practices and integrates with the existing project structure. All scripts are designed to be safe, maintainable, and provide comprehensive logging for debugging and monitoring purposes.
