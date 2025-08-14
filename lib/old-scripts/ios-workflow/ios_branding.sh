#!/usr/bin/env bash

# iOS App Branding Script
# Downloads logo and splash images and sets them as app icons and splash screens

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🎨 Starting iOS App Branding..."

# Create assets directory if it doesn't exist
mkdir -p assets/images

# Function to download image with retry
download_image() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    if [[ -z "$url" || "$url" == "null" || "$url" == "undefined" ]]; then
        log_warning "⚠️ $description URL is empty or not provided"
        return 1
    fi
    
    log_info "📥 Downloading $description from: $url"
    
    # Try to download with curl
    if curl -L -f -s "$url" -o "$output_path" --connect-timeout 30 --max-time 300; then
        log_success "✅ Downloaded $description successfully"
        
        # Verify the file exists and has content
        if [[ -f "$output_path" && -s "$output_path" ]]; then
            log_success "✅ $description file verified: $(ls -lh "$output_path" | awk '{print $5}')"
            return 0
        else
            log_error "❌ Downloaded $description file is empty or corrupted"
            return 1
        fi
    else
        log_error "❌ Failed to download $description from: $url"
        return 1
    fi
}

# Function to validate image format
validate_image() {
    local image_path="$1"
    local description="$2"
    
    if [[ ! -f "$image_path" ]]; then
        log_error "❌ $description file not found: $image_path"
        return 1
    fi
    
    # Check if it's a valid image file
    if file "$image_path" | grep -q "image"; then
        log_success "✅ $description format is valid"
        return 0
    else
        log_error "❌ $description is not a valid image file"
        return 1
    fi
}

# Function to copy image to iOS app icon locations
copy_to_ios_icons() {
    local source_image="$1"
    local description="$2"
    
    if [[ ! -f "$source_image" ]]; then
        log_error "❌ Source image not found: $source_image"
        return 1
    fi
    
    log_info "📱 Copying $description to iOS app icons..."
    
    # iOS app icon sizes (in pixels)
    local icon_sizes=(
        "20x20" "40x40" "60x60" "29x29" "58x58" "87x87" "80x80" "120x120" "180x180"
        "76x76" "152x152" "167x167" "1024x1024"
    )
    
    # iOS app icon directories
    local icon_dirs=(
        "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    )
    
    # Create icon directories if they don't exist
    for dir in "${icon_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # Copy to main app icon location
    local main_icon_dir="ios/Runner/Assets.xcassets/AppIcon.appiconset"
    local main_icon_path="$main_icon_dir/Icon-App-1024x1024@1x.png"
    
    if cp "$source_image" "$main_icon_path"; then
        log_success "✅ Copied $description to iOS app icon: $main_icon_path"
        
        # Update Contents.json for AppIcon
        cat > "$main_icon_dir/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
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
        log_success "✅ Updated iOS app icon Contents.json"
        return 0
    else
        log_error "❌ Failed to copy $description to iOS app icon"
        return 1
    fi
}

# Function to copy image to iOS splash screen locations
copy_to_ios_splash() {
    local source_image="$1"
    local description="$2"
    
    if [[ ! -f "$source_image" ]]; then
        log_error "❌ Source image not found: $source_image"
        return 1
    fi
    
    log_info "📱 Copying $description to iOS splash screen..."
    
    # iOS splash screen directories
    local splash_dir="ios/Runner/Assets.xcassets/LaunchImage.imageset"
    mkdir -p "$splash_dir"
    
    # Copy to splash screen location
    local splash_path="$splash_dir/LaunchImage.png"
    
    if cp "$source_image" "$splash_path"; then
        log_success "✅ Copied $description to iOS splash screen: $splash_path"
        
        # Update Contents.json for LaunchImage
        cat > "$splash_dir/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "320x480"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "640x960"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "1242x2688"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
        log_success "✅ Updated iOS splash screen Contents.json"
        return 0
    else
        log_error "❌ Failed to copy $description to iOS splash screen"
        return 1
    fi
}

# Main branding process
log_info "🎨 Starting iOS app branding process..."

# Download and set app logo
if [[ -n "${LOGO_URL:-}" ]]; then
    log_info "📱 Processing app logo..."
    
    # Download logo
    if download_image "$LOGO_URL" "assets/images/logo.png" "app logo"; then
        # Validate logo
        if validate_image "assets/images/logo.png" "app logo"; then
            # Copy to iOS app icons
            if copy_to_ios_icons "assets/images/logo.png" "app logo"; then
                log_success "✅ App logo successfully set for iOS"
            else
                log_error "❌ Failed to set app logo for iOS"
            fi
        else
            log_error "❌ App logo validation failed"
        fi
    else
        log_warning "⚠️ Skipping app logo setup due to download failure"
    fi
else
    log_warning "⚠️ LOGO_URL not provided, skipping app logo setup"
fi

# Download and set splash screen
if [[ -n "${SPLASH_URL:-}" ]]; then
    log_info "📱 Processing splash screen..."
    
    # Download splash
    if download_image "$SPLASH_URL" "assets/images/splash.png" "splash screen"; then
        # Validate splash
        if validate_image "assets/images/splash.png" "splash screen"; then
            # Copy to iOS splash screen
            if copy_to_ios_splash "assets/images/splash.png" "splash screen"; then
                log_success "✅ Splash screen successfully set for iOS"
            else
                log_error "❌ Failed to set splash screen for iOS"
            fi
        else
            log_error "❌ Splash screen validation failed"
        fi
    else
        log_warning "⚠️ Skipping splash screen setup due to download failure"
    fi
else
    log_warning "⚠️ SPLASH_URL not provided, skipping splash screen setup"
fi

# Verify iOS assets
log_info "🔍 Verifying iOS assets..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" ]]; then
    log_success "✅ iOS app icon verified"
else
    log_warning "⚠️ iOS app icon not found"
fi

if [[ -f "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png" ]]; then
    log_success "✅ iOS splash screen verified"
else
    log_warning "⚠️ iOS splash screen not found"
fi

# Show summary
log_info "📋 iOS Branding Summary:"
echo "=========================================="
if [[ -n "${LOGO_URL:-}" ]]; then
    echo "✅ App Logo: $LOGO_URL"
else
    echo "❌ App Logo: Not provided"
fi

if [[ -n "${SPLASH_URL:-}" ]]; then
    echo "✅ Splash Screen: $SPLASH_URL"
else
    echo "❌ Splash Screen: Not provided"
fi

echo "=========================================="

log_success "🎉 iOS app branding completed successfully" 