#!/bin/bash
# 🎨 Asset Download Script for iOS Workflow
# Downloads and configures all assets for the iOS app

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ASSETS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

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

# Set asset URLs
export LOGO_URL=$(get_api_var "LOGO_URL" "")
export SPLASH_URL=$(get_api_var "SPLASH_URL" "")
export SPLASH_BG_URL=$(get_api_var "SPLASH_BG_URL" "")
export SPLASH_BG_COLOR=$(get_api_var "SPLASH_BG_COLOR" "#FFFFFF")
export SPLASH_TAGLINE=$(get_api_var "SPLASH_TAGLINE" "")
export SPLASH_TAGLINE_COLOR=$(get_api_var "SPLASH_TAGLINE_COLOR" "#000000")

# Create asset directories
mkdir -p assets/icons
mkdir -p assets/images
mkdir -p assets/fonts
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset
mkdir -p ios/Runner/Assets.xcassets/LaunchImage.imageset

# Function to download and process image
download_image() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    if [ -n "$url" ]; then
        log "Downloading $description from: $url"
        if curl -L -o "$output_path" "$url" 2>/dev/null; then
            log_success "$description downloaded successfully"
            
            # Get image dimensions
            if command -v identify >/dev/null 2>&1; then
                DIMENSIONS=$(identify -format "%wx%h" "$output_path" 2>/dev/null || echo "unknown")
                log "Image dimensions: $DIMENSIONS"
            fi
            
            return 0
        else
            log_warning "Failed to download $description"
            return 1
        fi
    else
        log_warning "URL not provided for $description"
        return 1
    fi
}

# Function to generate iOS app icons with all required sizes
generate_ios_icons() {
    local source_image="$1"
    local app_name="$2"
    
    if [ ! -f "$source_image" ]; then
        log_warning "Source image not found: $source_image"
        return 1
    fi
    
    log "Generating iOS app icons from: $source_image"
    
    # iOS icon sizes with proper naming
    local icon_sizes=(
        "20x20@1x:Icon-App-20x20@1x.png"
        "20x20@2x:Icon-App-20x20@2x.png"
        "20x20@3x:Icon-App-20x20@3x.png"
        "29x29@1x:Icon-App-29x29@1x.png"
        "29x29@2x:Icon-App-29x29@2x.png"
        "29x29@3x:Icon-App-29x29@3x.png"
        "40x40@1x:Icon-App-40x40@1x.png"
        "40x40@2x:Icon-App-40x40@2x.png"
        "40x40@3x:Icon-App-40x40@3x.png"
        "60x60@2x:Icon-App-60x60@2x.png"
        "60x60@3x:Icon-App-60x60@3x.png"
        "76x76@1x:Icon-App-76x76@1x.png"
        "76x76@2x:Icon-App-76x76@2x.png"
        "83.5x83.5@2x:Icon-App-83.5x83.5@2x.png"
        "1024x1024@1x:Icon-App-1024x1024@1x.png"
    )
    
    # Generate each size
    for icon_info in "${icon_sizes[@]}"; do
        local size=$(echo "$icon_info" | cut -d':' -f1)
        local filename=$(echo "$icon_info" | cut -d':' -f2)
        local width=$(echo "$size" | cut -d'x' -f1)
        local height=$(echo "$size" | cut -d'x' -f2)
        local output_file="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
        
        if command -v convert >/dev/null 2>&1; then
            if convert "$source_image" -resize "${width}x${height}" -background transparent -gravity center -extent "${width}x${height}" "$output_file" 2>/dev/null; then
                log "Generated icon: $filename (${width}x${height})"
            else
                log_warning "Failed to generate icon: $filename"
            fi
        else
            log_warning "ImageMagick not available, copying source image"
            cp "$source_image" "$output_file" 2>/dev/null || log_warning "Failed to copy source image"
        fi
    done
    
    # Create Contents.json for AppIcon
    cat > ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json <<EOF
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60",
      "filename" : "Icon-App-60x60@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60",
      "filename" : "Icon-App-60x60@3x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76",
      "filename" : "Icon-App-76x76@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5",
      "filename" : "Icon-App-83.5x83.5@2x.png"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024",
      "filename" : "Icon-App-1024x1024@1x.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    
    log_success "iOS app icons generated successfully"
}

