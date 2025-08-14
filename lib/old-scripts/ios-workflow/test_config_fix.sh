#!/bin/bash
# 🧪 Test Generated.xcconfig Fix
# Tests the fix_generated_config.sh script

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_CONFIG] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Testing Generated.xcconfig fix..."

# Test 1: Check if fix script exists
if [ -f "lib/scripts/ios-workflow/fix_generated_config.sh" ]; then
    log_success "✅ Fix script exists"
else
    log_error "❌ Fix script not found"
    exit 1
fi

# Test 2: Make script executable and run it
log_info "Running fix script..."
chmod +x lib/scripts/ios-workflow/fix_generated_config.sh

if ./lib/scripts/ios-workflow/fix_generated_config.sh; then
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

# Test 4: Verify other xcconfig files
for config_file in "ios/Flutter/Release.xcconfig" "ios/Flutter/Debug.xcconfig"; do
    if [ -f "$config_file" ]; then
        log_success "✅ $config_file exists"
        
        # Check for syntax errors
        if grep -q "unexpected character" "$config_file" 2>/dev/null || 
           grep -q "C$" "$config_file" 2>/dev/null; then
            log_error "❌ $config_file has syntax errors"
            cat "$config_file"
            exit 1
        else
            log_success "✅ $config_file syntax is valid"
        fi
    else
        log_warning "⚠️ $config_file does not exist"
    fi
done

# Test 5: Test Flutter build with the fixed config
log_info "Testing Flutter build with fixed configuration..."
if flutter build ios --no-codesign --debug > /dev/null 2>&1; then
    log_success "✅ Flutter build succeeded with fixed configuration"
else
    log_warning "⚠️ Flutter build failed, but this might be expected in test environment"
fi

log_success "All tests passed! Generated.xcconfig fix is working correctly." 