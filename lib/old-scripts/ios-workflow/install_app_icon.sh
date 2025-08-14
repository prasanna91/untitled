#!/bin/bash
# 🎨 App Icon Installation Script for iOS Workflow
# Downloads and installs app icons for iOS builds

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

# Function to safely get environment variable with fallback
get_env_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        printf "%s" "$value"
    else
        printf "%s" "$fallback"
    fi
}

# Get logo URL from environment
LOGO_URL=$(get_env_var "LOGO_URL" "")

if [ -z "$LOGO_URL" ]; then
    log_warning "LOGO_URL not provided, skipping app icon installation"
    exit 0
fi

log_info "Starting app icon installation..."

# Verify we're in the right directory and environment
log_info "Current directory: $(pwd)"
log_info "Flutter version: $(flutter --version 2>/dev/null | head -1 || echo 'Flutter not available')"
log_info "iOS project exists: $([ -d ios/Runner ] && echo 'Yes' || echo 'No')"

# COMPLETE CLEANUP: Remove all old assets and ensure fresh download
log_info "🧹 Performing complete cleanup of old assets..."

# Remove old logo file
if [ -f assets/images/logo.png ]; then
    rm -f assets/images/logo.png
    log_success "Deleted old logo.png"
else
    log_info "No old logo.png found"
fi

# Remove any other image files in assets/images
log_info "Cleaning up any other image files in assets/images..."
find assets/images -name "*.png" -type f -delete 2>/dev/null || true
find assets/images -name "*.jpg" -type f -delete 2>/dev/null || true
find assets/images -name "*.jpeg" -type f -delete 2>/dev/null || true
log_success "Cleaned up all old image files"

# Ensure assets/images directory exists
mkdir -p assets/images

echo "🚀 Started: Downloading logo from $LOGO_URL"

# Create assets directory
mkdir -p assets/images/

# Try downloading with SSL certificate check first (silent test)
wget --spider --quiet "$LOGO_URL"
if [ $? -ne 0 ]; then
    echo "⚠️ SSL verification failed. Retrying with --no-check-certificate..."
    WGET_OPTS="--no-check-certificate"
else
    WGET_OPTS=""
fi

# Attempt actual download
wget $WGET_OPTS -O assets/images/logo.png "$LOGO_URL"

# Verify fresh logo download
log_info "Verifying fresh logo download..."
if [ ! -f assets/images/logo.png ]; then
    log_warning "Failed to download logo from $LOGO_URL"
    log_info "Creating a default placeholder icon..."
    
    # Create a simple default icon using ImageMagick or sips
    if command -v convert >/dev/null 2>&1; then
        # Use ImageMagick to create a default icon
        convert -size 1024x1024 xc:#667eea -fill white -gravity center -pointsize 200 -annotate 0 "Q" assets/images/logo.png
        log_success "Created default icon using ImageMagick"
    elif command -v sips >/dev/null 2>&1; then
        # Create a simple colored square using sips
        echo "Creating default icon with sips..."
        # Create a 1024x1024 PNG with a solid color
        sips -s format png --setProperty format png --setProperty formatOptions default assets/images/logo.png --out assets/images/logo.png 2>/dev/null || {
            # If that fails, try to create a simple colored square
            echo "Creating fallback icon..."
            # This is a very basic fallback - in practice, you'd want a proper default icon
            cp assets/images/default_logo.png assets/images/logo.png 2>/dev/null || {
                log_error "No default logo available and download failed"
                exit 1
            }
        }
    else
        log_error "No image manipulation tools available and download failed"
        exit 1
    fi
else
    # Verify the downloaded file is not empty and is valid
    if [ ! -s assets/images/logo.png ]; then
        log_error "Downloaded logo file is empty"
        rm -f assets/images/logo.png
        exit 1
    fi
    
    log_success "✅ Fresh logo downloaded successfully"
    log_info "Logo file size: $(ls -lh assets/images/logo.png | awk '{print $5}')"
fi
fi

