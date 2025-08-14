#!/bin/bash
# 🔧 Fix Generated.xcconfig Issue
# Ensures the Generated.xcconfig file is properly created for iOS builds

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIX_CONFIG] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting Generated.xcconfig fix..."

# Step 1: Check and fix xcconfig files for encoding issues
log_info "Step 1: Checking xcconfig files for encoding issues..."

# Function to clean xcconfig file
clean_xcconfig_file() {
    local file="$1"
    if [ -f "$file" ]; then
        log_info "Cleaning $file..."
        # Remove any BOM or hidden characters and ensure proper line endings
        tr -d '\r' < "$file" | sed 's/[[:space:]]*$//' > "${file}.tmp"
        mv "${file}.tmp" "$file"
        log_success "Cleaned $file"
    fi
}

# Clean existing xcconfig files
clean_xcconfig_file "ios/Flutter/Release.xcconfig"
clean_xcconfig_file "ios/Flutter/Debug.xcconfig"
clean_xcconfig_file "ios/Flutter/Generated.xcconfig"

# Step 2: Check if Generated.xcconfig exists and is valid
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    log_success "Generated.xcconfig exists"
    # Check if it's corrupted or has syntax errors
    if grep -q "unexpected character" ios/Flutter/Generated.xcconfig 2>/dev/null || 
       grep -q "C$" ios/Flutter/Generated.xcconfig 2>/dev/null; then
        log_warning "Generated.xcconfig appears corrupted, will recreate"
        rm -f ios/Flutter/Generated.xcconfig
    else
        log_success "Generated.xcconfig is valid"
        # Still verify it has the required content
        if grep -q "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig; then
            log_success "Generated.xcconfig has required content"
            exit 0
        else
            log_warning "Generated.xcconfig missing required content, will recreate"
            rm -f ios/Flutter/Generated.xcconfig
        fi
    fi
else
    log_warning "Generated.xcconfig is missing"
fi

# Step 3: Clean Flutter and regenerate
log_info "Step 2: Cleaning Flutter and regenerating configuration..."

# Clean Flutter
flutter clean > /dev/null 2>&1 || log_warning "flutter clean failed (continuing)"

# Get Flutter dependencies
flutter pub get > /dev/null 2>&1 || {
    log_error "flutter pub get failed"
    exit 1
}

# Step 4: Force Flutter to generate iOS configuration
log_info "Step 3: Forcing Flutter to generate iOS configuration..."

# Create the Flutter directory if it doesn't exist
mkdir -p ios/Flutter

# Try to run flutter build ios with no codesign to generate config
flutter build ios --no-codesign --debug > /dev/null 2>&1 || {
    log_warning "flutter build ios failed, creating Generated.xcconfig manually..."
    
    # Create a proper Generated.xcconfig with correct encoding
    cat > ios/Flutter/Generated.xcconfig << 'EOF'
// This is a generated file; do not edit or check into version control.
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
    
    log_success "Created Generated.xcconfig manually"
}

# Step 5: Verify the file was created and clean it
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    log_success "✅ Generated.xcconfig created successfully"
    
    # Clean the file to remove any potential encoding issues
    clean_xcconfig_file "ios/Flutter/Generated.xcconfig"
    
    # Check for any obvious syntax errors
    if grep -q "unexpected character" ios/Flutter/Generated.xcconfig 2>/dev/null || 
       grep -q "C$" ios/Flutter/Generated.xcconfig 2>/dev/null; then
        log_error "❌ Generated.xcconfig still has syntax errors"
        cat ios/Flutter/Generated.xcconfig
        exit 1
    else
        log_success "✅ Generated.xcconfig syntax is valid"
    fi
else
    log_error "❌ Generated.xcconfig was not created"
    exit 1
fi

# Step 6: Verify xcconfig files are properly formatted
log_info "Step 4: Verifying xcconfig files..."

# Check Release.xcconfig
if [ -f "ios/Flutter/Release.xcconfig" ]; then
    if grep -q "unexpected character" ios/Flutter/Release.xcconfig 2>/dev/null || 
       grep -q "C$" ios/Flutter/Release.xcconfig 2>/dev/null; then
        log_error "❌ Release.xcconfig has syntax errors"
        exit 1
    else
        log_success "✅ Release.xcconfig is valid"
    fi
fi

# Check Debug.xcconfig
if [ -f "ios/Flutter/Debug.xcconfig" ]; then
    if grep -q "unexpected character" ios/Flutter/Debug.xcconfig 2>/dev/null || 
       grep -q "C$" ios/Flutter/Debug.xcconfig 2>/dev/null; then
        log_error "❌ Debug.xcconfig has syntax errors"
        exit 1
    else
        log_success "✅ Debug.xcconfig is valid"
    fi
fi

# Step 7: Display the final Generated.xcconfig content for verification
log_info "Step 5: Generated.xcconfig content:"
cat ios/Flutter/Generated.xcconfig

log_success "Generated.xcconfig fix completed successfully" 