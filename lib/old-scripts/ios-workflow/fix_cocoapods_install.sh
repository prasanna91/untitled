#!/bin/bash
# 🔧 Fix CocoaPods Installation Issues
# Handles common CocoaPods installation problems in iOS workflows

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [COCOAPODS_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting CocoaPods installation fix..."

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

# Step 1: Check CocoaPods installation
log_info "Step 1: Checking CocoaPods installation..."

if ! command -v pod &>/dev/null; then
    log_error "CocoaPods is not installed!"
    log_info "Installing CocoaPods..."
    sudo gem install cocoapods || {
        log_error "Failed to install CocoaPods via gem"
        exit 1
    }
else
    log_success "CocoaPods is installed: $(pod --version)"
fi

# Step 2: Check Podfile existence and validity
log_info "Step 2: Checking Podfile..."

if [ ! -f "ios/Podfile" ]; then
    log_error "Podfile not found at ios/Podfile"
    exit 1
fi

# Verify Podfile integrity
if ! grep -q "target 'Runner'" ios/Podfile; then
    log_error "Podfile is corrupted - missing target 'Runner'"
    log_info "Podfile contents:"
    cat ios/Podfile
    exit 1
fi

log_success "Podfile is valid"

# Step 3: Clean up CocoaPods cache and files
log_info "Step 3: Cleaning CocoaPods cache and files..."

# Remove old files
rm -rf ios/Pods > /dev/null 2>&1 || true
rm -f ios/Podfile.lock > /dev/null 2>&1 || true
rm -rf ~/.cocoapods > /dev/null 2>&1 || true
rm -rf ~/Library/Caches/CocoaPods > /dev/null 2>&1 || true

log_success "CocoaPods cache cleaned"

# Step 4: Update CocoaPods repo
log_info "Step 4: Updating CocoaPods repo..."

pod repo update > /dev/null 2>&1 || {
    log_warning "pod repo update failed, continuing anyway..."
}

# Step 5: Try different installation methods
log_info "Step 5: Attempting CocoaPods installation..."

# Method 1: Standard install
log_info "Trying standard pod install..."
pushd ios > /dev/null || { log_error "Failed to enter ios directory"; exit 1; }

if pod install --verbose > /dev/null 2>&1; then
    log_success "✅ Standard pod install completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Standard pod install failed, trying alternative methods..."
fi

# Method 2: Install with repo update
log_info "Trying pod install with repo update..."
if pod install --repo-update --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with repo update completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with repo update failed..."
fi

# Method 3: Install with legacy build system
log_info "Trying pod install with legacy build system..."
if pod install --verbose --legacy-build-system > /dev/null 2>&1; then
    log_success "✅ Pod install with legacy build system completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with legacy build system failed..."
fi

# Method 4: Install with no repo update and no cache
log_info "Trying pod install with no cache..."
pod cache clean --all > /dev/null 2>&1 || true
if pod install --no-repo-update --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with no cache completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with no cache failed..."
fi

# Method 5: Install with specific platform
log_info "Trying pod install with specific platform..."
if pod install --platform=ios --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with specific platform completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific platform failed..."
fi

# Method 6: Install with deployment target
log_info "Trying pod install with deployment target..."
if pod install --deployment-target=13.0 --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with deployment target completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with deployment target failed..."
fi

# Method 7: Install with explicit workspace
log_info "Trying pod install with explicit workspace..."
if pod install --workspace=Runner.xcworkspace --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with explicit workspace completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with explicit workspace failed..."
fi

# Method 8: Install with project specification
log_info "Trying pod install with project specification..."
if pod install --project-directory=. --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with project specification completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with project specification failed..."
fi

# Method 9: Install with clean build
log_info "Trying pod install with clean build..."
rm -rf Pods > /dev/null 2>&1 || true
rm -f Podfile.lock > /dev/null 2>&1 || true
if pod install --clean-install --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with clean build completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with clean build failed..."
fi

# Method 10: Install with specific CocoaPods version
log_info "Trying pod install with specific CocoaPods version..."
if pod install --verbose --allow-warnings > /dev/null 2>&1; then
    log_success "✅ Pod install with warnings allowed completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with warnings allowed failed..."
fi

# Method 11: Install with force
log_info "Trying pod install with force..."
if pod install --force --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with force completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with force failed..."
fi

# Method 12: Install with no integrate
log_info "Trying pod install with no integrate..."
if pod install --no-integrate --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with no integrate completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with no integrate failed..."
fi

# Method 13: Install with specific target
log_info "Trying pod install with specific target..."
if pod install --target=Runner --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with specific target completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific target failed..."
fi

# Method 14: Install with development pods
log_info "Trying pod install with development pods..."
if pod install --development --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with development pods completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with development pods failed..."
fi

# Method 15: Install with no update
log_info "Trying pod install with no update..."
if pod install --no-update --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with no update completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with no update failed..."
fi

# Method 16: Install with specific configuration
log_info "Trying pod install with specific configuration..."
if pod install --configuration=Release --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with specific configuration completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific configuration failed..."
fi

# Method 17: Install with explicit scheme
log_info "Trying pod install with explicit scheme..."
if pod install --scheme=Runner --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with explicit scheme completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with explicit scheme failed..."
fi

# Method 18: Install with specific architecture
log_info "Trying pod install with specific architecture..."
if pod install --arch=arm64 --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with specific architecture completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific architecture failed..."
fi

# Method 19: Install with specific SDK
log_info "Trying pod install with specific SDK..."
if pod install --sdk=iphoneos --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with specific SDK completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific SDK failed..."
fi

# Method 20: Install with specific configuration
log_info "Trying pod install with specific configuration..."
if pod install --configuration=Debug --verbose > /dev/null 2>&1; then
    log_success "✅ Pod install with specific configuration completed successfully"
    popd > /dev/null
    exit 0
else
    log_warning "Pod install with specific configuration failed..."
fi

# Final attempt: Basic install with full output
log_info "Final attempt: Basic pod install with full output..."
if pod install; then
    log_success "✅ Basic pod install completed successfully"
    popd > /dev/null
    exit 0
else
    log_error "❌ All pod install methods failed"
    log_info "Pod install error details:"
    pod install 2>&1 || true
    popd > /dev/null
    exit 1
fi 