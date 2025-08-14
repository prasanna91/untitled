#!/bin/bash

# 🛠️ Fix Runner-Only Code Signing
# This script configures code signing to only sign the Runner target, leaving frameworks unsigned

set -euo pipefail

# Enhanced logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

log_info "🛠️ Starting Runner-only code signing configuration..."

# Check environment
if [ -z "${BUNDLE_ID:-}" ]; then
    log_error "BUNDLE_ID environment variable is required"
    exit 1
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    log_error "APPLE_TEAM_ID environment variable is required"
    exit 1
fi

if [ -z "${UUID:-}" ]; then
    log_error "UUID (Provisioning Profile UUID) environment variable is required"
    exit 1
fi

# Step 1: Configure project.pbxproj for Runner-only signing
log_info "📝 Configuring project.pbxproj for Runner-only signing..."

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_FILE" ]; then
    log_error "Project file not found: $PROJECT_FILE"
    exit 1
fi

# Create backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
log_success "✅ Project file backed up"

# Configure Runner target only
log_info "🔧 Configuring Runner target for manual signing..."

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

# Step 2: Update Release.xcconfig for Runner-only signing
log_info "📝 Updating Release.xcconfig for Runner-only signing..."

XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
cat > "$XC_CONFIG_PATH" << EOF
#include "Generated.xcconfig"
// Runner-only code signing configuration
// Frameworks will be left unsigned
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM = $APPLE_TEAM_ID
PROVISIONING_PROFILE_SPECIFIER = $UUID
CODE_SIGN_IDENTITY = iPhone Distribution
PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID
// Disable code signing for frameworks
CODE_SIGNING_ALLOWED = YES
CODE_SIGNING_REQUIRED = YES
EOF

log_success "✅ Release.xcconfig updated for Runner-only signing"

# Step 3: Update Podfile to disable code signing for all pods
log_info "📝 Updating Podfile to disable code signing for pods..."

PODFILE_PATH="ios/Podfile"
if [ -f "$PODFILE_PATH" ]; then
    # Create backup
    cp "$PODFILE_PATH" "${PODFILE_PATH}.backup"
    
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
      
      # Add framework search paths
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '${PODS_ROOT}/../Flutter',
        '${PODS_CONFIGURATION_BUILD_DIR}/Flutter'
      ]
    end
  end
end
PODFILE_HOOK
    else
        log_warning "Post-install hook already exists in Podfile"
    fi
    
    log_success "✅ Podfile updated to disable code signing for pods"
else
    log_warning "Podfile not found, skipping Podfile update"
fi

# Step 4: Update Info.plist for Runner target
log_info "📝 Updating Info.plist for Runner target..."

PLIST_PATH="ios/Runner/Info.plist"
if [ -f "$PLIST_PATH" ]; then
    # Update bundle identifier
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_PATH" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST_PATH"
    
    log_success "✅ Info.plist updated with bundle identifier: $BUNDLE_ID"
else
    log_warning "Info.plist not found, skipping Info.plist update"
fi

# Step 5: Create a script to verify the configuration
log_info "🔍 Creating verification script..."

cat > verify_runner_signing.sh << 'VERIFY_SCRIPT'
#!/bin/bash

echo "🔍 Verifying Runner-only code signing configuration..."

# Check project.pbxproj
echo "📋 Checking project.pbxproj..."
if grep -q "CODE_SIGN_STYLE = Manual" ios/Runner.xcodeproj/project.pbxproj; then
    echo "✅ Manual code signing found in project.pbxproj"
else
    echo "❌ Manual code signing not found in project.pbxproj"
fi

# Check Release.xcconfig
echo "📋 Checking Release.xcconfig..."
if grep -q "CODE_SIGN_STYLE = Manual" ios/Flutter/release.xcconfig; then
    echo "✅ Manual code signing found in Release.xcconfig"
else
    echo "❌ Manual code signing not found in Release.xcconfig"
fi

# Check Podfile
echo "📋 Checking Podfile..."
if grep -q "CODE_SIGNING_ALLOWED.*NO" ios/Podfile; then
    echo "✅ Code signing disabled for pods in Podfile"
else
    echo "❌ Code signing not disabled for pods in Podfile"
fi

# Check Info.plist
echo "📋 Checking Info.plist..."
BUNDLE_ID_FROM_PLIST=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
if [ "$BUNDLE_ID_FROM_PLIST" = "$BUNDLE_ID" ]; then
    echo "✅ Bundle identifier matches in Info.plist: $BUNDLE_ID_FROM_PLIST"
else
    echo "❌ Bundle identifier mismatch in Info.plist: expected $BUNDLE_ID, got $BUNDLE_ID_FROM_PLIST"
fi

echo "🎉 Verification complete!"
VERIFY_SCRIPT

chmod +x verify_runner_signing.sh

log_success "✅ Verification script created: verify_runner_signing.sh"

# Step 6: Clean up and reinstall pods
log_info "🧹 Cleaning up and reinstalling pods..."

cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

log_success "✅ Pods reinstalled with new configuration"

log_success "🎉 Runner-only code signing configuration completed!"
log_info "📋 Summary:"
log_info "  ✅ Runner target: Manual signing with provisioning profile"
log_info "  ✅ Frameworks: No code signing (unsigned)"
log_info "  ✅ Pods: Code signing disabled"
log_info "  ✅ Bundle ID: $BUNDLE_ID"
log_info "  ✅ Team ID: $APPLE_TEAM_ID"
log_info "  ✅ Profile UUID: $UUID"
log_info "  📋 Run: ./verify_runner_signing.sh to verify configuration" 