# Verify the downloaded image is valid
if command -v file >/dev/null 2>&1; then
    IMAGE_TYPE=$(file -b --mime-type assets/images/logo.png 2>/dev/null || echo "unknown")
    if [[ "$IMAGE_TYPE" != image/* ]]; then
        log_error "Downloaded file is not a valid image: $IMAGE_TYPE"
        exit 1
    fi
    log_success "Downloaded image type: $IMAGE_TYPE"
fi

# Get image dimensions if possible
if command -v identify >/dev/null 2>&1; then
    DIMENSIONS=$(identify -format "%wx%h" assets/images/logo.png 2>/dev/null || echo "unknown")
    log_info "Logo dimensions: $DIMENSIONS"
    
    # Check if image is square (required for app icons)
    if [[ "$DIMENSIONS" =~ ^([0-9]+)x\1$ ]]; then
        log_success "Logo is square, perfect for app icon"
    else
        log_warning "Logo is not square ($DIMENSIONS), may cause icon display issues"
    fi
fi

# Create iOS app icon directory structure
log_info "Creating iOS app icon directory structure..."

# COMPLETE CLEANUP: Remove entire AppIcon.appiconset directory and recreate
log_info "🧹 Performing complete cleanup of previous icons..."
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
    log_info "Removing entire AppIcon.appiconset directory..."
    rm -rf ios/Runner/Assets.xcassets/AppIcon.appiconset
    log_success "Removed old AppIcon.appiconset directory"
fi

# Create fresh directory structure
log_info "Creating fresh AppIcon.appiconset directory..."
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset
log_success "Created fresh AppIcon.appiconset directory"

# Additional cleanup: Remove any leftover icon files in parent directories
log_info "Cleaning up any leftover icon files..."
find ios/Runner/Assets.xcassets -name "*.png" -type f -delete 2>/dev/null || true
find ios/Runner/Assets.xcassets -name "*.jpg" -type f -delete 2>/dev/null || true
find ios/Runner/Assets.xcassets -name "*.jpeg" -type f -delete 2>/dev/null || true
log_success "Cleaned up all leftover image files"

# Verify complete cleanup
log_info "Verifying complete cleanup..."
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
    ICON_COUNT=$(find ios/Runner/Assets.xcassets/AppIcon.appiconset -name "*.png" -type f 2>/dev/null | wc -l)
    if [ "$ICON_COUNT" -eq 0 ]; then
        log_success "✅ Directory is completely clean (0 old icons found)"
    else
        log_warning "⚠️ Found $ICON_COUNT old icons, forcing removal..."
        rm -f ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
        log_success "Forced removal of remaining old icons"
    fi
else
    log_error "❌ AppIcon.appiconset directory not found after cleanup"
    exit 1
fi

# Generate iOS app icons
log_info "Generating iOS app icons..."

# iOS icon sizes with proper naming - including ALL required sizes for App Store
declare -A icon_sizes=(
    ["20x20@1x"]="Icon-App-20x20@1x.png"
    ["20x20@2x"]="Icon-App-20x20@2x.png"
    ["20x20@3x"]="Icon-App-20x20@3x.png"
    ["29x29@1x"]="Icon-App-29x29@1x.png"
    ["29x29@2x"]="Icon-App-29x29@2x.png"
    ["29x29@3x"]="Icon-App-29x29@3x.png"
    ["40x40@1x"]="Icon-App-40x40@1x.png"
    ["40x40@2x"]="Icon-App-40x40@2x.png"
    ["40x40@3x"]="Icon-App-40x40@3x.png"
    ["60x60@2x"]="Icon-App-60x60@2x.png"
    ["60x60@3x"]="Icon-App-60x60@3x.png"
    ["76x76@1x"]="Icon-App-76x76@1x.png"
    ["76x76@2x"]="Icon-App-76x76@2x.png"
    ["83.5x83.5@2x"]="Icon-App-83.5x83.5@2x.png"
    ["1024x1024@1x"]="Icon-App-1024x1024@1x.png"
    # Additional required sizes for App Store validation
    ["120x120@1x"]="Icon-App-120x120@1x.png"
    ["152x152@1x"]="Icon-App-152x152@1x.png"
    ["167x167@1x"]="Icon-App-167x167@1x.png"
)

# Function to generate icon with multiple fallback methods
generate_icon() {
    local size="$1"
    local filename="$2"
    local output_path="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
    
    # Extract dimensions from size string
    if [[ "$size" =~ ^([0-9]+)x([0-9]+)@[0-9]+x$ ]]; then
        local width="${BASH_REMATCH[1]}"
        local height="${BASH_REMATCH[2]}"
        
        log_info "Generating $size icon ($width x $height) -> $filename"
        
        # Method 1: Standard sips resize
        if sips -z "$height" "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Generated $filename (method 1)"
            return 0
        fi
        
        # Method 2: sips with format specification
        if sips -s format png --resampleHeightWidth "$height" "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Generated $filename (method 2)"
            return 0
        fi
        
        # Method 3: sips with crop to center
        if sips -c "$height" "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Generated $filename (method 3)"
            return 0
        fi
        
        # Method 4: sips with fit
        if sips -Z "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Generated $filename (method 4)"
            return 0
        fi
        
        # Method 5: Copy original and let iOS handle scaling (fallback)
        if cp assets/images/logo.png "$output_path" >/dev/null 2>&1; then
            log_warning "Copied original image for $filename (fallback method)"
            return 0
        fi
        
        log_error "Failed to generate $filename with all methods"
        return 1
    else
        log_error "Invalid size format: $size"
        return 1
    fi
}

# Generate each icon size with retry logic
for size in "${!icon_sizes[@]}"; do
    filename="${icon_sizes[$size]}"
    
    # Try up to 3 times to generate each icon
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        if generate_icon "$size" "$filename"; then
            break
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log_warning "Retrying $filename generation (attempt $retry_count/$max_retries)..."
                sleep 1
            else
                log_error "Failed to generate $filename after $max_retries attempts"
                exit 1
            fi
        fi
    done
done

# Create Contents.json for AppIcon.appiconset
log_info "Creating Contents.json for AppIcon.appiconset..."
cat > ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
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
    },
    {
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "120x120",
      "filename" : "Icon-App-120x120@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "152x152",
      "filename" : "Icon-App-152x152@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "167x167",
      "filename" : "Icon-App-167x167@1x.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

log_success "Created Contents.json for AppIcon.appiconset"

# Update Info.plist to include CFBundleIconName
log_info "Updating Info.plist with CFBundleIconName..."
PLIST_PATH="ios/Runner/Info.plist"

# Add CFBundleIconName if it doesn't exist
if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$PLIST_PATH" 2>/dev/null; then
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$PLIST_PATH"
    log_success "Added CFBundleIconName to Info.plist"
else
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "$PLIST_PATH"
    log_success "Updated CFBundleIconName in Info.plist"
fi

# Verify all required icon files are present
log_info "Verifying all required icon files..."
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
MISSING_ICONS=()

# Check for all required icon files
for size in "${!icon_sizes[@]}"; do
    filename="${icon_sizes[$size]}"
    if [ ! -f "$ICON_DIR/$filename" ]; then
        MISSING_ICONS+=("$filename")
        log_warning "Missing icon: $filename"
    else
        # Verify file size is not zero
        if [ ! -s "$ICON_DIR/$filename" ]; then
            MISSING_ICONS+=("$filename (empty file)")
            log_warning "Empty icon file: $filename"
        else
            log_success "Icon file verified: $filename"
        fi
    fi
done

if [ ${#MISSING_ICONS[@]} -gt 0 ]; then
    log_error "Missing or invalid ${#MISSING_ICONS[@]} icon files:"
    for icon in "${MISSING_ICONS[@]}"; do
        echo "  - $icon"
    done
    log_error "App icon installation incomplete"
    exit 1
else
    log_success "All required icon files are present and valid"
fi

# Display icon file sizes for verification
log_info "Icon file sizes:"
ls -la "$ICON_DIR"/*.png | head -10

# Debug: Check if sips is available and working
log_info "Debug: Checking sips availability..."
if command -v sips >/dev/null 2>&1; then
    log_success "sips command is available"
    sips --version 2>/dev/null || log_warning "sips version check failed"
else
    log_error "sips command not found - this is required for icon generation"
    exit 1
fi

# Debug: Check source image
log_info "Debug: Checking source image..."
if [ -f assets/images/logo.png ]; then
    log_success "Source image exists: assets/images/logo.png"
    ls -la assets/images/logo.png
else
    log_error "Source image missing: assets/images/logo.png"
    exit 1
fi

# Debug: Check output directory
log_info "Debug: Checking output directory..."
if [ -d "$ICON_DIR" ]; then
    log_success "Output directory exists: $ICON_DIR"
    ls -la "$ICON_DIR"
else
    log_error "Output directory missing: $ICON_DIR"
    exit 1
fi

# Force rebuild the iOS project to ensure icons are included
log_info "Forcing iOS project rebuild to include icons..."
cd ios
xcodebuild clean -project Runner.xcodeproj -scheme Runner >/dev/null 2>&1 || log_warning "xcodebuild clean failed"
cd ..

# Update Flutter dependencies
flutter pub get
echo "✅ Completed: App icon installation"

log_success "App icon installation completed successfully" 