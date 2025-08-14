#!/bin/bash
# 🚀 iOS Workflow Fix Script
# Fixes common iOS build issues and ensures proper Flutter configuration

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIX] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

log "🚀 Starting iOS Workflow Fix..."

# Ensure we're in the project root
cd "$(dirname "$0")/../.."

# Step 1: Clean Flutter project
log_info "Step 1: Cleaning Flutter project..."
flutter clean
flutter pub get

# Step 2: Fix iOS configuration files
log_info "Step 2: Fixing iOS configuration files..."

# Ensure iOS directory exists
if [ ! -d "ios" ]; then
    log_error "iOS directory not found"
    exit 1
fi

cd ios

# Ensure Flutter directory exists
if [ ! -d "Flutter" ]; then
    mkdir -p Flutter
    log_success "Created Flutter directory"
fi

# Step 3: Generate Flutter configuration files
log_info "Step 3: Generating Flutter configuration files..."

# First attempt: Try to generate configuration
log "🔄 Attempting Flutter iOS configuration generation..."
flutter build ios --no-codesign --debug --verbose || {
    log_warning "First attempt failed, trying alternative approach..."
    cd ..
    flutter clean
    flutter pub get
    cd ios
    flutter build ios --no-codesign --debug --verbose || {
        log_error "Failed to generate Flutter configuration files"
        exit 1
    }
}

# Step 4: Verify and fix configuration files
log_info "Step 4: Verifying configuration files..."

# Check if Generated.xcconfig exists
if [ ! -f "Flutter/Generated.xcconfig" ]; then
    log_error "Generated.xcconfig not found after Flutter configuration"
    log "🔍 Checking Flutter directory contents:"
    ls -la Flutter/ || true
    exit 1
fi

# Fix Release.xcconfig
log "🔧 Fixing Release.xcconfig..."
cat > Flutter/Release.xcconfig << 'EOF'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"
EOF

# Fix Debug.xcconfig
log "🔧 Fixing Debug.xcconfig..."
cat > Flutter/Debug.xcconfig << 'EOF'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Generated.xcconfig"
EOF

# Ensure Generated.xcconfig has proper content
log "🔧 Ensuring Generated.xcconfig has proper content..."
if [ ! -f "Flutter/Generated.xcconfig" ] || [ ! -s "Flutter/Generated.xcconfig" ]; then
    log "⚠️ Generated.xcconfig is missing or empty, creating basic configuration..."
    cat > Flutter/Generated.xcconfig << 'EOF'
FLUTTER_ROOT=/Users/builder/flutter
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
fi

# Step 5: Verify all configuration files
log_info "Step 5: Verifying all configuration files..."
if [ -f "Flutter/Generated.xcconfig" ] && [ -f "Flutter/Release.xcconfig" ] && [ -f "Flutter/Debug.xcconfig" ]; then
    log_success "All iOS configuration files are properly set up"
else
    log_error "Some configuration files are missing"
    ls -la Flutter/ || true
    exit 1
fi

# Step 6: Clean and reinstall CocoaPods
log_info "Step 6: Cleaning and reinstalling CocoaPods..."
rm -rf Pods/ Podfile.lock
pod install --repo-update

# Step 7: Test configuration
log_info "Step 7: Testing configuration..."
flutter build ios --no-codesign --debug --verbose || {
    log_error "Configuration test failed"
    exit 1
}

cd ..

log_success "✅ iOS Workflow Fix completed successfully!"
log "🎉 iOS build should now work without configuration errors" 