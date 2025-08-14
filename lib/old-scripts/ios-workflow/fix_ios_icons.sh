#!/usr/bin/env bash

# Fix iOS App Icons for App Store Upload
# Generates all required icon sizes and updates Info.plist

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "📱 Fixing iOS App Icons for App Store Upload..."

# Check if we have a source image
SOURCE_IMAGE=""
if [[ -f "assets/images/logo.png" ]]; then
    SOURCE_IMAGE="assets/images/logo.png"
    log_info "📱 Using logo.png as source image"
elif [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" ]]; then
    SOURCE_IMAGE="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
    log_info "📱 Using existing app icon as source image"
else
    log_error "❌ No source image found for icon generation"
    log_info "📋 Available images:"
    find . -name "*.png" -type f | head -10
    exit 1
fi

# Function to check if sips is available (macOS image processing)
check_sips() {
    if ! command -v sips &> /dev/null; then
        log_error "❌ sips command not available (required for icon generation)"
        return 1
    fi
    return 0
}

# Function to generate icon with specific size
generate_icon() {
    local source="$1"
    local output="$2"
    local size="$3"
    
    # Create output directory
    mkdir -p "$(dirname "$output")"
    
    # Generate icon using sips
    if sips -z "$size" "$size" "$source" --out "$output" > /dev/null 2>&1; then
        log_success "✅ Generated $size icon: $output"
        return 0
    else
        log_error "❌ Failed to generate $size icon: $output"
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

# Main icon generation process
log_info "🎨 Starting iOS icon generation..."

# Check if sips is available
if ! check_sips; then
    log_error "❌ Cannot generate icons without sips command"
    exit 1
fi

# Define all required iOS icon sizes
ICON_SIZES=(
    "Icon-App-20x20@1x.png:20"
    "Icon-App-20x20@2x.png:40"
    "Icon-App-20x20@3x.png:60"
    "Icon-App-29x29@1x.png:29"
    "Icon-App-29x29@2x.png:58"
    "Icon-App-29x29@3x.png:87"
    "Icon-App-40x40@1x.png:40"
    "Icon-App-40x40@2x.png:80"
    "Icon-App-40x40@3x.png:120"
    "Icon-App-60x60@2x.png:120"
    "Icon-App-60x60@3x.png:180"
    "Icon-App-76x76@1x.png:76"
    "Icon-App-76x76@2x.png:152"
    "Icon-App-83.5x83.5@2x.png:167"
    "Icon-App-1024x1024@1x.png:1024"
)

# Create app icon directory
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

log_info "📱 Generating iOS app icons..."

# Generate all required icon sizes
SUCCESS_COUNT=0
TOTAL_COUNT=0

for icon_spec in "${ICON_SIZES[@]}"; do
    filename="${icon_spec%:*}"
    size="${icon_spec#*:}"
    output_path="$ICON_DIR/$filename"
    
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    if generate_icon "$SOURCE_IMAGE" "$output_path" "$size"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
done

log_info "📊 Icon generation summary: $SUCCESS_COUNT/$TOTAL_COUNT icons generated successfully"

# Update Contents.json for AppIcon
log_info "📝 Updating AppIcon Contents.json..."
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

log_success "✅ Updated AppIcon Contents.json"

# Update Info.plist with CFBundleIconName
if update_info_plist; then
    log_success "✅ Info.plist updated with CFBundleIconName"
else
    log_error "❌ Failed to update Info.plist"
    exit 1
fi

# Verify critical icons exist
log_info "🔍 Verifying critical app icons..."

CRITICAL_ICONS=(
    "Icon-App-60x60@2x.png"  # iPhone 120x120
    "Icon-App-76x76@2x.png"  # iPad 152x152
    "Icon-App-83.5x83.5@2x.png"  # iPad Pro 167x167
    "Icon-App-1024x1024@1x.png"  # App Store 1024x1024
)

MISSING_ICONS=()
for icon in "${CRITICAL_ICONS[@]}"; do
    if [[ ! -f "$ICON_DIR/$icon" ]]; then
        MISSING_ICONS+=("$icon")
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "❌ Missing critical app icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "   - $icon"
    done
    exit 1
else
    log_success "✅ All critical app icons verified"
fi

# Show icon summary
log_info "📋 iOS App Icon Summary:"
echo "=========================================="
echo "✅ Source Image: $SOURCE_IMAGE"
echo "✅ Icons Generated: $SUCCESS_COUNT/$TOTAL_COUNT"
echo "✅ CFBundleIconName: Added to Info.plist"
echo "✅ Contents.json: Updated for AppIcon"
echo "=========================================="

# List generated icons
log_info "📱 Generated app icons:"
ls -la "$ICON_DIR"/*.png | head -10

log_success "🎉 iOS app icons fixed successfully for App Store upload" 