#!/bin/bash
# 🧪 iOS Configuration Test Script
# Tests iOS configuration files for syntax errors

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

log "🧪 Starting iOS Configuration Test..."

# Ensure we're in the project root
cd "$(dirname "$0")/../.."

# Test 1: Check if iOS directory exists
log_info "Test 1: Checking iOS directory..."
if [ -d "ios" ]; then
    log_success "iOS directory exists"
else
    log_error "iOS directory not found"
    exit 1
fi

cd ios

# Test 2: Check if Flutter directory exists
log_info "Test 2: Checking Flutter directory..."
if [ -d "Flutter" ]; then
    log_success "Flutter directory exists"
else
    log_error "Flutter directory not found"
    exit 1
fi

# Test 3: Check configuration files
log_info "Test 3: Checking configuration files..."

# Check Generated.xcconfig
if [ -f "Flutter/Generated.xcconfig" ]; then
    log_success "Generated.xcconfig exists"
    log "📄 Generated.xcconfig content:"
    cat Flutter/Generated.xcconfig
else
    log_error "Generated.xcconfig not found"
    exit 1
fi

# Check Release.xcconfig
if [ -f "Flutter/Release.xcconfig" ]; then
    log_success "Release.xcconfig exists"
    log "📄 Release.xcconfig content:"
    cat Flutter/Release.xcconfig
else
    log_error "Release.xcconfig not found"
    exit 1
fi

# Check Debug.xcconfig
if [ -f "Flutter/Debug.xcconfig" ]; then
    log_success "Debug.xcconfig exists"
    log "📄 Debug.xcconfig content:"
    cat Flutter/Debug.xcconfig
else
    log_error "Debug.xcconfig not found"
    exit 1
fi

# Test 4: Check for syntax errors
log_info "Test 4: Checking for syntax errors..."

# Check for trailing spaces or invalid characters
if grep -q "Generated.xcconfig " Flutter/Release.xcconfig; then
    log_error "Release.xcconfig has trailing space after Generated.xcconfig"
    exit 1
fi

if grep -q "Generated.xcconfig " Flutter/Debug.xcconfig; then
    log_error "Debug.xcconfig has trailing space after Generated.xcconfig"
    exit 1
fi

log_success "No syntax errors found in configuration files"

# Test 5: Test Flutter build
log_info "Test 5: Testing Flutter build..."
flutter build ios --no-codesign --debug --verbose || {
    log_error "Flutter build test failed"
    exit 1
}

log_success "✅ All iOS configuration tests passed!"
cd ..

log "🎉 iOS configuration is working properly!" 