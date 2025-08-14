#!/usr/bin/env bash

# Improved iOS Workflow Script
# Uses Codemagic CLI keychain commands for reliable code signing
# Based on build_ios-workflow(example ref).sh

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }
log() { echo "📌 $1"; }

echo "🚀 Starting Improved iOS Workflow..."

# Environment info
echo "📊 Build Environment:"
echo " - Flutter: $(flutter --version | head -1)"
echo " - Java: $(java -version 2>&1 | head -1)"
echo " - Xcode: $(xcodebuild -version | head -1)"
echo " - CocoaPods: $(pod --version)"

# Cleanup
echo "🧹 Pre-build cleanup..."
flutter clean > /dev/null 2>&1 || log_warning "⚠️ flutter clean failed (continuing)"

rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

# Firebase Setup for iOS Push Notifications
log_info "🔥 Setting up Firebase for iOS Push Notifications..."
if [[ "${PUSH_NOTIFY:-false}" == "true" && -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
    log_info "📥 Downloading Firebase iOS configuration..."
    if curl -fSL "$FIREBASE_CONFIG_IOS" -o ios/Runner/GoogleService-Info.plist 2>/dev/null; then
        log_success "✅ Firebase iOS configuration downloaded successfully"
        
        # Validate the downloaded file
        if /usr/libexec/PlistBuddy -c "Print :API_KEY" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
            log_success "✅ Firebase iOS configuration is valid"
        else
            log_warning "⚠️ Firebase iOS configuration may be invalid"
        fi
    else
        log_error "❌ Failed to download Firebase iOS configuration"
    fi
else
    log_info "ℹ️ Firebase setup skipped (PUSH_NOTIFY=false or no FIREBASE_CONFIG_IOS)"
fi

# Initialize keychain using Codemagic CLI
echo "🔐 Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

# Setup provisioning profile
log_info "Setting up provisioning profile..."

PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"

if [[ -n "$PROFILE_URL" ]]; then
    # Download provisioning profile
    PROFILE_PATH="$PROFILES_HOME/app_store.mobileprovision"
    
    if [[ "$PROFILE_URL" == http* ]]; then
        curl -fSL "$PROFILE_URL" -o "$PROFILE_PATH"
        log_success "Downloaded provisioning profile to $PROFILE_PATH"
    else
        cp "$PROFILE_URL" "$PROFILE_PATH"
        log_success "Copied provisioning profile from $PROFILE_URL to $PROFILE_PATH"
    fi
    
    # Extract information from provisioning profile
    security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
    UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
    BUNDLE_ID_FROM_PROFILE=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
    
    if [[ -n "$UUID" ]]; then
        echo "UUID: $UUID"
    fi
    if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
        echo "Bundle Identifier from profile: $BUNDLE_ID_FROM_PROFILE"
        
        # Use bundle ID from profile if BUNDLE_ID is not set or is default
        if [[ -z "$BUNDLE_ID" || "$BUNDLE_ID" == "com.example.sampleprojects.sampleProject" || "$BUNDLE_ID" == "com.test.app" ]]; then
            BUNDLE_ID="$BUNDLE_ID_FROM_PROFILE"
            log_info "Using bundle ID from provisioning profile: $BUNDLE_ID"
        else
            log_info "Using provided bundle ID: $BUNDLE_ID (profile has: $BUNDLE_ID_FROM_PROFILE)"
        fi
    fi
else
    log_warning "No provisioning profile URL provided (PROFILE_URL)"
    UUID=""
fi

# Setup certificate using Codemagic CLI
log_info "Setting up certificate using Codemagic CLI..."

# Determine certificate type (default to p12 if not specified)
CERT_TYPE="${CERT_TYPE:-p12}"
log_info "Certificate type: $CERT_TYPE"

if [[ "$CERT_TYPE" == "p12" ]]; then
    # P12 Certificate Setup
    if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
        log_info "📥 Downloading P12 certificate from: $CERT_P12_URL"
        curl -fSL "$CERT_P12_URL" -o /tmp/certificate.p12
        log_success "✅ Downloaded P12 certificate to /tmp/certificate.p12"
        
        # Add certificate to keychain using Codemagic CLI
        keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
        log_success "✅ P12 certificate added to keychain using Codemagic CLI"
    else
        log_warning "⚠️ P12 certificate type selected but CERT_P12_URL or CERT_PASSWORD not provided"
        log_info "Continuing without certificate setup..."
    fi
    
elif [[ "$CERT_TYPE" == "manual" ]]; then
    # Manual Certificate Setup (CER + KEY)
    if [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
        log_info "📥 Downloading CER certificate from: $CERT_CER_URL"
        curl -fSL "$CERT_CER_URL" -o /tmp/certificate.cer
        log_success "✅ Downloaded CER certificate"
        
        log_info "📥 Downloading KEY file from: $CERT_KEY_URL"
        curl -fSL "$CERT_KEY_URL" -o /tmp/certificate.key
        log_success "✅ Downloaded KEY file"
        
        # Generate P12 from CER/KEY
        log_info "🔧 Generating P12 from CER/KEY files..."
        if [[ -n "$CERT_PASSWORD" ]]; then
            openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -passout pass:"$CERT_PASSWORD"
            log_success "✅ Generated P12 with password protection"
        else
            openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -nodes
            log_success "✅ Generated P12 without password protection"
        fi
        
        # Add certificate to keychain using Codemagic CLI
        if [[ -n "$CERT_PASSWORD" ]]; then
            keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
        else
            keychain add-certificates --certificate /tmp/certificate.p12
        fi
        log_success "✅ Manual certificate added to keychain using Codemagic CLI"
    else
        log_warning "⚠️ Manual certificate type selected but CERT_CER_URL or CERT_KEY_URL not provided"
        log_info "Continuing without certificate setup..."
    fi
    
else
    log_warning "⚠️ Unknown certificate type: $CERT_TYPE (supported: p12, manual)"
    log_info "Continuing without certificate setup..."
fi

# Validate signing identities
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    log_error "No valid iPhone Distribution signing identities found in keychain. Exiting build."
    exit 1
else
    log_success "Found $IDENTITY_COUNT valid iPhone Distribution identity(ies) in keychain."
fi

# Validate provisioning profile and bundle ID match
if [[ -n "$UUID" && -n "$BUNDLE_ID" ]]; then
    log_info "🔍 Validating provisioning profile and bundle ID match..."
    
    # Check if provisioning profile exists and is valid
    if [[ -f "$PROFILE_PATH" ]]; then
        log_success "Provisioning profile exists: $PROFILE_PATH"
        
        # Verify bundle ID in profile matches our bundle ID
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

# CocoaPods commands
run_cocoapods_commands() {
    if [ -f "ios/Podfile.lock" ]; then
        cp ios/Podfile.lock ios/Podfile.lock.backup
        log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
        rm ios/Podfile.lock
        log_info "🗑️ Removed original Podfile.lock"
    else
        log_warning "⚠️ Podfile.lock not found — skipping backup and removal"
    fi

    log_info "📦 Running CocoaPods commands..."

    if ! command -v pod &>/dev/null; then
        log_error "CocoaPods is not installed!"
        exit 1
    fi

    pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }
    log_info "🔄 Running: pod install"

    if pod install > /dev/null 2>&1; then
        log_success "✅ pod install completed successfully"
    else
        log_error "❌ pod install failed"
        popd > /dev/null
        return 1
    fi

    popd > /dev/null
    log_success "✅ CocoaPods commands completed"
}

# Update display name and bundle id
if [[ -n "$APP_NAME" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
        && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST_PATH" \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST_PATH"
    log_success "Updated app display name to: $APP_NAME"
fi

if [[ -n "$BUNDLE_ID" ]]; then
    log_info "Updating bundle identifier to: $BUNDLE_ID"
    
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
    
    log_success "Bundle Identifier updated to $BUNDLE_ID"
fi

# Generate environment configuration
log_info "📝 Step: Generate environment configuration..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "✅ Environment configuration generated successfully"
        
        # Verify the file was written correctly
        if [ -f "lib/config/env_config.dart" ]; then
            log_info "📋 Verifying environment configuration file..."
            
            # Check file size
            FILE_SIZE=$(stat -f%z "lib/config/env_config.dart" 2>/dev/null || stat -c%s "lib/config/env_config.dart" 2>/dev/null || echo "0")
            if [ "$FILE_SIZE" -gt 100 ]; then
                log_success "✅ Environment configuration file size: ${FILE_SIZE} bytes"
            else
                log_error "❌ Environment configuration file too small: ${FILE_SIZE} bytes"
                exit 1
            fi
            
            # Test Dart syntax
            if flutter analyze lib/config/env_config.dart >/dev/null 2>&1; then
                log_success "✅ Environment configuration syntax is valid"
            else
                log_error "❌ Environment configuration has syntax errors"
                flutter analyze lib/config/env_config.dart
                exit 1
            fi
            
            # Force file system sync
            sync 2>/dev/null || true
            sleep 1
            
            log_success "✅ Environment configuration verified and ready for build"
        else
            log_error "❌ Environment configuration file not found after generation"
            exit 1
        fi
    else
        log_error "❌ Environment configuration failed"
        exit 1
    fi
else
    log_error "❌ Environment configuration script not found"
    exit 1
fi

# Fix all iOS permissions for App Store compliance
log_info "🔐 Step: Fix all iOS permissions for App Store compliance..."
if [ -f "lib/scripts/ios-workflow/fix_all_permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_all_permissions.sh
    if ./lib/scripts/ios-workflow/fix_all_permissions.sh; then
        log_success "✅ All iOS permissions fixed successfully"
    else
        log_error "❌ Failed to fix iOS permissions"
        exit 1
    fi
else
    log_warning "⚠️ All permissions fix script not found, trying speech-only fix..."
    if [ -f "lib/scripts/ios-workflow/fix_speech_permissions.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_speech_permissions.sh
        if ./lib/scripts/ios-workflow/fix_speech_permissions.sh; then
            log_success "✅ Speech recognition permissions fixed successfully"
        else
            log_error "❌ Failed to fix speech recognition permissions"
            exit 1
        fi
    else
        log_warning "⚠️ Speech permissions fix script not found, skipping..."
    fi
fi

# iOS app branding (logo and splash screen)
log_info "🎨 Step: iOS app branding (logo and splash screen)..."
if [ -f "lib/scripts/ios-workflow/ios_branding.sh" ]; then
    chmod +x lib/scripts/ios-workflow/ios_branding.sh
    if ./lib/scripts/ios-workflow/ios_branding.sh; then
        log_success "✅ iOS app branding completed successfully"
    else
        log_error "❌ Failed to complete iOS app branding"
        log_warning "⚠️ Continuing build without custom branding..."
    fi
else
    log_warning "⚠️ iOS branding script not found, skipping branding..."
fi

# Dynamic iOS app icon fix for ITMS compliance (ITMS-90022, ITMS-90023, ITMS-90713)
log_info "🚀 Step: Dynamic iOS app icon fix for ITMS compliance..."
if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_dynamic.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_dynamic.sh
    if ./lib/scripts/ios-workflow/fix_ios_app_icons_dynamic.sh; then
        log_success "✅ Dynamic iOS app icon fix completed successfully"
    else
        log_error "❌ Dynamic iOS app icon fix failed"
        log_warning "⚠️ Trying comprehensive iOS workflow fix..."
        
        # Try comprehensive fix as primary fallback
        if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh
            if ./lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh; then
                log_success "✅ Comprehensive iOS workflow fix completed"
            else
                log_warning "⚠️ Comprehensive fix failed, trying robust ITMS icon fix..."
                
                # Try robust ITMS icon fix as secondary fallback
                if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
                    if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                        log_success "✅ Robust ITMS icon fix completed"
                    else
                        log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                        
                        # Try individual fixes as tertiary fallback
                        if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                            chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                            ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                        fi
                        
                        if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                            chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                            ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                        fi
                    fi
                else
                    log_warning "⚠️ Robust ITMS icon fix script not found, trying individual fixes..."
                    
                    # Try individual fixes
                    if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                        ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                    fi
                    
                    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                        ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                    fi
                fi
            fi
        else
            log_warning "⚠️ Comprehensive fix script not found, trying robust ITMS icon fix..."
            
            # Try robust ITMS icon fix
            if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
                if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                    log_success "✅ Robust ITMS icon fix completed"
                else
                    log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                    
                    # Try individual fixes
                    if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                        ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                    fi
                    
                    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                        ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                    fi
                fi
            else
                log_warning "⚠️ No robust ITMS icon fix script, trying individual fixes..."
                
                # Try individual fixes
                if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                    ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                fi
                
                if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                    ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                fi
            fi
        fi
    fi
else
    log_warning "⚠️ Dynamic iOS app icon fix script not found, trying comprehensive fix..."
    
    # Try comprehensive fix
    if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh
        if ./lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh; then
            log_success "✅ Comprehensive iOS workflow fix completed"
        else
            log_warning "⚠️ Comprehensive fix failed, trying robust ITMS icon fix..."
            
            # Try robust ITMS icon fix
            if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
                if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                    log_success "✅ Robust ITMS icon fix completed"
                else
                    log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                    
                    # Try individual fixes
                    if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                        ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                    fi
                    
                    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                        ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                    fi
                fi
            else
                log_warning "⚠️ No robust ITMS icon fix script, trying individual fixes..."
                
                # Try individual fixes
                if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                    ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                fi
                
                if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                    ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                fi
            fi
        fi
    else
        log_warning "⚠️ No comprehensive fix script, trying robust ITMS icon fix..."
        
        # Try robust ITMS icon fix
        if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
            if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                log_success "✅ Robust ITMS icon fix completed"
            else
                log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                
                # Try individual fixes
                if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                    ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                fi
                
                if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                    ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                fi
            fi
        else
            log_warning "⚠️ No robust ITMS icon fix script, trying individual fixes..."
            
            # Try individual fixes
            if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
            fi
            
            if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
            fi
        fi
    fi
fi

# Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
    log_error "flutter pub get failed"
    exit 1
}

run_cocoapods_commands

# Update Release.xcconfig
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
echo "🔧 Updating release.xcconfig with dynamic signing values..."
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

echo "✅ release.xcconfig updated:"
cat "$XC_CONFIG_PATH"

# Validate bundle ID consistency
log_info "🔍 Validating bundle ID consistency..."
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

echo "Set up code signing settings on Xcode project"
xcode-project use-profiles

# Final verification before build
log_info "🔍 Final verification before build..."
log_info "Bundle ID: $BUNDLE_ID"
log_info "Team ID: $APPLE_TEAM_ID"
log_info "Provisioning Profile UUID: $UUID"
log_info "Provisioning Profile Path: $PROFILE_PATH"

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

# Clean and prepare for build
log_info "🧹 Cleaning build cache to ensure fresh environment configuration..."
flutter clean > /dev/null 2>&1 || log_warning "⚠️ flutter clean failed (continuing)"
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf build/ > /dev/null 2>&1 || true

# Verify environment configuration is still valid after clean
log_info "📋 Re-verifying environment configuration after clean..."
if flutter analyze lib/config/env_config.dart >/dev/null 2>&1; then
    log_success "✅ Environment configuration still valid after clean"
else
    log_error "❌ Environment configuration invalid after clean"
    flutter analyze lib/config/env_config.dart
    exit 1
fi

# Build
log_info "📱 Building Flutter iOS app in release mode..."
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

log_info "📦 Archiving app with Xcode..."
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

log_info "🛠️ Writing ExportOptions.plist..."
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

log_info "📤 Exporting IPA..."
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

# Create artifacts summary
log_info "📋 Creating artifacts summary..."
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

Generated Files:
- IPA File: $IPA_PATH
- Archive: build/ios/archive/Runner.xcarchive
- ExportOptions: ios/ExportOptions.plist
- Release Config: ios/Flutter/release.xcconfig

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

# Upload to App Store Connect if configured
if [[ "$UPLOAD_TO_APP_STORE" == "true" && -n "$APP_STORE_CONNECT_API_KEY_URL" ]]; then
    log_info "📤 Uploading to App Store Connect..."
    
    APP_STORE_CONNECT_API_KEY_PATH="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
    mkdir -p "$(dirname "$APP_STORE_CONNECT_API_KEY_PATH")"
    curl -fSL "$APP_STORE_CONNECT_API_KEY_URL" -o "$APP_STORE_CONNECT_API_KEY_PATH"
    log_success "✅ API key downloaded to $APP_STORE_CONNECT_API_KEY_PATH"

    xcrun altool --upload-app \
        -f "$IPA_PATH" \
        -t ios \
        --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
        --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
    
    log_success "✅ App uploaded to App Store Connect"
else
    log_info "ℹ️ Skipping App Store Connect upload (UPLOAD_TO_APP_STORE=$UPLOAD_TO_APP_STORE)"
fi

log_success "🎉 iOS build process completed successfully!"
log_info "📦 Artifacts available in:"
log_info "  📱 IPA: $IPA_PATH"
log_info "  📋 Summary: output/ios/ARTIFACTS_SUMMARY.txt"
log_info "  📦 Archive: build/ios/archive/Runner.xcarchive"
log_info "  📋 Config: ios/ExportOptions.plist"