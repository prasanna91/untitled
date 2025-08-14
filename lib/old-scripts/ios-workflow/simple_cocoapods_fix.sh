#!/bin/bash
# 🔧 Simple CocoaPods Fix
# Handles the specific CocoaPods installation error we're seeing

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SIMPLE_COCOAPODS_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting simple CocoaPods fix..."

# Step 0: Ensure Generated.xcconfig exists before CocoaPods
log_info "Step 0: Ensuring Generated.xcconfig exists before CocoaPods..."
if [ -f "lib/scripts/ios-workflow/fix_generated_config_before_pods.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_generated_config_before_pods.sh
    if ./lib/scripts/ios-workflow/fix_generated_config_before_pods.sh; then
        log_success "✅ Generated.xcconfig is ready for CocoaPods"
    else
        log_error "❌ Failed to create Generated.xcconfig"
        exit 1
    fi
else
    log_warning "Generated.xcconfig fix script not found, continuing anyway..."
fi

# Step 1: Basic checks
log_info "Step 1: Basic checks..."

if ! command -v pod &>/dev/null; then
    log_error "CocoaPods is not installed!"
    exit 1
fi

if [ ! -f "ios/Podfile" ]; then
    log_error "Podfile not found at ios/Podfile"
    exit 1
fi

log_success "Basic checks passed"

# Step 2: Clean everything
log_info "Step 2: Cleaning everything..."

rm -rf ios/Pods > /dev/null 2>&1 || true
rm -f ios/Podfile.lock > /dev/null 2>&1 || true
rm -rf ~/.cocoapods > /dev/null 2>&1 || true
rm -rf ~/Library/Caches/CocoaPods > /dev/null 2>&1 || true

log_success "Cleaned all CocoaPods files"

# Step 3: Enter ios directory and try simple install
log_info "Step 3: Trying simple pod install..."

pushd ios > /dev/null || { log_error "Failed to enter ios directory"; exit 1; }

# Try the simplest possible install
log_info "Attempting basic pod install..."
if pod install --no-repo-update --verbose; then
    log_success "✅ Basic pod install succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Basic pod install failed, trying with repo update..."
fi

# Try with repo update
log_info "Attempting pod install with repo update..."
if pod install --repo-update --verbose; then
    log_success "✅ Pod install with repo update succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with repo update failed, trying with warnings allowed..."
fi

# Try with warnings allowed
log_info "Attempting pod install with warnings allowed..."
if pod install --allow-warnings --verbose; then
    log_success "✅ Pod install with warnings allowed succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with warnings allowed failed, trying with force..."
fi

# Try with force
log_info "Attempting pod install with force..."
if pod install --force --verbose; then
    log_success "✅ Pod install with force succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with force failed, trying with clean install..."
fi

# Try with clean install
log_info "Attempting pod install with clean install..."
if pod install --clean-install --verbose; then
    log_success "✅ Pod install with clean install succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with clean install failed, trying with no integrate..."
fi

# Try with no integrate
log_info "Attempting pod install with no integrate..."
if pod install --no-integrate --verbose; then
    log_success "✅ Pod install with no integrate succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with no integrate failed, trying with legacy build system..."
fi

# Try with legacy build system
log_info "Attempting pod install with legacy build system..."
if pod install --legacy-build-system --verbose; then
    log_success "✅ Pod install with legacy build system succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with legacy build system failed, trying with specific platform..."
fi

# Try with specific platform
log_info "Attempting pod install with specific platform..."
if pod install --platform=ios --verbose; then
    log_success "✅ Pod install with specific platform succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific platform failed, trying with deployment target..."
fi

# Try with deployment target
log_info "Attempting pod install with deployment target..."
if pod install --deployment-target=13.0 --verbose; then
    log_success "✅ Pod install with deployment target succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with deployment target failed, trying with explicit workspace..."
fi

# Try with explicit workspace
log_info "Attempting pod install with explicit workspace..."
if pod install --workspace=Runner.xcworkspace --verbose; then
    log_success "✅ Pod install with explicit workspace succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with explicit workspace failed, trying with project directory..."
fi

# Try with project directory
log_info "Attempting pod install with project directory..."
if pod install --project-directory=. --verbose; then
    log_success "✅ Pod install with project directory succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with project directory failed, trying with specific target..."
fi

# Try with specific target
log_info "Attempting pod install with specific target..."
if pod install --target=Runner --verbose; then
    log_success "✅ Pod install with specific target succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific target failed, trying with development pods..."
fi

# Try with development pods
log_info "Attempting pod install with development pods..."
if pod install --development --verbose; then
    log_success "✅ Pod install with development pods succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with development pods failed, trying with no update..."
fi

# Try with no update
log_info "Attempting pod install with no update..."
if pod install --no-update --verbose; then
    log_success "✅ Pod install with no update succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with no update failed, trying with specific configuration..."
fi

# Try with specific configuration
log_info "Attempting pod install with specific configuration..."
if pod install --configuration=Release --verbose; then
    log_success "✅ Pod install with specific configuration succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific configuration failed, trying with explicit scheme..."
fi

# Try with explicit scheme
log_info "Attempting pod install with explicit scheme..."
if pod install --scheme=Runner --verbose; then
    log_success "✅ Pod install with explicit scheme succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with explicit scheme failed, trying with specific architecture..."
fi

# Try with specific architecture
log_info "Attempting pod install with specific architecture..."
if pod install --arch=arm64 --verbose; then
    log_success "✅ Pod install with specific architecture succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific architecture failed, trying with specific SDK..."
fi

# Try with specific SDK
log_info "Attempting pod install with specific SDK..."
if pod install --sdk=iphoneos --verbose; then
    log_success "✅ Pod install with specific SDK succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific SDK failed, trying with Debug configuration..."
fi

# Try with Debug configuration
log_info "Attempting pod install with Debug configuration..."
if pod install --configuration=Debug --verbose; then
    log_success "✅ Pod install with Debug configuration succeeded"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with Debug configuration failed, trying final basic install..."
fi

# Final attempt: Basic install with full output
log_info "Final attempt: Basic pod install with full output..."
if pod install; then
    log_success "✅ Basic pod install succeeded"
    popd > /dev/null
    exit 0
else
    log_error "❌ All pod install methods failed"
    log_info "Pod install error details:"
    pod install 2>&1 || true
    popd > /dev/null
    exit 1
fi 