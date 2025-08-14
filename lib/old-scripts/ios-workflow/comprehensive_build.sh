#!/bin/bash
# 🚀 Comprehensive iOS Build Script
# Handles complete iOS build process with all requirements

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Source environment configuration
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../lib/config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
else
    log "Environment configuration file not found, using system environment variables"
fi

# Function to safely get environment variable with fallback
get_api_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        printf "%s" "$value"
    else
        printf "%s" "$fallback"
    fi
}

# Set default values for all required variables
export WORKFLOW_ID=$(get_api_var "WORKFLOW_ID" "ios-workflow")
export APP_NAME=$(get_api_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_api_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_api_var "VERSION_CODE" "1")
export EMAIL_ID=$(get_api_var "EMAIL_ID" "admin@example.com")
export BUNDLE_ID=$(get_api_var "BUNDLE_ID" "com.example.quikapp")
export APPLE_TEAM_ID=$(get_api_var "APPLE_TEAM_ID" "")
export PROFILE_TYPE=$(get_api_var "PROFILE_TYPE" "app-store")
export PROFILE_URL=$(get_api_var "PROFILE_URL" "")
export IS_TESTFLIGHT=$(get_api_var "IS_TESTFLIGHT" "false")
export APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_api_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
export APP_STORE_CONNECT_ISSUER_ID=$(get_api_var "APP_STORE_CONNECT_ISSUER_ID" "")
export APP_STORE_CONNECT_API_KEY_URL=$(get_api_var "APP_STORE_CONNECT_API_KEY_URL" "")
export LOGO_URL=$(get_api_var "LOGO_URL" "")
export SPLASH_URL=$(get_api_var "SPLASH_URL" "")
export SPLASH_BG_COLOR=$(get_api_var "SPLASH_BG_COLOR" "#FFFFFF")
export SPLASH_TAGLINE=$(get_api_var "SPLASH_TAGLINE" "")
export SPLASH_TAGLINE_COLOR=$(get_api_var "SPLASH_TAGLINE_COLOR" "#000000")
export FIREBASE_CONFIG_IOS=$(get_api_var "FIREBASE_CONFIG_IOS" "")
export ENABLE_EMAIL_NOTIFICATIONS=$(get_api_var "ENABLE_EMAIL_NOTIFICATIONS" "false")
export EMAIL_SMTP_SERVER=$(get_api_var "EMAIL_SMTP_SERVER" "")
export EMAIL_SMTP_PORT=$(get_api_var "EMAIL_SMTP_PORT" "587")
export EMAIL_SMTP_USER=$(get_api_var "EMAIL_SMTP_USER" "")
export EMAIL_SMTP_PASS=$(get_api_var "EMAIL_SMTP_PASS" "")
export USER_NAME=$(get_api_var "USER_NAME" "Admin")
export APP_ID=$(get_api_var "APP_ID" "quikapp")
export ORG_NAME=$(get_api_var "ORG_NAME" "QuikApp")
export WEB_URL=$(get_api_var "WEB_URL" "https://quikapp.com")
export PKG_NAME=$(get_api_var "PKG_NAME" "com.example.quikapp")
export PUSH_NOTIFY=$(get_api_var "PUSH_NOTIFY" "false")
export IS_CHATBOT=$(get_api_var "IS_CHATBOT" "false")
export IS_DOMAIN_URL=$(get_api_var "IS_DOMAIN_URL" "false")
export IS_SPLASH=$(get_api_var "IS_SPLASH" "true")
export IS_PULLDOWN=$(get_api_var "IS_PULLDOWN" "false")
export IS_BOTTOMMENU=$(get_api_var "IS_BOTTOMMENU" "false")
export IS_LOAD_IND=$(get_api_var "IS_LOAD_IND" "false")
export IS_CAMERA=$(get_api_var "IS_CAMERA" "false")
export IS_LOCATION=$(get_api_var "IS_LOCATION" "false")
export IS_MIC=$(get_api_var "IS_MIC" "false")
export IS_NOTIFICATION=$(get_api_var "IS_NOTIFICATION" "false")
export IS_CONTACT=$(get_api_var "IS_CONTACT" "false")
export IS_BIOMETRIC=$(get_api_var "IS_BIOMETRIC" "false")
export IS_CALENDAR=$(get_api_var "IS_CALENDAR" "false")
export IS_STORAGE=$(get_api_var "IS_STORAGE" "false")

