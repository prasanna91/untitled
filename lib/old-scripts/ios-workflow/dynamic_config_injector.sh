#!/bin/bash
# 🍎 Dynamic iOS Configuration Injector
# Injects all iOS-specific configurations dynamically

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_CONFIG] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting dynamic iOS configuration injection..."

# Step 1: Update Info.plist with dynamic values
log_info "Step 1: Updating Info.plist with dynamic values..."

# Backup original Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    cp ios/Runner/Info.plist ios/Runner/Info.plist.backup
    log_success "Backed up original Info.plist"
fi

# Note: Bundle ID and app name will be set in the new Info.plist creation
if [ -n "$BUNDLE_ID" ]; then
    log_info "Bundle identifier will be set to: $BUNDLE_ID"
fi
if [ -n "$APP_NAME" ]; then
    log_info "App name will be set to: $APP_NAME"
fi

# Step 2: Update pubspec.yaml with dynamic dependencies
log_info "Step 2: Updating pubspec.yaml with dynamic dependencies..."

# Backup original pubspec.yaml
cp pubspec.yaml pubspec.yaml.backup

# Enable Apple Auth if needed
if [ "$IS_APPLE_AUTH" = "true" ]; then
    log_info "Enabling Apple Auth dependency..."
    sed -i '' 's/# sign_in_with_apple: ^6.0.0/sign_in_with_apple: ^6.0.0/g' pubspec.yaml
    log_success "Apple Auth dependency enabled"
fi

# Step 3: Update iOS deployment target
log_info "Step 3: Updating iOS deployment target to 13.0..."

# Update project.pbxproj deployment target
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' ios/Runner.xcodeproj/project.pbxproj
    log_success "Updated iOS deployment target to 13.0"
fi

# Step 4: Generate dynamic permissions in Info.plist
log_info "Step 4: Injecting dynamic permissions..."

# Create permissions section
PERMISSIONS_XML=""

if [ "$IS_CAMERA" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSCameraUsageDescription</key>
	<string>This app needs access to camera to capture photos and videos.</string>"
fi

if [ "$IS_LOCATION" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>This app needs access to location when in use.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>This app needs access to location always and when in use.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>This app needs access to location always.</string>"
fi

if [ "$IS_MIC" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSMicrophoneUsageDescription</key>
	<string>This app needs access to microphone to record audio.</string>"
fi

if [ "$IS_CONTACT" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSContactsUsageDescription</key>
	<string>This app needs access to contacts to manage contact information.</string>"
fi

if [ "$IS_BIOMETRIC" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSFaceIDUsageDescription</key>
	<string>This app uses Face ID for secure authentication.</string>"
fi

if [ "$IS_CALENDAR" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSCalendarsUsageDescription</key>
	<string>This app needs access to calendar to manage events.</string>"
fi

if [ "$IS_STORAGE" = "true" ]; then
    PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSPhotoLibraryUsageDescription</key>
	<string>This app needs access to photo library to save and retrieve images.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>This app needs access to save photos to your photo library.</string>"
fi

# Always add network security for Firebase
PERMISSIONS_XML="${PERMISSIONS_XML}
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<false/>
	</dict>"

# Inject permissions into Info.plist
if [ -n "$PERMISSIONS_XML" ]; then
    log_info "Injecting permissions into Info.plist..."
    log_info "Permissions XML length: ${#PERMISSIONS_XML}"
    
    # Create a backup of the original Info.plist
    cp ios/Runner/Info.plist ios/Runner/Info.plist.original
    
    # Create a new Info.plist with proper structure
    cat > ios/Runner/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION_NAME}</string>
	<key>CFBundleVersion</key>
	<string>${VERSION_CODE}</string>
EOF
    
    # Add permissions if they exist
    if [ -n "$PERMISSIONS_XML" ]; then
        cat >> ios/Runner/Info.plist << EOF
$PERMISSIONS_XML
EOF
    fi
    
    # Close the plist
    cat >> ios/Runner/Info.plist << 'EOF'
</dict>
</plist>
EOF
    
    log_success "Permissions injected into Info.plist"
else
    log_warning "No permissions to inject (PERMISSIONS_XML is empty)"
fi

# Step 5: Update Firebase configuration
log_info "Step 5: Setting up Firebase configuration..."

if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_IOS" ]; then
    log_info "Downloading Firebase iOS configuration..."
    mkdir -p ios/Runner
    curl -fSL "$FIREBASE_CONFIG_IOS" -o ios/Runner/GoogleService-Info.plist
    log_success "Firebase iOS configuration downloaded"
else
    log_warning "Firebase not enabled or config URL not provided"
fi

# Step 6: Update version information
log_info "Step 6: Version information will be set in new Info.plist..."

if [ -n "$VERSION_NAME" ]; then
    log_info "Version name will be set to: $VERSION_NAME"
fi

if [ -n "$VERSION_CODE" ]; then
    log_info "Version code will be set to: $VERSION_CODE"
fi

log_success "Version information will be updated in new Info.plist"

# Step 7: Verify configurations
log_info "Step 7: Verifying configurations..."

# Check if Info.plist was created successfully
if [ -f "ios/Runner/Info.plist" ]; then
    log_success "✅ Info.plist created successfully"
    
    # Check bundle ID
    if grep -q "$BUNDLE_ID" ios/Runner/Info.plist; then
        log_success "✅ Bundle ID correctly set to: $BUNDLE_ID"
    else
        log_error "❌ Bundle ID not found in Info.plist"
    fi

    # Check app name
    if grep -q "$APP_NAME" ios/Runner/Info.plist; then
        log_success "✅ App name correctly set to: $APP_NAME"
    else
        log_error "❌ App name not found in Info.plist"
    fi
    
    # Check version
    if grep -q "$VERSION_NAME" ios/Runner/Info.plist; then
        log_success "✅ Version name correctly set to: $VERSION_NAME"
    else
        log_error "❌ Version name not found in Info.plist"
    fi
else
    log_error "❌ Info.plist was not created"
fi

# Check Firebase config
if [ "$PUSH_NOTIFY" = "true" ]; then
    if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
        log_success "✅ Firebase configuration file exists"
    else
        log_warning "⚠️ Firebase configuration file not found"
    fi
fi

# Check iOS deployment target
if grep -q "IPHONEOS_DEPLOYMENT_TARGET = 13.0" ios/Runner.xcodeproj/project.pbxproj; then
    log_success "✅ iOS deployment target set to 13.0"
else
    log_error "❌ iOS deployment target not updated"
fi

log_success "Dynamic iOS configuration injection completed"
log_info "Configuration Summary:"
log_info "  - Bundle ID: $BUNDLE_ID"
log_info "  - App Name: $APP_NAME"
log_info "  - Version: $VERSION_NAME"
log_info "  - Build: $VERSION_CODE"
log_info "  - Firebase: $PUSH_NOTIFY"
log_info "  - Permissions: Camera($IS_CAMERA), Location($IS_LOCATION), Mic($IS_MIC), Contact($IS_CONTACT), Biometric($IS_BIOMETRIC), Calendar($IS_CALENDAR), Storage($IS_STORAGE)"
log_info "  - OAuth: Google($IS_GOOGLE_AUTH), Apple($IS_APPLE_AUTH)" 