#!/usr/bin/env bash

# 🚀 Dynamic iOS Workflow Script
# Fully dynamic iOS build with comprehensive fixes and optimizations
# Based on improved_ios_workflow.sh with enhanced error handling

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Enhanced logging with timestamps and performance metrics
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }
log_performance() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚡ $1"; }

# Performance monitoring
START_TIME=$(date +%s)
log_performance() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚡ $1 (${elapsed}s elapsed)"
}

echo "🚀 Starting Dynamic iOS Workflow..."

# Environment info with build optimizations
echo "📊 Build Environment:"
echo " - Flutter: $(flutter --version | head -1)"
echo " - Java: $(java -version 2>&1 | head -1)"
echo " - Xcode: $(xcodebuild -version | head -1)"
echo " - CocoaPods: $(pod --version)"
echo " - Parallel Jobs: ${XCODE_PARALLEL_JOBS:-8}"
echo " - Fast Build: ${XCODE_FAST_BUILD:-true}"
echo " - iOS Deployment Target: ${IOS_DEPLOYMENT_TARGET:-13.0}"

# Step 1: Optimized Cleanup and Setup
log_performance "Step 1: Optimized cleanup and setup..."

# Parallel cleanup operations
(
    log_info "Cleaning Flutter..."
    flutter clean > /dev/null 2>&1 || log_warning "flutter clean failed (continuing)"
) &
(
    log_info "Cleaning Xcode derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
) &
(
    log_info "Cleaning build artifacts..."
    rm -rf .dart_tool/ ios/Pods/ ios/build/ ios/.symlinks > /dev/null 2>&1 || true
    rm -f ios/Podfile.lock > /dev/null 2>&1 || true
) &
wait

log_success "Parallel cleanup completed"

# Step 2: Initialize keychain using Codemagic CLI
log_performance "Step 2: Initialize keychain for codesigning..."

log_info "🔐 Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

# Step 3: Setup provisioning profile dynamically
log_performance "Step 3: Dynamic provisioning profile setup..."

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

# Step 4: Setup certificate using Codemagic CLI
log_performance "Step 4: Dynamic certificate setup..."

log_info "Setting up certificate using Codemagic CLI..."

if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
    # Download P12 certificate
    curl -fSL "$CERT_P12_URL" -o /tmp/certificate.p12
    log_success "Downloaded certificate to /tmp/certificate.p12"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
    log_success "Certificate added to keychain using Codemagic CLI"
    