# Create output directory
mkdir -p output/ios
mkdir -p build/ios/logs

# Step 1: Environment Setup
log_info "Step 1: Environment Setup"
log "Setting up build environment..."

# Generate environment configuration
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "Environment configuration generated successfully"
    else
        log_error "Environment configuration failed"
        exit 1
    fi
else
    log_error "Environment configuration script not found"
    exit 1
fi

# Generate env.g.dart if needed
if [ -f "lib/scripts/utils/gen_env_g.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_g.sh
    if ./lib/scripts/utils/gen_env_g.sh; then
        log_success "env.g.dart generated"
    else
        log_warning "env.g.dart generation failed (continuing...)"
    fi
fi

# Step 1.1: Inject iOS Permissions
log_info "Step 1.1: iOS Permissions Injection"
log "Injecting conditional permissions based on environment variables..."

if [ -f "lib/scripts/ios-workflow/ios_permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/ios_permissions.sh
    if ./lib/scripts/ios-workflow/ios_permissions.sh; then
        log_success "iOS permissions injection completed"
    else
        log_warning "iOS permissions injection failed (continuing...)"
    fi
else
    log_warning "iOS permissions script not found, skipping permissions injection"
fi

# Step 2: Asset Downloads
log_info "Step 2: Asset Downloads"
log "Downloading and configuring assets..."

# Download app icons
if [ -n "$LOGO_URL" ]; then
    log "Downloading app icons from: $LOGO_URL"
    mkdir -p assets/icons
    if curl -L -o "assets/icons/app_icon.png" "$LOGO_URL" 2>/dev/null; then
        log_success "App icon downloaded"
    else
        log_warning "Failed to download app icon"
    fi
fi

# Download splash screen
if [ -n "$SPLASH_URL" ]; then
    log "Downloading splash screen from: $SPLASH_URL"
    mkdir -p assets/images
    if curl -L -o "assets/images/splash.png" "$SPLASH_URL" 2>/dev/null; then
        log_success "Splash screen downloaded"
    else
        log_warning "Failed to download splash screen"
    fi
fi

# Step 3: Firebase Setup (if PUSH_NOTIFY is true)
if [ "$PUSH_NOTIFY" = "true" ]; then
    log_info "Step 3: Firebase Setup"
    log "Configuring Firebase for push notifications..."
    
    if [ -n "$FIREBASE_CONFIG_IOS" ]; then
        # Download Firebase configuration
        if curl -L -o "ios/Runner/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS" 2>/dev/null; then
            log_success "Firebase configuration downloaded"
        else
            log_warning "Failed to download Firebase configuration"
        fi
    else
        log_warning "FIREBASE_CONFIG_IOS not provided, skipping Firebase setup"
    fi
else
    log_info "Step 3: Firebase Setup (Skipped)"
    log "PUSH_NOTIFY is false, skipping Firebase setup"
fi

# Step 4: App Configuration
log_info "Step 4: App Configuration"
log "Configuring app settings..."

# Update bundle identifier
if [ -n "$BUNDLE_ID" ]; then
    log "Updating bundle identifier to: $BUNDLE_ID"
    if [ -f "lib/scripts/ios-workflow/update_bundle_id_target_only.sh" ]; then
        chmod +x lib/scripts/ios-workflow/update_bundle_id_target_only.sh
        ./lib/scripts/ios-workflow/update_bundle_id_target_only.sh "$BUNDLE_ID" || log_warning "Bundle ID update failed"
    fi
fi

# Update app name
if [ -n "$APP_NAME" ]; then
    log "Updating app name to: $APP_NAME"
    # Update Info.plist
    if [ -f "ios/Runner/Info.plist" ]; then
        plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null || log_warning "Failed to update app name in Info.plist"
    fi
fi

# Step 5: Flutter Dependencies
log_info "Step 5: Flutter Dependencies"
log "Installing Flutter dependencies..."

flutter pub get
flutter clean
flutter pub get

# Generate Flutter configuration files for iOS
log "Generating Flutter configuration files..."
cd ios

# Ensure iOS deployment target is set correctly for Firebase
log "Setting iOS deployment target to 13.0 for Firebase compatibility..."
if [ -f "Podfile" ]; then
    sed -i '' 's/platform :ios, '"'"'[0-9.]*'"'"'/platform :ios, '"'"'13.0'"'"'/g' Podfile
fi

# Update project.pbxproj deployment target
if [ -f "Runner.xcodeproj/project.pbxproj" ]; then
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' Runner.xcodeproj/project.pbxproj
fi

flutter build ios --no-codesign --debug --verbose || {
    log_warning "Failed to generate iOS configuration, trying alternative approach"
    cd ..
    flutter pub get
    cd ios
    flutter pub get
}

# Step 6: iOS Dependencies
log_info "Step 6: iOS Dependencies"
log "Installing iOS dependencies..."

# Ensure Podfile exists and is properly configured
if [ ! -f "Podfile" ]; then
    log_error "Podfile not found. Creating Podfile..."
    cat > Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!


end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Set minimum deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
EOF
    log_success "Podfile created successfully"
fi

# Validate that Flutter configuration files exist
if [ ! -f "Flutter/Generated.xcconfig" ]; then
    log_error "Flutter configuration files not found. Generated.xcconfig is missing."
    log "Attempting to regenerate Flutter configuration..."
    cd ..
    flutter clean
    flutter pub get
    cd ios
    flutter build ios --no-codesign --debug --verbose || {
        log_error "Failed to generate Flutter configuration files"
        exit 1
    }
fi

rm -rf Pods/ Podfile.lock
pod install --repo-update

# Step 6.1: Fix CwlCatchException Swift compiler error
log_info "Step 6.1: Fixing CwlCatchException Swift compiler error"
if [ -f "../lib/scripts/ios-workflow/fix_cwl_catch_exception.sh" ]; then
    chmod +x ../lib/scripts/ios-workflow/fix_cwl_catch_exception.sh
    # Set build mode for the fix script
    export FLUTTER_BUILD_MODE="release"
    export BUILD_CONFIGURATION="Release"
    if ../lib/scripts/ios-workflow/fix_cwl_catch_exception.sh; then
        log_success "CwlCatchException fix completed"
    else
        log_warning "CwlCatchException fix failed (continuing...)"
    fi
else
    log_warning "CwlCatchException fix script not found"
fi

cd ..

# Step 7: Build Configuration
log_info "Step 7: Build Configuration"
log "Configuring build settings..."

# Create ExportOptions.plist with modern App Store Connect API support
cat > ios/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$PROFILE_TYPE</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>manageVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF

# Configure code signing for modern App Store Connect API
if [ -n "$APP_STORE_CONNECT_KEY_IDENTIFIER" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ] && [ -n "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    log_info "Configuring modern App Store Connect API code signing..."
    
    # Download API key
    API_KEY_PATH="/tmp/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
    if curl -L -o "$API_KEY_PATH" "$APP_STORE_CONNECT_API_KEY_URL" 2>/dev/null; then
        chmod 600 "$API_KEY_PATH"
        log_success "App Store Connect API key downloaded"
        
        # Update ExportOptions.plist for API key signing
        plutil -replace apiKeyID -string "$APP_STORE_CONNECT_KEY_IDENTIFIER" ios/ExportOptions.plist 2>/dev/null || true
        plutil -replace apiKeyIssuerID -string "$APP_STORE_CONNECT_ISSUER_ID" ios/ExportOptions.plist 2>/dev/null || true
        plutil -replace apiKeyPath -string "$API_KEY_PATH" ios/ExportOptions.plist 2>/dev/null || true
        
        log_success "ExportOptions.plist updated for App Store Connect API"
    else
        log_warning "Failed to download App Store Connect API key, using automatic signing"
    fi
else
    log_info "App Store Connect API credentials not provided, using automatic signing"
fi

# Step 8: Build Archive
log_info "Step 8: Build Archive"
log "Building iOS archive..."

# Set build environment
export FLUTTER_BUILD_NUMBER="$VERSION_CODE"
export FLUTTER_VERSION_NAME="$VERSION_NAME"

# Build archive
flutter build ios --release --no-codesign

# Step 9: Create Archive
log_info "Step 9: Create Archive"
log "Creating Xcode archive..."

cd ios
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/Runner.xcarchive \
    archive \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration

cd ..

# Step 10: Export IPA
log_info "Step 10: Export IPA"
log "Exporting IPA file..."

cd ios
xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportPath build/ios/ipa \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates

cd ..

# Step 11: Validate Build
log_info "Step 11: Validate Build"
log "Validating build results..."

# Check if IPA was created
IPA_FILES=$(find . -name "*.ipa" -type f 2>/dev/null || true)
if [ -n "$IPA_FILES" ]; then
    IPA_PATH=$(echo "$IPA_FILES" | head -1)
    IPA_SIZE=$(stat -f%z "$IPA_PATH" 2>/dev/null || stat -c%s "$IPA_PATH" 2>/dev/null || echo "0")
    
    if [ "$IPA_SIZE" -gt 1000000 ]; then
        log_success "IPA created successfully: $IPA_PATH ($IPA_SIZE bytes)"
        
        # Copy to output directory
        cp "$IPA_PATH" "output/ios/Runner.ipa"
        log_success "IPA copied to output/ios/Runner.ipa"
    else
        log_error "IPA file is too small ($IPA_SIZE bytes) - build may have failed"
        exit 1
    fi
else
    log_error "No IPA file found - build failed"
    exit 1
fi

# Step 12: TestFlight Upload (if enabled)
if [ "$IS_TESTFLIGHT" = "true" ] && [ -n "$APP_STORE_CONNECT_KEY_IDENTIFIER" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ] && [ -n "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    log_info "Step 12: TestFlight Upload"
    log "Uploading to TestFlight..."
    
    # Download API key
    API_KEY_PATH="/tmp/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
    if curl -L -o "$API_KEY_PATH" "$APP_STORE_CONNECT_API_KEY_URL" 2>/dev/null; then
        chmod 600 "$API_KEY_PATH"
        log_success "API key downloaded"
        
        # Upload to TestFlight
        if xcrun altool --upload-app --type ios --file "output/ios/Runner.ipa" --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" --apiKeyPath "$API_KEY_PATH"; then
            log_success "TestFlight upload completed successfully"
        else
            log_error "TestFlight upload failed"
            exit 1
        fi
    else
        log_error "Failed to download API key"
        exit 1
    fi
else
    log_info "Step 12: TestFlight Upload (Skipped)"
    log "TestFlight upload not enabled or missing credentials"
fi

# Step 13: Create Build Summary
log_info "Step 13: Create Build Summary"
log "Creating build summary..."

cat > output/ios/ARTIFACTS_SUMMARY.txt <<EOF
iOS Build Summary
=================

Build Information:
- Workflow ID: $WORKFLOW_ID
- App Name: $APP_NAME
- Version Name: $VERSION_NAME
- Version Code: $VERSION_CODE
- Bundle ID: $BUNDLE_ID
- Team ID: $APPLE_TEAM_ID
- Profile Type: $PROFILE_TYPE

Feature Flags:
- Push Notifications: $PUSH_NOTIFY
- Firebase Setup: $([ "$PUSH_NOTIFY" = "true" ] && echo "Enabled" || echo "Disabled")
- TestFlight Upload: $([ "$IS_TESTFLIGHT" = "true" ] && echo "Enabled" || echo "Disabled")

Build Results:
- IPA File: output/ios/Runner.ipa
- Build Time: $(date)
- Build Status: SUCCESS

Environment Variables Used:
$(env | grep -E '^(WORKFLOW_ID|APP_NAME|VERSION_NAME|VERSION_CODE|EMAIL_ID|BUNDLE_ID|APPLE_TEAM_ID|PROFILE_TYPE|IS_TESTFLIGHT|PUSH_NOTIFY)' | sort)
EOF

log_success "Build completed successfully!"
log "Build artifacts available in: output/ios/" 