# Function to generate splash screen with background
generate_splash_screen() {
    local source_image="$1"
    local bg_color="$2"
    local tagline="$3"
    local tagline_color="$4"
    
    if [ ! -f "$source_image" ]; then
        log_warning "Source splash image not found: $source_image"
        return 1
    fi
    
    log "Generating splash screen with background color: $bg_color"
    
    # Create splash screen with background
    local splash_output="ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png"
    local splash_output_2x="ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png"
    local splash_output_3x="ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png"
    
    if command -v convert >/dev/null 2>&1; then
        # Create splash screen with background color and logo
        # iPhone 6/7/8 size (750x1334)
        if convert -size 750x1334 xc:"$bg_color" \
            "$source_image" -geometry +375+500 -composite \
            "$splash_output" 2>/dev/null; then
            log "Generated splash screen: $splash_output"
        else
            log_warning "Failed to generate splash screen, copying source image"
            cp "$source_image" "$splash_output" 2>/dev/null || log_warning "Failed to copy source image"
        fi
        
        # iPhone 6/7/8 Plus size (1242x2208)
        if convert -size 1242x2208 xc:"$bg_color" \
            "$source_image" -geometry +621+800 -composite \
            "$splash_output_2x" 2>/dev/null; then
            log "Generated splash screen 2x: $splash_output_2x"
        else
            cp "$source_image" "$splash_output_2x" 2>/dev/null || log_warning "Failed to copy source image"
        fi
        
        # iPhone X/XS/11 Pro size (1125x2436)
        if convert -size 1125x2436 xc:"$bg_color" \
            "$source_image" -geometry +562+900 -composite \
            "$splash_output_3x" 2>/dev/null; then
            log "Generated splash screen 3x: $splash_output_3x"
        else
            cp "$source_image" "$splash_output_3x" 2>/dev/null || log_warning "Failed to copy source image"
        fi
    else
        log_warning "ImageMagick not available, copying source image"
        cp "$source_image" "$splash_output" 2>/dev/null || log_warning "Failed to copy source image"
        cp "$source_image" "$splash_output_2x" 2>/dev/null || log_warning "Failed to copy source image"
        cp "$source_image" "$splash_output_3x" 2>/dev/null || log_warning "Failed to copy source image"
    fi
    
    # Create Contents.json for LaunchImage
    cat > ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json <<EOF
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x",
      "filename" : "LaunchImage.png"
    },
    {
      "idiom" : "universal",
      "scale" : "2x",
      "filename" : "LaunchImage@2x.png"
    },
    {
      "idiom" : "universal",
      "scale" : "3x",
      "filename" : "LaunchImage@3x.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    
    log_success "Splash screen assets generated successfully"
}

# Step 1: Download App Logo
log_info "Step 1: Download App Logo"
if download_image "$LOGO_URL" "assets/icons/app_icon.png" "app logo"; then
    # Generate iOS app icons
    generate_ios_icons "assets/icons/app_icon.png" "$APP_NAME"
else
    log_warning "Using default app icon"
    # Copy default icon if available
    if [ -f "assets/images/default_logo.png" ]; then
        cp "assets/images/default_logo.png" "assets/icons/app_icon.png"
        generate_ios_icons "assets/icons/app_icon.png" "$APP_NAME"
    else
        # Create a simple placeholder logo
        log "Creating placeholder logo"
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > assets/icons/app_icon.png 2>/dev/null || {
            printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc```\x00\x00\x00\x04\x00\x01\xf5\xd7\xd4\xc2\x00\x00\x00\x00IEND\xaeB`\x82' > assets/icons/app_icon.png
        }
        generate_ios_icons "assets/icons/app_icon.png" "$APP_NAME"
    fi
fi

# Step 2: Download Splash Screen
log_info "Step 2: Download Splash Screen"
if download_image "$SPLASH_URL" "assets/images/splash.png" "splash screen"; then
    # Generate splash screen
    generate_splash_screen "assets/images/splash.png" "$SPLASH_BG_COLOR" "$SPLASH_TAGLINE" "$SPLASH_TAGLINE_COLOR"
