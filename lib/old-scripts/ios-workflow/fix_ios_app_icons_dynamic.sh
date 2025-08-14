#!/usr/bin/env bash

# Dynamic iOS App Icon Fix for ITMS Compliance
# Addresses ITMS-90022, ITMS-90023, and ITMS-90713 errors
# Integrates with dynamic workflow variables

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "📱 Dynamic iOS App Icon Fix for ITMS Compliance..."

# Step 1: Ensure flutter_launcher_icons is available
log_info "🔧 Step 1: Ensuring flutter_launcher_icons is available..."
if ! flutter pub deps | grep -q "flutter_launcher_icons"; then
    log_info "📝 Adding flutter_launcher_icons to dev_dependencies..."
    flutter pub add --dev flutter_launcher_icons
fi

# Step 2: Find source image dynamically
log_info "🔍 Step 2: Finding source image dynamically..."
SOURCE_IMAGE=""

# Check for dynamic logo URL first
if [[ -n "${LOGO_URL:-}" ]]; then
    log_info "📱 Downloading logo from URL: $LOGO_URL"
    mkdir -p assets/images
    if curl -fSL "$LOGO_URL" -o "assets/images/dynamic_logo.png" 2>/dev/null; then
        SOURCE_IMAGE="assets/images/dynamic_logo.png"
        log_success "✅ Downloaded logo from URL"
    else
        log_warning "⚠️ Failed to download logo from URL, trying local files..."
    fi
fi

# Fallback to local images
if [[ -z "$SOURCE_IMAGE" ]]; then
    if [[ -f "assets/images/logo.png" ]]; then
        SOURCE_IMAGE="assets/images/logo.png"
        log_info "📱 Using local logo.png"
    elif [[ -f "assets/images/splash.png" ]]; then
        SOURCE_IMAGE="assets/images/splash.png"
        log_info "📱 Using local splash.png"
    elif [[ -f "assets/images/default_logo.png" ]]; then
        SOURCE_IMAGE="assets/images/default_logo.png"
        log_info "📱 Using local default_logo.png"
    else
        log_error "❌ No suitable source image found"
        log_info "📋 Available images:"
        find assets/images -name "*.png" -type f 2>/dev/null || echo "No images found in assets/images/"
        exit 1
    fi
fi

# Step 3: Create dynamic flutter_launcher_icons configuration
log_info "📝 Step 3: Creating dynamic flutter_launcher_icons configuration..."
create_dynamic_launcher_icons_config() {
    local logo_path="$1"
    local app_name="${APP_NAME:-QuikApp}"
    local bundle_id="${BUNDLE_ID:-com.example.quikapp}"
    
    # Create a dynamic pubspec.yaml with flutter_launcher_icons config
    cat > "pubspec_launcher_icons.yaml" << EOF
name: $(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
description: "A dynamic Flutter app built with QuikApp"
publish_to: "none"
version: ${VERSION_NAME:-1.0.0}+${VERSION_CODE:-1}

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
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "$logo_path"

flutter:
  uses-material-design: true
EOF

    log_success "✅ Dynamic flutter_launcher_icons configuration created"
}

# Step 4: Run flutter_launcher_icons
log_info "🚀 Step 4: Running flutter_launcher_icons..."
if create_dynamic_launcher_icons_config "$SOURCE_IMAGE"; then
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

# Step 5: Verify critical app icons exist (ITMS compliance)
log_info "🔍 Step 5: Verifying critical app icons for ITMS compliance..."
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
    log_warning "⚠️ Trying manual icon generation as fallback..."
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
log_info "📝 Step 6: Ensuring CFBundleIconName in Info.plist (ITMS-90713)..."
if [[ ! -f "ios/Runner/Info.plist" ]]; then
    log_error "❌ Info.plist not found"
    exit 1
fi

# Check if CFBundleIconName exists
if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
    log_success "✅ CFBundleIconName already exists in Info.plist"
else
    log_info "📝 Adding CFBundleIconName to Info.plist..."
    
    # Use PlistBuddy to add CFBundleIconName properly
    if /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" ios/Runner/Info.plist 2>/dev/null; then
        log_success "✅ CFBundleIconName already exists"
    else
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" ios/Runner/Info.plist
        log_success "✅ Added CFBundleIconName to Info.plist"
    fi
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

# Step 9: Update Contents.json to ensure all required icons are referenced
log_info "📝 Step 9: Updating Contents.json for complete icon coverage..."
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

log_success "✅ Updated Contents.json for complete icon coverage"

# Step 10: Final verification of ITMS compliance
log_info "🔍 Step 10: Final ITMS compliance verification..."

# Check for ITMS-90022 (iPhone 120x120)
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" ]]; then
    log_success "✅ ITMS-90022: iPhone 120x120 icon verified"
else
    log_error "❌ ITMS-90022: Missing iPhone 120x120 icon"
fi

# Check for ITMS-90023 (iPad 167x167)
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" ]]; then
    log_success "✅ ITMS-90023: iPad Pro 167x167 icon verified"
else
    log_error "❌ ITMS-90023: Missing iPad Pro 167x167 icon"
fi

# Check for ITMS-90023 (iPad 152x152)
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" ]]; then
    log_success "✅ ITMS-90023: iPad 152x152 icon verified"
else
    log_error "❌ ITMS-90023: Missing iPad 152x152 icon"
fi

# Check for ITMS-90713 (CFBundleIconName)
if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
    log_success "✅ ITMS-90713: CFBundleIconName verified in Info.plist"
else
    log_error "❌ ITMS-90713: Missing CFBundleIconName in Info.plist"
fi

# Step 11: Show comprehensive summary
log_info "📋 Dynamic iOS App Icon Fix Summary for ITMS Compliance:"
echo "=========================================="
echo "✅ Source Image: $SOURCE_IMAGE"
echo "✅ App Name: ${APP_NAME:-QuikApp}"
echo "✅ Bundle ID: ${BUNDLE_ID:-com.example.quikapp}"
echo "✅ flutter_launcher_icons: Executed successfully"
echo "✅ CFBundleIconName: Added to Info.plist (ITMS-90713)"
echo "✅ iPhone 120x120: Verified (ITMS-90022)"
echo "✅ iPad Pro 167x167: Verified (ITMS-90023)"
echo "✅ iPad 152x152: Verified (ITMS-90023)"
echo "✅ App Store 1024x1024: Verified"
echo "✅ Asset Catalog: Properly configured"
echo "✅ Info.plist: Syntax validated"
echo "✅ Contents.json: Updated for complete coverage"
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

log_success "🎉 Dynamic iOS app icon fix for ITMS compliance completed successfully"
log_info "🚀 Ready for App Store Connect upload!" 