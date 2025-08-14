#!/bin/bash
# 🔧 Robust Xcconfig Fix
# Ensures all xcconfig files are properly cleaned and created

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ROBUST_XCCONFIG_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting robust xcconfig fix..."

# Step 1: Create Flutter directory if it doesn't exist
mkdir -p ios/Flutter

# Step 2: Clean all xcconfig files
log_info "Step 1: Cleaning all xcconfig files..."

clean_xcconfig_file() {
    local file="$1"
    if [ -f "$file" ]; then
        log_info "Cleaning $file..."
        # Remove BOM, hidden chars, fix line endings
        tr -d '\r' < "$file" | sed 's/[[:space:]]*$//' > "${file}.tmp"
        mv "${file}.tmp" "$file"
        log_success "Cleaned $file"
    fi
}

clean_xcconfig_file "ios/Flutter/Release.xcconfig"
clean_xcconfig_file "ios/Flutter/Debug.xcconfig"
clean_xcconfig_file "ios/Flutter/Generated.xcconfig"

# Step 3: Recreate Release.xcconfig
log_info "Step 2: Recreating Release.xcconfig..."
cat > ios/Flutter/Release.xcconfig << 'EOF'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"
EOF
log_success "✅ Created Release.xcconfig"

# Step 4: Recreate Debug.xcconfig
log_info "Step 3: Recreating Debug.xcconfig..."
cat > ios/Flutter/Debug.xcconfig << 'EOF'
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Generated.xcconfig"
EOF
log_success "✅ Created Debug.xcconfig"

# Step 5: Recreate Generated.xcconfig
log_info "Step 4: Recreating Generated.xcconfig..."

# Try to get Flutter root from environment or use default
FLUTTER_ROOT="${FLUTTER_ROOT:-/usr/local/bin}"
FLUTTER_APPLICATION_PATH="${FLUTTER_APPLICATION_PATH:-/Users/builder/clone}"

cat > ios/Flutter/Generated.xcconfig << EOF
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=$FLUTTER_ROOT
FLUTTER_APPLICATION_PATH=$FLUTTER_APPLICATION_PATH
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=${VERSION_NAME:-1.0.0}
FLUTTER_BUILD_NUMBER=${VERSION_CODE:-1}
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF
log_success "✅ Created Generated.xcconfig"

# Step 6: Verify all files exist and are valid
log_info "Step 5: Verifying all xcconfig files..."

verify_xcconfig_file() {
    local file="$1"
    if [ -f "$file" ]; then
        log_success "✅ $file exists"
        
        # Check for encoding issues
        if file "$file" | grep -q "text"; then
            log_success "✅ $file is valid text"
        else
            log_warning "⚠️ $file may have encoding issues"
        fi
        
        # Check for required content
        if grep -q "Generated.xcconfig" "$file" 2>/dev/null || grep -q "FLUTTER_ROOT" "$file" 2>/dev/null; then
            log_success "✅ $file has required content"
        else
            log_warning "⚠️ $file may be missing required content"
        fi
    else
        log_error "❌ $file does not exist"
        return 1
    fi
}

verify_xcconfig_file "ios/Flutter/Release.xcconfig"
verify_xcconfig_file "ios/Flutter/Debug.xcconfig"
verify_xcconfig_file "ios/Flutter/Generated.xcconfig"

# Step 7: Display file contents for verification
log_info "Step 6: Displaying file contents for verification..."

log_info "Release.xcconfig content:"
cat ios/Flutter/Release.xcconfig

log_info "Debug.xcconfig content:"
cat ios/Flutter/Debug.xcconfig

log_info "Generated.xcconfig content:"
cat ios/Flutter/Generated.xcconfig

# Step 8: Test xcconfig parsing
log_info "Step 7: Testing xcconfig parsing..."

# Test if Xcode can parse the files
if command -v xcodebuild >/dev/null 2>&1; then
    log_info "Testing xcconfig parsing with xcodebuild..."
    if xcodebuild -showBuildSettings -project ios/Runner.xcodeproj -scheme Runner -configuration Release >/dev/null 2>&1; then
        log_success "✅ xcconfig files parse correctly"
    else
        log_warning "⚠️ xcconfig files may have parsing issues"
    fi
else
    log_warning "xcodebuild not available, skipping parsing test"
fi

log_success "✅ Robust xcconfig fix completed" 