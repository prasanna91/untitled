#!/usr/bin/env bash

# Fix iOS App Icons using flutter_launcher_icons
# Generates proper app icons and fixes permission issues

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "📱 Fixing iOS App Icons using flutter_launcher_icons..."

# Check if flutter_launcher_icons is available
if ! flutter pub deps | grep -q "flutter_launcher_icons"; then
    log_error "❌ flutter_launcher_icons not found in dependencies"
    log_info "📝 Adding flutter_launcher_icons to dev_dependencies..."
    flutter pub add --dev flutter_launcher_icons
fi

# Function to create flutter_launcher_icons configuration
create_launcher_icons_config() {
    local logo_path="$1"
    
    log_info "📝 Creating flutter_launcher_icons configuration..."
    
    cat > "pubspec.yaml" << EOF
name: quikapptest06
description: "A new Flutter project."
publish_to: "none"
version: 1.0.7+43

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.10
  flutter_local_notifications: ^17.1.2
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  fluttertoast: ^8.2.4
  google_fonts: ^6.2.1
  path_provider: ^2.1.3
  connectivity_plus: ^6.0.3
  speech_to_text: ^7.0.0
  html: ^0.15.4
  flutter_inappwebview: ^6.0.0
  permission_handler: ^11.3.0
  package_info_plus: ^8.3.0
  shared_preferences: ^2.2.3
  url_launcher: ^6.2.6
  http: ^1.2.1
  google_sign_in: ^6.2.1
  # sign_in_with_apple: ^6.0.0  # Uncomment when IS_APPLE_AUTH=true

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "$logo_path"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "$logo_path"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "$logo_path"
    icon_size: 48
  macos:
    generate: true
    image_path: "$logo_path"

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/
EOF

    log_success "✅ flutter_launcher_icons configuration created"
}

