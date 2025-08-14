#!/usr/bin/env bash

# 🚀 iOS Workflow Main Script
# Comprehensive iOS build workflow with all required functionality
# Based on improved_ios_workflow.sh with enhanced features

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Enhanced logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🚀 Starting iOS Workflow Main Script..."

# Environment info
echo "📊 Build Environment:"
echo " - Flutter: $(flutter --version | head -1)"
echo " - Xcode: $(xcodebuild -version | head -1)"
echo " - CocoaPods: $(pod --version)"
echo " - Bundle ID: $BUNDLE_ID"
echo " - Team ID: $APPLE_TEAM_ID"
echo " - Push Notifications: $PUSH_NOTIFY"
echo " - Splash Screen: $IS_SPLASH"
echo " - Firebase iOS Config: ${FIREBASE_CONFIG_IOS:-Not provided}"
echo " - Splash URL: ${SPLASH_URL:-Not provided}"
echo " - Splash BG URL: ${SPLASH_BG_URL:-Not provided}"
echo " - Splash Tagline Font: ${SPLASH_TAGLINE_FONT:-Roboto}"
echo " - Splash Tagline Size: ${SPLASH_TAGLINE_SIZE:-16}"
echo " - Splash Tagline Bold: ${SPLASH_TAGLINE_BOLD:-false}"
echo " - Splash Tagline Italic: ${SPLASH_TAGLINE_ITALIC:-false}"

# Step 1: Pre-build cleanup
log_info "🧹 Step 1: Pre-build cleanup..."
flutter clean > /dev/null 2>&1 || log_warning "flutter clean failed (continuing)"
rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true
log_success "✅ Cleanup completed"

# Step 2: Initialize keychain using Codemagic CLI
log_info "🔐 Step 2: Initialize keychain..."
keychain initialize
log_success "✅ Keychain initialized"

# Step 3: Setup provisioning profile
log_info "📋 Step 3: Setup provisioning profile..."
PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"

if [[ -n "$PROFILE_URL" ]]; then
    PROFILE_PATH="$PROFILES_HOME/app_store.mobileprovision"
    
    if [[ "$PROFILE_URL" == http* ]]; then
        curl -fSL "$PROFILE_URL" -o "$PROFILE_PATH"
        log_success "✅ Downloaded provisioning profile to $PROFILE_PATH"
    else
        cp "$PROFILE_URL" "$PROFILE_PATH"
        log_success "✅ Copied provisioning profile from $PROFILE_URL to $PROFILE_PATH"
    fi
    
    # Extract information from provisioning profile
    security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
    UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
    BUNDLE_ID_FROM_PROFILE=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
    
    if [[ -n "$UUID" ]]; then
        log_success "✅ Extracted UUID: $UUID"
    fi
    if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
        log_success "✅ Bundle ID from profile: $BUNDLE_ID_FROM_PROFILE"
        
        # Use bundle ID from profile if BUNDLE_ID is not set or is default
        if [[ -z "$BUNDLE_ID" || "$BUNDLE_ID" == "com.example.sampleprojects.sampleProject" || "$BUNDLE_ID" == "com.test.app" ]]; then
            BUNDLE_ID="$BUNDLE_ID_FROM_PROFILE"
            log_info "✅ Using bundle ID from provisioning profile: $BUNDLE_ID"
        else
            log_info "✅ Using provided bundle ID: $BUNDLE_ID (profile has: $BUNDLE_ID_FROM_PROFILE)"
        fi
    fi
else
    log_warning "⚠️ No provisioning profile URL provided (PROFILE_URL)"
    UUID=""
fi

# Step 4: Setup certificate using Codemagic CLI
log_info "🔑 Step 4: Setup certificate..."
if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
    # Download P12 certificate
    curl -fSL "$CERT_P12_URL" -o /tmp/certificate.p12
    log_success "✅ Downloaded certificate to /tmp/certificate.p12"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
    log_success "✅ Certificate added to keychain using Codemagic CLI"
    