else
    log_warning "Using default splash screen"
    # Copy default splash if available
    if [ -f "assets/images/splash.png" ]; then
        generate_splash_screen "assets/images/splash.png" "$SPLASH_BG_COLOR" "$SPLASH_TAGLINE" "$SPLASH_TAGLINE_COLOR"
    else
        # Use logo as splash if available
        if [ -f "assets/icons/app_icon.png" ]; then
            cp "assets/icons/app_icon.png" "assets/images/splash.png"
            generate_splash_screen "assets/images/splash.png" "$SPLASH_BG_COLOR" "$SPLASH_TAGLINE" "$SPLASH_TAGLINE_COLOR"
        else
            log_warning "No splash image available"
        fi
    fi
fi

# Step 3: Download Background Image (if provided)
log_info "Step 3: Download Background Image"
if [ -n "$SPLASH_BG_URL" ]; then
    download_image "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background"
fi

# Step 4: Update pubspec.yaml for Dart assets
log_info "Step 4: Update pubspec.yaml for Dart assets"
log "Configuring asset paths in pubspec.yaml..."

# Create assets section in pubspec.yaml if it doesn't exist
if ! grep -q "assets:" pubspec.yaml 2>/dev/null; then
    # Add assets section before dependencies
    sed -i.bak '/dependencies:/i\
  assets:\
    - assets/icons/\
    - assets/images/\
    - assets/fonts/\
' pubspec.yaml
    log_success "Added assets section to pubspec.yaml"
fi

# Step 5: Create asset mapping for Dart
log_info "Step 5: Create asset mapping for Dart"
log "Creating asset mapping configuration..."

# Create asset mapping file
cat > lib/config/asset_mapping.dart <<EOF
// GENERATED FILE: DO NOT EDIT
// Asset mapping configuration for iOS workflow

class AssetMapping {
  // App Icons
  static const String appIcon = 'assets/icons/app_icon.png';
  static const String defaultLogo = 'assets/images/default_logo.png';
  
  // Splash Screens
  static const String splashScreen = 'assets/images/splash.png';
  static const String splashBackground = 'assets/images/splash_bg.png';
  
  // Background Colors
  static const String splashBgColor = '$SPLASH_BG_COLOR';
  static const String splashTaglineColor = '$SPLASH_TAGLINE_COLOR';
  
  // Taglines
  static const String splashTagline = '$SPLASH_TAGLINE';
  
  // Asset URLs (for reference)
  static const String logoUrl = '$LOGO_URL';
  static const String splashUrl = '$SPLASH_URL';
  static const String splashBgUrl = '$SPLASH_BG_URL';
}
EOF

log_success "Asset mapping configuration created"

# Step 6: Validate Assets
log_info "Step 6: Validate Assets"
log "Validating downloaded assets..."

# Check if required assets exist
REQUIRED_ASSETS=(
    "assets/icons/app_icon.png"
    "assets/images/splash.png"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png"
)

MISSING_ASSETS=()
for asset in "${REQUIRED_ASSETS[@]}"; do
    if [ ! -f "$asset" ]; then
        MISSING_ASSETS+=("$asset")
    fi
done

if [ ${#MISSING_ASSETS[@]} -gt 0 ]; then
    log_warning "Missing assets: ${MISSING_ASSETS[*]}"
else
    log_success "All required assets are present"
fi

# Step 7: Create Asset Summary
log_info "Step 7: Create Asset Summary"
log "Creating asset summary..."

cat > output/ios/ASSET_SUMMARY.txt <<EOF
Asset Download Summary
=====================

Downloaded Assets:
- App Icon: $([ -f "assets/icons/app_icon.png" ] && echo "✅ Downloaded" || echo "❌ Missing")
- Splash Screen: $([ -f "assets/images/splash.png" ] && echo "✅ Downloaded" || echo "❌ Missing")
- iOS App Icons: $([ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" ] && echo "✅ Generated" || echo "❌ Missing")
- iOS Launch Image: $([ -f "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png" ] && echo "✅ Generated" || echo "❌ Missing")

Asset URLs:
- Logo URL: $LOGO_URL
- Splash URL: $SPLASH_URL
- Splash Background URL: $SPLASH_BG_URL

Configuration:
- Splash Background Color: $SPLASH_BG_COLOR
- Splash Tagline Color: $SPLASH_TAGLINE_COLOR
- Splash Tagline: $SPLASH_TAGLINE

Dart Asset Mapping:
- Asset mapping file: lib/config/asset_mapping.dart
- Assets configured in pubspec.yaml

Download Time: $(date)
EOF

log_success "Asset download and configuration completed!"
log "Asset summary available in: output/ios/ASSET_SUMMARY.txt" 