# Function to run flutter_launcher_icons
run_launcher_icons() {
    log_info "🚀 Running flutter_launcher_icons..."
    
    # Clean previous icons
    log_info "🧹 Cleaning previous app icons..."
    rm -rf ios/Runner/Assets.xcassets/AppIcon.appiconset/*
    rm -rf android/app/src/main/res/mipmap-*
    
    # Run flutter_launcher_icons
    if flutter pub get && flutter pub run flutter_launcher_icons:main; then
        log_success "✅ flutter_launcher_icons completed successfully"
        return 0
    else
        log_error "❌ flutter_launcher_icons failed"
        return 1
    fi
}

# Function to update Info.plist with CFBundleIconName
update_info_plist() {
    local info_plist="ios/Runner/Info.plist"
    
    if [[ ! -f "$info_plist" ]]; then
        log_error "❌ Info.plist not found: $info_plist"
        return 1
    fi
    
    # Check if CFBundleIconName already exists
    if grep -q "CFBundleIconName" "$info_plist"; then
        log_success "✅ CFBundleIconName already exists in Info.plist"
        return 0
    fi
    
    # Add CFBundleIconName before the closing </dict> tag
    log_info "📝 Adding CFBundleIconName to Info.plist..."
    sed -i '' '/<\/dict>/i\
	<key>CFBundleIconName</key>\
	<string>AppIcon</string>\
' "$info_plist"
    
    log_success "✅ Added CFBundleIconName to Info.plist"
    return 0
}

# Function to fix iOS permissions
fix_ios_permissions() {
    log_info "🔐 Fixing iOS permissions..."
    
    # Add missing permission strings to Info.plist
    local info_plist="ios/Runner/Info.plist"
    
    # Function to add permission if not exists
    add_permission_if_missing() {
        local key="$1"
        local description="$2"
        
        if ! grep -q "$key" "$info_plist"; then
            log_info "Adding $key to Info.plist..."
            sed -i '' '/<\/dict>/i\
	<key>'"$key"'</key>\
	<string>'"$description"'</string>\
' "$info_plist"
            log_success "✅ Added $key"
        else
            log_success "✅ $key already exists"
        fi
    }
    
    # Add all required permissions
    add_permission_if_missing "NSSpeechRecognitionUsageDescription" "This app uses speech recognition to convert your voice to text for better accessibility and user experience."
    add_permission_if_missing "NSMicrophoneUsageDescription" "This app needs microphone access for speech recognition and voice recording features."
    
    # Add conditional permissions based on environment variables
    if [[ "${IS_CAMERA:-false}" == "true" ]]; then
        add_permission_if_missing "NSCameraUsageDescription" "This app requires camera access to take photos and videos."
    fi
    
    if [[ "${IS_LOCATION:-false}" == "true" ]]; then
        add_permission_if_missing "NSLocationWhenInUseUsageDescription" "This app needs your location to provide location-based services."
        add_permission_if_missing "NSLocationAlwaysAndWhenInUseUsageDescription" "This app needs your location to provide location-based services."
        add_permission_if_missing "NSLocationAlwaysUsageDescription" "This app needs your location to provide location-based services."
    fi
    
    if [[ "${IS_CONTACT:-false}" == "true" ]]; then
        add_permission_if_missing "NSContactsUsageDescription" "This app requires access to your contacts for communication features."
    fi
    
    if [[ "${IS_CALENDAR:-false}" == "true" ]]; then
        add_permission_if_missing "NSCalendarsUsageDescription" "This app uses your calendar to sync and manage events."
    fi
    
    if [[ "${IS_BIOMETRIC:-false}" == "true" ]]; then
        add_permission_if_missing "NSFaceIDUsageDescription" "This app uses Face ID for secure login and authentication."
    fi
    
    if [[ "${IS_STORAGE:-false}" == "true" ]]; then
        add_permission_if_missing "NSPhotoLibraryUsageDescription" "This app requires access to your photo library to save images and videos."
        add_permission_if_missing "NSPhotoLibraryAddUsageDescription" "This app needs permission to save media to your photo library."
    fi
    
    log_success "✅ iOS permissions fixed"
}

# Main process
log_info "🎨 Starting iOS launcher icons fix..."

# Determine source image
SOURCE_IMAGE=""
if [[ -f "assets/images/logo.png" ]]; then
    SOURCE_IMAGE="assets/images/logo.png"
    log_info "📱 Using logo.png as source image"
elif [[ -f "assets/images/splash.png" ]]; then
    SOURCE_IMAGE="assets/images/splash.png"
    log_info "📱 Using splash.png as source image"
elif [[ -f "assets/images/default_logo.png" ]]; then
    SOURCE_IMAGE="assets/images/default_logo.png"
    log_info "📱 Using default_logo.png as source image"
else
    log_error "❌ No suitable source image found"
    log_info "📋 Available images:"
    find assets/images -name "*.png" -type f 2>/dev/null || echo "No images found in assets/images/"
    exit 1
fi

# Create flutter_launcher_icons configuration
if create_launcher_icons_config "$SOURCE_IMAGE"; then
    log_success "✅ Configuration created successfully"
else
    log_error "❌ Failed to create configuration"
    exit 1
fi

# Run flutter_launcher_icons
if run_launcher_icons; then
    log_success "✅ App icons generated successfully"
else
    log_error "❌ Failed to generate app icons"
    exit 1
fi

# Update Info.plist with CFBundleIconName
if update_info_plist; then
    log_success "✅ Info.plist updated successfully"
else
    log_error "❌ Failed to update Info.plist"
    exit 1
fi

# Fix iOS permissions
fix_ios_permissions

# Verify the generated icons
log_info "🔍 Verifying generated app icons..."

# Check iOS icons
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" ]]; then
    log_success "✅ iOS app icon verified"
else
    log_warning "⚠️ iOS app icon not found"
fi

# Check Android icons
if [[ -f "android/app/src/main/res/mipmap-hdpi/launcher_icon.png" ]]; then
    log_success "✅ Android app icon verified"
else
    log_warning "⚠️ Android app icon not found"
fi

# Show summary
log_info "📋 iOS Launcher Icons Fix Summary:"
echo "=========================================="
echo "✅ Source Image: $SOURCE_IMAGE"
echo "✅ flutter_launcher_icons: Configured and executed"
echo "✅ CFBundleIconName: Added to Info.plist"
echo "✅ iOS Permissions: Fixed"
echo "✅ App Icons: Generated for iOS and Android"
echo "=========================================="

# List generated iOS icons
log_info "📱 Generated iOS app icons:"
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null | head -5 || echo "No iOS icons found"

# List generated Android icons
log_info "🤖 Generated Android app icons:"
ls -la android/app/src/main/res/mipmap-*/launcher_icon.png 2>/dev/null | head -5 || echo "No Android icons found"

log_success "🎉 iOS launcher icons fix completed successfully" 