elif [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
    # Download CER and KEY files
    curl -fSL "$CERT_CER_URL" -o /tmp/certificate.cer
    curl -fSL "$CERT_KEY_URL" -o /tmp/certificate.key
    log_success "✅ Downloaded CER and KEY files"
    
    # Generate P12 from CER/KEY
    openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -passout pass:"${CERT_PASSWORD:-quikapp2025}"
    log_success "✅ Generated P12 from CER/KEY files"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "${CERT_PASSWORD:-quikapp2025}"
    log_success "✅ Certificate added to keychain using Codemagic CLI"
else
    log_warning "⚠️ No certificate configuration provided"
fi

# Step 5: Validate signing identities
log_info "🔍 Step 5: Validate signing identities..."
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    log_error "❌ No valid iPhone Distribution signing identities found in keychain. Exiting build."
    exit 1
else
    log_success "✅ Found $IDENTITY_COUNT valid iPhone Distribution identity(ies) in keychain."
fi

# Step 6: Validate provisioning profile and bundle ID match
log_info "🔍 Step 6: Validate provisioning profile and bundle ID match..."
if [[ -n "$UUID" && -n "$BUNDLE_ID" ]]; then
    if [[ -f "$PROFILE_PATH" ]]; then
        log_success "✅ Provisioning profile exists: $PROFILE_PATH"
        
        if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
            if [[ "$BUNDLE_ID_FROM_PROFILE" == "$BUNDLE_ID" ]]; then
                log_success "✅ Bundle ID matches provisioning profile: $BUNDLE_ID"
            else
                log_warning "⚠️ Bundle ID mismatch with provisioning profile"
                log_warning "Profile expects: $BUNDLE_ID_FROM_PROFILE"
                log_warning "Using: $BUNDLE_ID"
                log_info "This might cause signing issues. Consider updating the provisioning profile."
            fi
        fi
    else
        log_warning "⚠️ Provisioning profile not found at expected location"
    fi
else
    log_warning "⚠️ Missing UUID or BUNDLE_ID for validation"
fi

# Step 7: Generate environment configuration
log_info "📝 Step 7: Generate environment configuration..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "✅ Environment configuration generated successfully"
    else
        log_error "❌ Environment configuration failed"
        exit 1
    fi
else
    log_error "❌ Environment configuration script not found"
    exit 1
fi

# Step 8: Update display name and bundle id
log_info "📱 Step 8: Update app configuration..."
if [[ -n "$APP_NAME" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
        && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST_PATH" \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST_PATH"
    log_success "✅ Updated app display name to: $APP_NAME"
fi

if [[ -n "$BUNDLE_ID" ]]; then
    log_info "✅ Updating bundle identifier to: $BUNDLE_ID"
    
    # List of possible default bundle IDs to replace
    DEFAULT_BUNDLE_IDS=("com.example.sampleprojects.sampleProject" "com.test.app" "com.example.quikapp")
    
    for OLD_BUNDLE_ID in "${DEFAULT_BUNDLE_IDS[@]}"; do
        log_info "Replacing $OLD_BUNDLE_ID with $BUNDLE_ID"
        find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
        find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
        find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
    done
    
    # Also update the Info.plist directly
    PLIST_PATH="ios/Runner/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_PATH" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST_PATH"
    
    # Update project.pbxproj PRODUCT_BUNDLE_IDENTIFIER
    PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
    if [[ -f "$PROJECT_FILE" ]]; then
        log_info "Updating PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj..."
        sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" "$PROJECT_FILE"
        log_success "Updated PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj"
    fi
    
    log_success "✅ Bundle Identifier updated to $BUNDLE_ID"
fi

# Step 9: Update app icon and splash screen (if provided)
log_info "🎨 Step 9: Update app icon and splash screen..."

# Download app icon
if [[ -n "$LOGO_URL" ]]; then
    log_info "📥 Downloading app icon from: $LOGO_URL"
    mkdir -p assets/images
    if curl -fSL "$LOGO_URL" -o assets/images/logo.png 2>/dev/null; then
        log_success "✅ App icon downloaded"
        
        # Copy to iOS app icon location
        cp assets/images/logo.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png 2>/dev/null || log_warning "Could not copy to iOS app icon"
    else
        log_warning "⚠️ Failed to download app icon"
    fi
else
    log_info "ℹ️ No app icon URL provided, using default"
fi

# Download splash screen image
if [[ -n "$SPLASH_URL" ]]; then
    log_info "📥 Downloading splash screen from: $SPLASH_URL"
    mkdir -p assets/images
    if curl -fSL "$SPLASH_URL" -o assets/images/splash.png 2>/dev/null; then
        log_success "✅ Splash screen downloaded"
        
        # Copy to iOS splash location
        cp assets/images/splash.png ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png 2>/dev/null || log_warning "Could not copy to iOS splash"
        cp assets/images/splash.png ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png 2>/dev/null || log_warning "Could not copy to iOS splash@2x"
        cp assets/images/splash.png ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png 2>/dev/null || log_warning "Could not copy to iOS splash@3x"
    else
        log_warning "⚠️ Failed to download splash screen"
    fi
else
    log_info "ℹ️ No splash screen URL provided, using default"
fi

# Download splash background image (if provided)
if [[ -n "$SPLASH_BG_URL" ]]; then
    log_info "📥 Downloading splash background from: $SPLASH_BG_URL"
    mkdir -p assets/images
    if curl -fSL "$SPLASH_BG_URL" -o assets/images/splash_bg.png 2>/dev/null; then
        log_success "✅ Splash background downloaded"
    else
        log_warning "⚠️ Failed to download splash background"
    fi
else
    log_info "ℹ️ No splash background URL provided"
fi

# Step 10: Flutter dependencies
log_info "📦 Step 10: Install Flutter dependencies..."
flutter pub get > /dev/null || {
    log_error "❌ flutter pub get failed"
    exit 1
}
log_success "✅ Flutter dependencies installed"

# Step 10.5: Setup Firebase configuration (if enabled)
log_info "🔥 Step 10.5: Setup Firebase configuration..."
if [[ "$PUSH_NOTIFY" == "true" && -n "$FIREBASE_CONFIG_IOS" ]]; then
    log_info "📥 Downloading iOS Firebase configuration..."
    mkdir -p ios/Runner
    if curl -fSL "$FIREBASE_CONFIG_IOS" -o ios/Runner/GoogleService-Info.plist 2>/dev/null; then
        log_success "✅ iOS Firebase configuration downloaded"
        
        # Validate the plist file
        if /usr/libexec/PlistBuddy -c "Print :API_KEY" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
            log_success "✅ Firebase configuration validated"
        else
            log_warning "⚠️ Firebase configuration may be invalid"
        fi
    else
        log_warning "⚠️ Failed to download iOS Firebase configuration"
    fi
else
    log_info "ℹ️ Firebase not enabled or iOS config not provided (PUSH_NOTIFY=$PUSH_NOTIFY)"
fi

# Step 11: CocoaPods commands
log_info "📦 Step 11: Setup CocoaPods..."
if [ -f "ios/Podfile.lock" ]; then
    cp ios/Podfile.lock ios/Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
    rm ios/Podfile.lock
    log_info "🗑️ Removed original Podfile.lock"
else
    log_warning "⚠️ Podfile.lock not found — skipping backup and removal"
fi

if ! command -v pod &>/dev/null; then
    log_error "❌ CocoaPods is not installed!"
    exit 1
fi

pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }
log_info "🔄 Running: pod install"

if pod install > /dev/null 2>&1; then
    log_success "✅ pod install completed successfully"
else
    log_error "❌ pod install failed"
    popd > /dev/null
    exit 1
fi

popd > /dev/null
log_success "✅ CocoaPods commands completed"

# Step 12: Configure code signing for Runner-only
log_info "🔧 Step 12: Configure Runner-only code signing..."

# Update Release.xcconfig
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
log_info "🔧 Updating release.xcconfig with dynamic signing values..."
sed -i '' '/^CODE_SIGN_STYLE/d' "$XC_CONFIG_PATH"
sed -i '' '/^DEVELOPMENT_TEAM/d' "$XC_CONFIG_PATH"
sed -i '' '/^PROVISIONING_PROFILE_SPECIFIER/d' "$XC_CONFIG_PATH"
sed -i '' '/^CODE_SIGN_IDENTITY/d' "$XC_CONFIG_PATH"
sed -i '' '/^PRODUCT_BUNDLE_IDENTIFIER/d' "$XC_CONFIG_PATH"

cat <<EOF >> "$XC_CONFIG_PATH"
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM = $APPLE_TEAM_ID
PROVISIONING_PROFILE_SPECIFIER = $UUID
CODE_SIGN_IDENTITY = iPhone Distribution
PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID
EOF

log_success "✅ release.xcconfig updated"

# Configure project.pbxproj for Runner-only signing
log_info "🔧 Configuring project.pbxproj for Runner-only signing..."
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

# Use awk to modify the project file for Runner-only signing
awk -v bundle_id="$BUNDLE_ID" -v team_id="$APPLE_TEAM_ID" -v profile_uuid="$UUID" '
BEGIN { in_runner_target = 0; in_build_settings = 0; }

# Detect Runner target
/isa = PBXNativeTarget;/ { in_runner_target = 0; }
/name = Runner;/ { in_runner_target = 1; }

# Detect build settings section
/isa = XCBuildConfiguration;/ { in_build_settings = 0; }
/name = Runner;/ && in_runner_target { in_build_settings = 1; }

# In Runner target build settings, configure signing
in_build_settings && /buildSettings = {/ {
    print;
    print "\t\t\t\t\tCODE_SIGN_STYLE = Manual;";
    print "\t\t\t\t\tDEVELOPMENT_TEAM = " team_id ";";
    print "\t\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = " profile_uuid ";";
    print "\t\t\t\t\tCODE_SIGN_IDENTITY = \"iPhone Distribution\";";
    print "\t\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = " bundle_id ";";
    print "\t\t\t\t\tCODE_SIGNING_ALLOWED = YES;";
    print "\t\t\t\t\tCODE_SIGNING_REQUIRED = YES;";
    next;
}

# In Runner target build settings, remove any existing signing settings
in_build_settings && /CODE_SIGN_STYLE/ { next; }
in_build_settings && /DEVELOPMENT_TEAM/ { next; }
in_build_settings && /PROVISIONING_PROFILE_SPECIFIER/ { next; }
in_build_settings && /CODE_SIGN_IDENTITY/ { next; }
in_build_settings && /PRODUCT_BUNDLE_IDENTIFIER/ { next; }
in_build_settings && /CODE_SIGNING_ALLOWED/ { next; }
in_build_settings && /CODE_SIGNING_REQUIRED/ { next; }

# For all other targets (frameworks), disable code signing
/isa = XCBuildConfiguration;/ && !in_runner_target {
    in_build_settings = 1;
    print;
    next;
}

# In non-Runner targets, disable code signing
in_build_settings && !in_runner_target && /buildSettings = {/ {
    print;
    print "\t\t\t\t\tCODE_SIGN_STYLE = Automatic;";
    print "\t\t\t\t\tCODE_SIGNING_ALLOWED = NO;";
    print "\t\t\t\t\tCODE_SIGNING_REQUIRED = NO;";
    print "\t\t\t\t\tDEVELOPMENT_TEAM = \"\";";
    print "\t\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"\";";
    next;
}

# Remove existing signing settings from non-Runner targets
in_build_settings && !in_runner_target && /CODE_SIGN_STYLE/ { next; }
in_build_settings && !in_runner_target && /DEVELOPMENT_TEAM/ { next; }
in_build_settings && !in_runner_target && /PROVISIONING_PROFILE_SPECIFIER/ { next; }
in_build_settings && !in_runner_target && /CODE_SIGN_IDENTITY/ { next; }
in_build_settings && !in_runner_target && /CODE_SIGNING_ALLOWED/ { next; }
in_build_settings && !in_runner_target && /CODE_SIGNING_REQUIRED/ { next; }

# Print all other lines unchanged
{ print }
' "$PROJECT_FILE" > "${PROJECT_FILE}.tmp" && mv "${PROJECT_FILE}.tmp" "$PROJECT_FILE"

log_success "✅ Project file configured for Runner-only signing"

# Step 13: Update Podfile to disable code signing for pods
log_info "📝 Step 13: Update Podfile to disable code signing for pods..."
PODFILE_PATH="ios/Podfile"
if [ -f "$PODFILE_PATH" ]; then
    # Add post_install hook to disable code signing for all pods
    if ! grep -q "post_install" "$PODFILE_PATH"; then
        cat >> "$PODFILE_PATH" << 'PODFILE_HOOK'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Set minimum iOS version
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      # Disable code signing for ALL pods/frameworks
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
      config.build_settings['DEVELOPMENT_TEAM'] = ''
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      
      # Additional optimizations
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
end
PODFILE_HOOK
    fi
    
    log_success "✅ Podfile updated to disable code signing for pods"
else
    log_warning "⚠️ Podfile not found, skipping Podfile update"
fi

# Step 14: Validate bundle ID consistency
log_info "🔍 Step 14: Validate bundle ID consistency..."
ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
if [[ "$ACTUAL_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
    log_warning "Bundle ID mismatch detected!"
    log_warning "Expected: $BUNDLE_ID"
    log_warning "Actual: $ACTUAL_BUNDLE_ID"
    log_info "Fixing bundle ID in Info.plist..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" ios/Runner/Info.plist
    log_success "Bundle ID fixed in Info.plist"
else
    log_success "Bundle ID consistency verified: $BUNDLE_ID"
fi

log_info "Set up code signing settings on Xcode project"
xcode-project use-profiles

# Step 15: Final verification before build
log_info "🔍 Step 15: Final verification before build..."
log_info "Bundle ID: $BUNDLE_ID"
log_info "Team ID: $APPLE_TEAM_ID"
log_info "Provisioning Profile UUID: $UUID"
log_info "Provisioning Profile Path: $PROFILE_PATH"
log_info "Push Notifications: $PUSH_NOTIFY"
log_info "Splash Screen: $IS_SPLASH"
log_info "Firebase iOS Config: ${FIREBASE_CONFIG_IOS:-Not provided}"
log_info "Splash URL: ${SPLASH_URL:-Not provided}"
log_info "Splash BG URL: ${SPLASH_BG_URL:-Not provided}"
log_info "Splash Tagline Font: ${SPLASH_TAGLINE_FONT:-Roboto}"
log_info "Splash Tagline Size: ${SPLASH_TAGLINE_SIZE:-16}"
log_info "Splash Tagline Bold: ${SPLASH_TAGLINE_BOLD:-false}"
log_info "Splash Tagline Italic: ${SPLASH_TAGLINE_ITALIC:-false}"

# Verify key files exist
if [[ -f "ios/Runner/Info.plist" ]]; then
    ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
    log_info "Info.plist Bundle ID: $ACTUAL_BUNDLE_ID"
fi

if [[ -f "ios/Flutter/release.xcconfig" ]]; then
    log_info "Release.xcconfig contents:"
    cat ios/Flutter/release.xcconfig
fi

log_success "✅ Pre-build verification completed"

# Step 16: Generate environment configuration
log_info "📝 Step 16: Generate environment configuration..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "✅ Environment configuration generated successfully"
    else
        log_error "❌ Failed to generate environment configuration"
        exit 1
    fi
else
    log_warning "⚠️ Environment config script not found, skipping..."
fi

# Step 17: Build Flutter iOS app
log_info "📱 Step 17: Build Flutter iOS app..."
flutter build ios --release --no-codesign \
    --build-name="$VERSION_NAME" \
    --build-number="$VERSION_CODE" \
    2>&1 | tee flutter_build.log

# Check if Flutter build was successful
if [ $? -eq 0 ]; then
    log_success "✅ Flutter build completed successfully"
else
    log_error "❌ Flutter build failed"
    # Show relevant error messages from the log
    echo "=== Flutter Build Log (Errors/Warnings) ==="
    grep -E "(Error|FAILURE|Exception|error|warning|Warning)" flutter_build.log || echo "No specific errors found in log"
    echo "=== End Flutter Build Log ==="
    exit 1
fi

# Step 18: Archive app with Xcode
log_info "📦 Step 18: Archive app with Xcode..."
mkdir -p build/ios/archive

xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    archive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    2>&1 | tee xcodebuild_archive.log

# Check if Xcode archive was successful
if [ $? -eq 0 ]; then
    log_success "✅ Xcode archive completed successfully"
else
    log_error "❌ Xcode archive failed"
    # Show relevant error messages from the log
    echo "=== Xcode Archive Log (Errors/Warnings) ==="
    grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED)" xcodebuild_archive.log || echo "No specific errors found in log"
    echo "=== End Xcode Archive Log ==="
    exit 1
fi

# Step 19: Create ExportOptions.plist
log_info "🛠️ Step 19: Create ExportOptions.plist..."
cat > ios/ExportOptions.plist << EXPORTPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>$UUID</string>
    </dict>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
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
</dict>
</plist>
EXPORTPLIST

log_success "✅ ExportOptions.plist created"

# Step 20: Export IPA
log_info "📤 Step 20: Export IPA..."
set -x # verbose shell output

xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath build/ios/output \
    -exportOptionsPlist ios/ExportOptions.plist

# Find and verify IPA
IPA_PATH=$(find build/ios/output -name "*.ipa" | head -n 1)
if [ -z "$IPA_PATH" ]; then
    echo "IPA not found in build/ios/output. Searching entire clone directory..."
    IPA_PATH=$(find . -name "*.ipa" | head -n 1)
fi
if [ -z "$IPA_PATH" ]; then
    log_error "❌ IPA file not found. Build failed."
    exit 1
fi
log_success "✅ IPA found at: $IPA_PATH"

# Step 21: Create artifacts summary
log_info "📋 Step 21: Create artifacts summary..."
mkdir -p output/ios
cat > output/ios/ARTIFACTS_SUMMARY.txt << EOF
iOS Build Artifacts Summary
===========================

Build Information:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: ${BUNDLE_ID:-Unknown}
- Version: ${VERSION_NAME:-Unknown}
- Build Number: ${VERSION_CODE:-Unknown}
- Team ID: ${APPLE_TEAM_ID:-Unknown}

Features Enabled:
- Push Notifications: ${PUSH_NOTIFY:-false}
- Splash Screen: ${IS_SPLASH:-false}
- Firebase Integration: ${FIREBASE_CONFIG_IOS:+true}
- Splash Customization: ${SPLASH_URL:+true}
- Splash Tagline Font: ${SPLASH_TAGLINE_FONT:-Roboto}
- Splash Tagline Size: ${SPLASH_TAGLINE_SIZE:-16}
- Splash Tagline Bold: ${SPLASH_TAGLINE_BOLD:-false}
- Splash Tagline Italic: ${SPLASH_TAGLINE_ITALIC:-false}

Generated Files:
- IPA File: $IPA_PATH
- Archive: build/ios/archive/Runner.xcarchive
- ExportOptions: ios/ExportOptions.plist
- Release Config: ios/Flutter/release.xcconfig
- Firebase Config: ${FIREBASE_CONFIG_IOS:+ios/Runner/GoogleService-Info.plist}

Build Logs:
- Flutter Build: flutter_build.log
- Xcode Archive: xcodebuild_archive.log

Build Status: ✅ SUCCESS
Build Date: $(date)
EOF

log_success "✅ Artifacts summary created: output/ios/ARTIFACTS_SUMMARY.txt"

# Copy IPA to output directory for easier access
cp "$IPA_PATH" "output/ios/" 2>/dev/null || log_warning "Could not copy IPA to output/ios/"

# List all generated artifacts
log_info "📦 Generated artifacts:"
find build/ios/output -name "*.ipa" -exec echo "  📱 IPA: {}" \;
find build/ios/archive -name "*.xcarchive" -exec echo "  📦 Archive: {}" \;
find output/ios -name "*" -exec echo "  📋 Output: {}" \;

# Step 22: TestFlight Upload (if configured)
if [[ "$IS_TESTFLIGHT" == "true" && -n "$APP_STORE_CONNECT_API_KEY_URL" ]]; then
    log_info "📤 Step 22: Upload to TestFlight..."
    
    APP_STORE_CONNECT_API_KEY_PATH="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
    mkdir -p "$(dirname "$APP_STORE_CONNECT_API_KEY_PATH")"
    curl -fSL "$APP_STORE_CONNECT_API_KEY_URL" -o "$APP_STORE_CONNECT_API_KEY_PATH"
    log_success "✅ API key downloaded to $APP_STORE_CONNECT_API_KEY_PATH"

    xcrun altool --upload-app \
        -f "$IPA_PATH" \
        -t ios \
        --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
        --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
    
    log_success "✅ App uploaded to TestFlight"
else
    log_info "ℹ️ Skipping TestFlight upload (IS_TESTFLIGHT=$IS_TESTFLIGHT)"
fi

# Step 23: Send email notification (if configured)
if [[ "$ENABLE_EMAIL_NOTIFICATIONS" == "true" && -n "$EMAIL_SMTP_SERVER" ]]; then
    log_info "📧 Step 23: Send email notification..."
    if [ -f "lib/scripts/utils/send_email.sh" ]; then
        chmod +x lib/scripts/utils/send_email.sh
        ./lib/scripts/utils/send_email.sh "build_success" "$IPA_PATH"
        log_success "✅ Email notification sent"
    else
        log_warning "⚠️ Email script not found"
    fi
else
    log_info "ℹ️ Skipping email notification (ENABLE_EMAIL_NOTIFICATIONS=$ENABLE_EMAIL_NOTIFICATIONS)"
fi

log_success "🎉 iOS build process completed successfully!"
log_info "📦 Artifacts available in:"
log_info "  📱 IPA: $IPA_PATH"
log_info "  📋 Summary: output/ios/ARTIFACTS_SUMMARY.txt"
log_info "  📦 Archive: build/ios/archive/Runner.xcarchive"
log_info "  📋 Config: ios/ExportOptions.plist"
if [[ "$PUSH_NOTIFY" == "true" && -n "$FIREBASE_CONFIG_IOS" ]]; then
    log_info "  🔥 Firebase: ios/Runner/GoogleService-Info.plist"
fi
if [[ -n "$SPLASH_URL" ]]; then
    log_info "  🎨 Splash: assets/images/splash.png"
fi 