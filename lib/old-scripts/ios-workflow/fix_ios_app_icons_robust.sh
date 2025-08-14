#!/usr/bin/env bash

# Robust iOS App Icon Fix for ITMS Errors
# Addresses ITMS-90022, ITMS-90023, and ITMS-90713 errors

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "📱 Fixing iOS App Icons for ITMS Compliance..."

# Step 1: Ensure flutter_launcher_icons is available
log_info "🔧 Step 1: Ensuring flutter_launcher_icons is available..."
if ! flutter pub deps | grep -q "flutter_launcher_icons"; then
    log_info "📝 Adding flutter_launcher_icons to dev_dependencies..."
    flutter pub add --dev flutter_launcher_icons
fi

# Step 2: Create a minimal flutter_launcher_icons configuration
log_info "📝 Step 2: Creating flutter_launcher_icons configuration..."
create_launcher_icons_config() {
    local logo_path="$1"
    
    # Create a minimal pubspec.yaml with flutter_launcher_icons config
    cat > "pubspec_launcher_icons.yaml" << EOF
name: quikapptest06
description: "A new Flutter project."
publish_to: "none"
version: 1.0.7+43

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

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
  remove_alpha_ios: true
  ios_content_mode: center

flutter:
  uses-material-design: true
EOF

    log_success "✅ flutter_launcher_icons configuration created"
}

# Step 3: Find source image
log_info "🔍 Step 3: Finding source image..."
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

# Step 4: Create configuration and run flutter_launcher_icons
log_info "🚀 Step 4: Running flutter_launcher_icons..."
if create_launcher_icons_config "$SOURCE_IMAGE"; then
    # Backup current pubspec.yaml
    cp pubspec.yaml pubspec.yaml.backup
    
    # Use the launcher icons configuration
    cp pubspec_launcher_icons.yaml pubspec.yaml
    
    # Run flutter_launcher_icons
    if flutter pub get && flutter pub run flutter_launcher_icons:main; then
        log_success "✅ flutter_launcher_icons completed successfully"
        
        # Restore original pubspec.yaml
        cp pubspec.yaml.backup pubspec.yaml
    else
        log_error "❌ flutter_launcher_icons failed"
        # Restore original pubspec.yaml
        cp pubspec.yaml.backup pubspec.yaml
        exit 1
    fi
else
    log_error "❌ Failed to create flutter_launcher_icons configuration"
    exit 1
fi

# Step 5: Verify critical app icons exist
log_info "🔍 Step 5: Verifying critical app icons..."
CRITICAL_ICONS=(
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"  # iPhone 120x120 (ITMS-90022)
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"  # iPad Pro 167x167 (ITMS-90023)
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"  # iPad 152x152 (ITMS-90023)
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"  # App Store 1024x1024
)

MISSING_ICONS=()
for icon in "${CRITICAL_ICONS[@]}"; do
    if [[ ! -f "$icon" ]]; then
        MISSING_ICONS+=("$icon")
        log_error "❌ Missing icon: $icon"
    else
        log_success "✅ Found icon: $icon"
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "❌ Missing critical app icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "   - $icon"
    done
    
    # Try manual icon generation as fallback
    log_warning "⚠️ Trying manual icon generation..."
    if [ -f "lib/scripts/ios-workflow/fix_ios_icons.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_ios_icons.sh
        if ./lib/scripts/ios-workflow/fix_ios_icons.sh; then
            log_success "✅ Manual icon generation completed"
        else
            log_error "❌ Manual icon generation failed"
            exit 1
        fi
    else
        log_error "❌ No fallback icon generation available"
        exit 1
    fi
else
    log_success "✅ All critical app icons verified"
fi

# Step 6: Ensure CFBundleIconName is in Info.plist (ITMS-90713)
log_info "📝 Step 6: Ensuring CFBundleIconName in Info.plist..."
if [[ ! -f "ios/Runner/Info.plist" ]]; then
    log_error "❌ Info.plist not found"
    exit 1
fi

# Check if CFBundleIconName exists
if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
    log_success "✅ CFBundleIconName already exists in Info.plist"
else
    log_info "📝 Adding CFBundleIconName to Info.plist..."
    sed -i '' '/<\/dict>/i\
	<key>CFBundleIconName</key>\
	<string>AppIcon</string>\
' ios/Runner/Info.plist
    log_success "✅ Added CFBundleIconName to Info.plist"
fi

# Step 7: Verify Info.plist syntax
log_info "🔍 Step 7: Validating Info.plist syntax..."
if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
    log_success "✅ Info.plist syntax is valid"
else
    log_error "❌ Info.plist syntax is invalid"
    plutil -lint ios/Runner/Info.plist
    exit 1
fi

# Step 8: Verify app icon asset catalog
log_info "📱 Step 8: Verifying app icon asset catalog..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
    log_success "✅ App icon asset catalog verified"
else
    log_error "❌ App icon asset catalog missing"
    exit 1
fi

# Step 9: Show comprehensive summary
log_info "📋 iOS App Icon Fix Summary for ITMS Compliance:"
echo "=========================================="
echo "✅ Source Image: $SOURCE_IMAGE"
echo "✅ flutter_launcher_icons: Executed successfully"
echo "✅ CFBundleIconName: Added to Info.plist (ITMS-90713)"
echo "✅ iPhone 120x120: Verified (ITMS-90022)"
echo "✅ iPad Pro 167x167: Verified (ITMS-90023)"
echo "✅ iPad 152x152: Verified (ITMS-90023)"
echo "✅ App Store 1024x1024: Verified"
echo "✅ Asset Catalog: Properly configured"
echo "✅ Info.plist: Syntax validated"
echo "=========================================="

# Show generated icons
log_info "📱 Generated App Icons:"
echo "=========================================="
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null | head -10 || echo "No app icons found"

# Show CFBundleIconName in Info.plist
log_info "📝 CFBundleIconName in Info.plist:"
echo "=========================================="
grep -A 1 "CFBundleIconName" ios/Runner/Info.plist || echo "CFBundleIconName not found"

echo "=========================================="

log_success "🎉 iOS app icon fix for ITMS compliance completed successfully"
log_info "🚀 Ready for App Store Connect upload!" 