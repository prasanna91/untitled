#!/bin/bash
# 🔧 Fix Generated.xcconfig Before CocoaPods
# Ensures Generated.xcconfig exists before CocoaPods installation

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIX_CONFIG_BEFORE_PODS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Ensuring Generated.xcconfig exists before CocoaPods installation..."

# Step 1: Check if Generated.xcconfig exists
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    log_success "Generated.xcconfig already exists"
    # Verify it has required content
    if grep -q "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig; then
        log_success "Generated.xcconfig has required content"
        exit 0
    else
        log_warning "Generated.xcconfig exists but missing required content"
    fi
else
    log_warning "Generated.xcconfig is missing"
fi

# Step 2: Create Flutter directory if it doesn't exist
mkdir -p ios/Flutter

# Step 3: Run flutter pub get to generate configuration
log_info "Running flutter pub get to generate configuration..."
flutter pub get > /dev/null 2>&1 || {
    log_warning "flutter pub get failed, trying flutter clean first..."
    flutter clean > /dev/null 2>&1 || true
    flutter pub get > /dev/null 2>&1 || {
        log_error "flutter pub get failed after clean"
        exit 1
    }
}

# Step 4: Try to generate iOS configuration
log_info "Attempting to generate iOS configuration..."
flutter build ios --no-codesign --debug > /dev/null 2>&1 || {
    log_warning "flutter build ios failed, creating Generated.xcconfig manually..."
    
    # Create Generated.xcconfig manually
    cat > ios/Flutter/Generated.xcconfig << 'EOF'
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=/usr/local/bin
FLUTTER_APPLICATION_PATH=/Users/builder/clone
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF
    
    log_success "Created Generated.xcconfig manually"
}

# Step 5: Verify the file was created
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    log_success "✅ Generated.xcconfig created successfully"
    
    # Check for required content
    if grep -q "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig; then
        log_success "✅ Generated.xcconfig has required content"
    else
        log_error "❌ Generated.xcconfig missing required content"
        exit 1
    fi
else
    log_error "❌ Generated.xcconfig was not created"
    exit 1
fi

# Step 6: Display the file content for verification
log_info "Generated.xcconfig content:"
cat ios/Flutter/Generated.xcconfig

log_success "Generated.xcconfig is ready for CocoaPods installation" 