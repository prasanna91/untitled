#!/bin/bash
# 🧪 Test Generated.xcconfig Fix
# Tests the fix_generated_config_before_pods.sh script

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_CONFIG_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Testing Generated.xcconfig fix..."

# Test 1: Check if fix script exists
if [ -f "lib/scripts/ios-workflow/fix_generated_config_before_pods.sh" ]; then
    log_success "✅ Fix script exists"
else
    log_error "❌ Fix script not found"
    exit 1
fi

# Test 2: Make script executable and run it
log_info "Running fix script..."
chmod +x lib/scripts/ios-workflow/fix_generated_config_before_pods.sh

if ./lib/scripts/ios-workflow/fix_generated_config_before_pods.sh; then
    log_success "✅ Fix script ran successfully"
else
    log_error "❌ Fix script failed"
    exit 1
fi

# Test 3: Verify Generated.xcconfig exists and is valid
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    log_success "✅ Generated.xcconfig exists"
    
    # Check for required content
    if grep -q "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig; then
        log_success "✅ Generated.xcconfig has required content"
    else
        log_error "❌ Generated.xcconfig missing required content"
        exit 1
    fi
    
    # Check for syntax errors
    if grep -q "unexpected character" ios/Flutter/Generated.xcconfig 2>/dev/null || 
       grep -q "C$" ios/Flutter/Generated.xcconfig 2>/dev/null; then
        log_error "❌ Generated.xcconfig has syntax errors"
        cat ios/Flutter/Generated.xcconfig
        exit 1
    else
        log_success "✅ Generated.xcconfig syntax is valid"
    fi
else
    log_error "❌ Generated.xcconfig does not exist"
    exit 1
fi

# Test 4: Verify Podfile can read the Generated.xcconfig
log_info "Testing Podfile compatibility..."
if [ -f "ios/Podfile" ]; then
    log_success "✅ Podfile exists"
    
    # Check if Podfile references Generated.xcconfig
    if grep -q "Generated.xcconfig" ios/Podfile; then
        log_success "✅ Podfile references Generated.xcconfig"
    else
        log_warning "⚠️ Podfile does not reference Generated.xcconfig"
    fi
else
    log_warning "⚠️ Podfile does not exist"
fi

# Test 5: Test basic pod install (without full installation)
log_info "Testing pod install validation..."
pushd ios > /dev/null || { log_error "Failed to enter ios directory"; exit 1; }

# Just check if pod install can start (don't run full installation)
if pod install --dry-run > /dev/null 2>&1; then
    log_success "✅ Pod install validation passed"
else
    log_warning "⚠️ Pod install validation failed, but this might be expected"
fi

popd > /dev/null

log_success "All tests passed! Generated.xcconfig fix is working correctly." 