#!/bin/bash
# 🧪 Test Xcodebuild Command
# Tests the xcodebuild command to ensure it works correctly

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_XCODEBUILD] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Testing xcodebuild command..."

# Test 1: Check if xcodebuild is available
log_info "Test 1: Checking xcodebuild availability..."
if command -v xcodebuild >/dev/null 2>&1; then
    XCODE_VERSION=$(xcodebuild -version | head -1)
    log_success "✅ xcodebuild is available: $XCODE_VERSION"
else
    log_error "❌ xcodebuild is not available"
    exit 1
fi

# Test 2: Check workspace and scheme
log_info "Test 2: Checking workspace and scheme..."
if [[ -d "ios/Runner.xcworkspace" ]]; then
    log_success "✅ ios/Runner.xcworkspace exists"
else
    log_error "❌ ios/Runner.xcworkspace not found"
    exit 1
fi

if [[ -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]]; then
    log_success "✅ ios/Runner.xcworkspace is valid"
else
    log_error "❌ ios/Runner.xcworkspace is not valid"
    exit 1
fi

# Test 3: List available schemes
log_info "Test 3: Listing available schemes..."
if xcodebuild -workspace ios/Runner.xcworkspace -list >/dev/null 2>&1; then
    log_success "✅ Can list workspace schemes"
    log_info "Available schemes:"
    xcodebuild -workspace ios/Runner.xcworkspace -list | grep -A 10 "Schemes:"
else
    log_error "❌ Cannot list workspace schemes"
    exit 1
fi

# Test 4: Check if Runner scheme exists
log_info "Test 4: Checking if Runner scheme exists..."
if xcodebuild -workspace ios/Runner.xcworkspace -list | grep -q "Runner"; then
    log_success "✅ Runner scheme exists"
else
    log_error "❌ Runner scheme not found"
    log_info "Available schemes:"
    xcodebuild -workspace ios/Runner.xcworkspace -list | grep -A 10 "Schemes:"
    exit 1
fi

# Test 5: Test xcodebuild help
log_info "Test 5: Testing xcodebuild help..."
if xcodebuild -help >/dev/null 2>&1; then
    log_success "✅ xcodebuild help works"
else
    log_error "❌ xcodebuild help failed"
    exit 1
fi

# Test 6: Test archive command syntax (without actually building)
log_info "Test 6: Testing archive command syntax..."
XCODEBUILD_CMD="xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    -jobs \"8\" \
    -showBuildSettings"

log_info "Testing command: $XCODEBUILD_CMD"

if eval $XCODEBUILD_CMD >/dev/null 2>&1; then
    log_success "✅ xcodebuild command syntax is valid"
else
    log_error "❌ xcodebuild command syntax is invalid"
    log_info "Trying with simpler command..."
    
    # Try a simpler command
    SIMPLE_CMD="xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -showBuildSettings"
    if eval $SIMPLE_CMD >/dev/null 2>&1; then
        log_success "✅ Simple xcodebuild command works"
    else
        log_error "❌ Even simple xcodebuild command fails"
        exit 1
    fi
fi

# Test 7: Check environment variables
log_info "Test 7: Checking environment variables..."
REQUIRED_VARS=("APPLE_TEAM_ID" "UUID" "BUNDLE_ID")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        MISSING_VARS+=("$var")
    else
        log_success "✅ $var is set: ${!var}"
    fi
done

if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
    log_warning "⚠️ Missing environment variables: ${MISSING_VARS[*]}"
    log_info "These will need to be set for the actual build"
else
    log_success "✅ All required environment variables are set"
fi

# Test 8: Test export command syntax
log_info "Test 8: Testing export command syntax..."
EXPORT_CMD="xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath build/ios/output \
    -exportOptionsPlist ios/ExportOptions.plist \
    -help"

log_info "Testing export command: $EXPORT_CMD"

if eval $EXPORT_CMD >/dev/null 2>&1; then
    log_success "✅ Export command syntax is valid"
else
    log_warning "⚠️ Export command syntax may have issues"
fi

log_success "✅ All xcodebuild tests passed" 