elif [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
    # Download CER and KEY files
    curl -fSL "$CERT_CER_URL" -o /tmp/certificate.cer
    curl -fSL "$CERT_KEY_URL" -o /tmp/certificate.key
    log_success "Downloaded CER and KEY files"
    
    # Generate P12 from CER/KEY
    openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -passout pass:"${CERT_PASSWORD:-quikapp2025}"
    log_success "Generated P12 from CER/KEY files"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "${CERT_PASSWORD:-quikapp2025}"
    log_success "Certificate added to keychain using Codemagic CLI"
else
    log_warning "No certificate configuration provided"
fi

# Step 5: Validate signing identities
log_performance "Step 5: Validate signing identities..."

IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    log_error "No valid iPhone Distribution signing identities found in keychain. Exiting build."
    exit 1
else
    log_success "Found $IDENTITY_COUNT valid iPhone Distribution identity(ies) in keychain."
fi

# Step 6: Optimized Flutter Setup
log_performance "Step 6: Optimized Flutter setup..."

# Initialize Flutter with optimizations
log_info "Initializing Flutter with optimizations..."
flutter pub get --offline > /dev/null 2>&1 || {
    log_warning "Offline pub get failed, trying online..."
    flutter pub get
}

# Step 7: Fix All iOS Permissions for App Store Compliance
log_performance "Step 7: Fix all iOS permissions for App Store compliance..."

# Add missing permission strings to Info.plist for App Store Connect
log_info "🔐 Fixing all iOS permissions for App Store compliance..."
if [ -f "lib/scripts/ios-workflow/fix_all_permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_all_permissions.sh
    if ./lib/scripts/ios-workflow/fix_all_permissions.sh; then
        log_success "✅ All iOS permissions fixed successfully"
    else
        log_error "❌ Failed to fix iOS permissions"
        exit 1
    fi
else
    log_warning "All permissions fix script not found, trying speech-only fix..."
    if [ -f "lib/scripts/ios-workflow/fix_speech_permissions.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_speech_permissions.sh
        if ./lib/scripts/ios-workflow/fix_speech_permissions.sh; then
            log_success "✅ Speech recognition permissions fixed successfully"
        else
            log_error "❌ Failed to fix speech recognition permissions"
            exit 1
        fi
    else
        log_warning "Speech permissions fix script not found, continuing anyway..."
    fi
fi

# Step 8: iOS App Branding (Logo and Splash Screen)
log_performance "Step 8: iOS app branding (logo and splash screen)..."

# Download and set app logo and splash screen from URLs
log_info "🎨 Processing iOS app branding..."
if [ -f "lib/scripts/ios-workflow/ios_branding.sh" ]; then
    chmod +x lib/scripts/ios-workflow/ios_branding.sh
    if ./lib/scripts/ios-workflow/ios_branding.sh; then
        log_success "✅ iOS app branding completed successfully"
    else
        log_error "❌ Failed to complete iOS app branding"
        log_warning "⚠️ Continuing build without custom branding..."
    fi
else
    log_warning "iOS branding script not found, skipping branding..."
fi

# Step 9: Comprehensive iOS Workflow Fix
log_performance "Step 9: Comprehensive iOS workflow fix..."

# Fix dynamic permissions and app icons comprehensively
log_info "🚀 Fixing iOS workflow comprehensively (permissions + app icons)..."
if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh
    if ./lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh; then
        log_success "✅ Comprehensive iOS workflow fix completed successfully"
    else
        log_error "❌ Comprehensive iOS workflow fix failed"
        log_warning "⚠️ Trying individual fixes..."
        
        # Try individual fixes as fallback
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
    log_warning "Comprehensive fix script not found, trying individual fixes..."
    
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

# Step 10: Robust Xcconfig Fix
log_performance "Step 10: Robust xcconfig fix..."

# Fix all xcconfig files with robust approach
log_info "🔍 Starting robust xcconfig fix..."
if [ -f "lib/scripts/ios-workflow/robust_xcconfig_fix.sh" ]; then
    chmod +x lib/scripts/ios-workflow/robust_xcconfig_fix.sh
    if ./lib/scripts/ios-workflow/robust_xcconfig_fix.sh; then
        log_success "✅ Robust xcconfig fix completed"
    else
        log_error "❌ Robust xcconfig fix failed"
        exit 1
    fi
else
    log_warning "Robust xcconfig fix script not found, continuing anyway..."
fi

# Step 11: Optimized Dynamic Configuration Injection
log_performance "Step 11: Optimized dynamic configuration injection..."

if [ -f "lib/scripts/ios-workflow/dynamic_config_injector.sh" ]; then
    chmod +x lib/scripts/ios-workflow/dynamic_config_injector.sh
    if ./lib/scripts/ios-workflow/dynamic_config_injector.sh; then
        log_success "Dynamic iOS configuration injection completed"
    else
        log_error "Dynamic iOS configuration injection failed"
        exit 1
    fi
else
    log_error "Dynamic iOS configuration injector not found"
    exit 1
fi

# Step 12: Optimized Podfile Generation
log_performance "Step 12: Optimized Podfile generation..."

# Generate dynamic Podfile
log_info "🔧 Generating dynamic Podfile..."
if [ -f "lib/scripts/ios-workflow/generate_podfile.sh" ]; then
    chmod +x lib/scripts/ios-workflow/generate_podfile.sh
    if ./lib/scripts/ios-workflow/generate_podfile.sh; then
        log_success "✅ Dynamic Podfile generated"
    else
        log_error "❌ Dynamic Podfile generation failed"
        exit 1
    fi
else
    log_warning "Podfile generation script not found, using existing Podfile"
fi

# Step 13: Optimized Cleanup
log_performance "Step 13: Optimized cleanup..."

# Clean iOS build artifacts
log_info "🧹 Cleaning iOS build artifacts..."
rm -rf ios/build/ ios/.symlinks > /dev/null 2>&1 || true
rm -f ios/Podfile.lock > /dev/null 2>&1 || true

# Step 14: Extract Signing Variables
log_performance "Step 14: Extract signing variables from certificate and profile files..."

# Extract required variables from certificate and profile files
log_info "🔍 Extracting signing variables from certificate and profile files..."
if [ -f "lib/scripts/ios-workflow/extract_signing_variables.sh" ]; then
    chmod +x lib/scripts/ios-workflow/extract_signing_variables.sh
    if ./lib/scripts/ios-workflow/extract_signing_variables.sh; then
        log_success "✅ Signing variables extracted successfully"
        
        # Source the extracted variables
        if [ -f "signing_variables_summary.txt" ]; then
            log_info "📋 Signing variables summary:"
            cat signing_variables_summary.txt
        fi
    else
        log_error "❌ Failed to extract signing variables"
        exit 1
    fi
else
    log_warning "Signing variables extraction script not found, using provided variables..."
fi

# Step 15: Optimized Runner-Only Code Signing Setup
log_performance "Step 15: Optimized Runner-only code signing setup..."

# Configure code signing for Runner target only, leaving frameworks unsigned
log_info "🔧 Configuring Runner-only code signing..."
if [ -f "lib/scripts/ios-workflow/fix_runner_only_codesigning.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_runner_only_codesigning.sh
    if ./lib/scripts/ios-workflow/fix_runner_only_codesigning.sh; then
        log_success "✅ Runner-only code signing configured successfully"
    else
        log_error "❌ Failed to configure Runner-only code signing"
        exit 1
    fi
else
    log_warning "Runner-only code signing script not found, using fallback configuration..."
    
    # Fallback: Basic code signing setup
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
fi

# Step 16: Ensure Xcconfig Before CocoaPods
log_performance "Step 16: Ensure xcconfig before CocoaPods..."

# Ensure Generated.xcconfig exists before CocoaPods
log_info "🔍 Ensuring Generated.xcconfig exists before CocoaPods..."
if [ -f "lib/scripts/ios-workflow/robust_xcconfig_fix.sh" ]; then
    chmod +x lib/scripts/ios-workflow/robust_xcconfig_fix.sh
    if ./lib/scripts/ios-workflow/robust_xcconfig_fix.sh; then
        log_success "✅ Generated.xcconfig is ready for CocoaPods"
    else
        log_error "❌ Failed to create Generated.xcconfig"
        exit 1
    fi
else
    log_warning "Robust xcconfig fix script not found, continuing anyway..."
fi

# Step 17: Optimized CocoaPods Setup
log_performance "Step 17: Optimized CocoaPods setup..."

# Run CocoaPods commands with fallback chain
log_info "📦 Running CocoaPods commands with fallback chain..."

if [ -f "ios/Podfile.lock" ]; then
    cp ios/Podfile.lock ios/Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
    rm ios/Podfile.lock
    log_info "🗑️ Removed original Podfile.lock"
else
    log_warning "⚠️ Podfile.lock not found — skipping backup and removal"
fi

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
    exit 1
fi

popd > /dev/null
log_success "✅ CocoaPods commands completed"

# Step 18: Fix Provisioning Profile Conflicts
log_performance "Step 18: Fixing provisioning profile conflicts..."

# Fix provisioning profile conflicts with CocoaPods
log_info "🔧 Fixing provisioning profile conflicts with CocoaPods..."
if [ -f "lib/scripts/ios-workflow/fix_provisioning_profile_conflicts.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_provisioning_profile_conflicts.sh
    if ./lib/scripts/ios-workflow/fix_provisioning_profile_conflicts.sh; then
        log_success "✅ Provisioning profile conflicts resolved"
    else
        log_error "❌ Failed to fix provisioning profile conflicts"
        exit 1
    fi
else
    log_warning "Provisioning profile conflict fix script not found, continuing anyway..."
fi

# Step 19: Optimized Bundle Configuration
log_performance "Step 19: Optimized bundle configuration..."

# Update display name and bundle id dynamically
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

# Step 20: Optimized Flutter Build
log_performance "Step 20: Optimized Flutter build..."

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

# Optimized Flutter build
log_info "📱 Building Flutter iOS app in release mode with optimizations..."

# Use direct Flutter build command with valid flags only
log_info "Building Flutter iOS app with valid flags..."
flutter build ios --release --no-codesign \
    --build-name="$VERSION_NAME" \
    --build-number="$VERSION_CODE" \
    --verbose \
    2>&1 | tee flutter_build.log

# Check if build was successful
if [ $? -eq 0 ]; then
    log_success "✅ Flutter release build completed successfully"
else
    log_error "❌ Flutter release build failed"
    log_info "Flutter build log:"
    cat flutter_build.log
    exit 1
fi

# Verify Flutter build completed successfully
if ! grep -q "Built.*Runner.app" flutter_build.log; then
    log_error "❌ Flutter build failed - Runner.app not found in build log"
    log_info "Flutter build log:"
    cat flutter_build.log
    exit 1
fi

log_success "✅ Flutter build completed successfully"

# Step 21: Optimized Xcode Configuration
log_performance "Step 21: Optimized Xcode configuration..."

# Verify Runner-only code signing configuration
log_info "🔍 Verifying Runner-only code signing configuration..."

# Check if the configuration was applied correctly
if [ -f "verify_runner_signing.sh" ]; then
    log_info "Running verification script..."
    ./verify_runner_signing.sh
    log_success "✅ Runner-only code signing verification completed"
else
    log_warning "Verification script not found, skipping verification"
fi

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

log_info "✅ Xcode configuration optimized for Runner-only signing"

# Step 22: Optimized Final Build
log_performance "Step 22: Optimized final build..."

# Optimized Xcode archive
log_info "📦 Archiving app with Xcode optimizations..."
mkdir -p build/ios/archive

# Validate required variables
log_info "🔍 Validating required variables for Xcode archive..."
if [[ -z "$APPLE_TEAM_ID" ]]; then
    log_error "❌ APPLE_TEAM_ID is not set"
    exit 1
fi

if [[ -z "$UUID" ]]; then
    log_error "❌ UUID (Provisioning Profile UUID) is not set"
    exit 1
fi

if [[ -z "$BUNDLE_ID" ]]; then
    log_error "❌ BUNDLE_ID is not set"
    exit 1
fi

log_success "✅ All required variables are set"
log_info "Team ID: $APPLE_TEAM_ID"
log_info "Provisioning Profile UUID: $UUID"
log_info "Bundle ID: $BUNDLE_ID"

# Use simplified xcodebuild command without complex options
log_info "🔍 Validating workspace and scheme..."
if [[ ! -d "ios/Runner.xcworkspace" ]]; then
    log_error "❌ ios/Runner.xcworkspace not found"
    exit 1
fi

if [[ ! -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]]; then
    log_error "❌ ios/Runner.xcworkspace is not a valid workspace"
    exit 1
fi

log_success "✅ Workspace validation passed"

# Use a simple, reliable xcodebuild command
log_info "Running xcodebuild archive command..."

xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    archive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="iPhone Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="$UUID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    2>&1 | tee xcodebuild_archive.log

# Verify archive was created successfully
if [ ! -d "build/ios/archive/Runner.xcarchive" ]; then
    log_error "❌ Xcode archive failed - Runner.xcarchive not found"
    log_info "Xcode archive log:"
    cat xcodebuild_archive.log
    exit 1
fi

log_success "✅ Xcode archive completed successfully"

# Verify archive contents
log_info "🔍 Verifying archive contents..."
if [ -d "build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app" ]; then
    if [ -f "build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Runner" ]; then
        log_success "✅ Archive contains Runner executable"
    else
        log_error "❌ Archive does not contain Runner executable"
        log_info "Archive contents:"
        ls -la "build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/"
        exit 1
    fi
else
    log_error "❌ Runner.app not found in archive"
    log_info "Archive structure:"
    find "build/ios/archive/Runner.xcarchive" -type d -name "*.app" 2>/dev/null || echo "No .app directories found"
    exit 1
fi

# Step 23: Optimized IPA Export
log_performance "Step 23: Optimized IPA export..."

log_info "🛠️ Using export provisioning profile conflict fix..."
./lib/scripts/ios-workflow/fix_export_provisioning_conflicts.sh

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
- Xcode Export: xcodebuild_export.log

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

# Step 24: Optimized TestFlight Upload
log_performance "Step 24: Optimized TestFlight upload..."

# Upload to TestFlight if configured
if [[ "$IS_TESTFLIGHT" == "true" && -n "$APP_STORE_CONNECT_API_KEY_URL" ]]; then
    log_info "📤 Uploading to TestFlight..."
    ./lib/scripts/ios-workflow/testflight_upload.sh
    log_success "✅ TestFlight upload completed"
else
    log_info "ℹ️ Skipping TestFlight upload (IS_TESTFLIGHT=$IS_TESTFLIGHT)"
fi

log_success "🎉 Dynamic iOS build process completed successfully!"
log_info "📦 Artifacts available in:"
log_info "  📱 IPA: $IPA_PATH"
log_info "  📋 Summary: output/ios/ARTIFACTS_SUMMARY.txt"
log_info "  📦 Archive: build/ios/archive/Runner.xcarchive"
log_info "  📋 Config: ios/ExportOptions.plist" 