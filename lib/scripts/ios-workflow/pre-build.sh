#!/bin/bash

# 🚀 iOS Workflow Pre-Build Script - Upgraded Version
# Handles comprehensive pre-build setup for ios-workflow with enhanced features

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow Pre-Build Setup - Enhanced Version"

# Configuration
BUILD_TYPE="${BUILD_TYPE:-release}"
PROFILE_TYPE="${PROFILE_TYPE:-app-store}"
TARGET_ONLY_MODE="${TARGET_ONLY_MODE:-false}"
ENABLE_COLLISION_FIX="${ENABLE_COLLISION_FIX:-false}"
ENABLE_FRAMEWORK_BUNDLE_UPDATE="${ENABLE_FRAMEWORK_BUNDLE_UPDATE:-false}"
ENABLE_BUNDLE_ID_ECHO="${ENABLE_BUNDLE_ID_ECHO:-true}"

# Function to display build environment information
display_build_environment() {
    log_step "Build Environment Information"
    
    echo "📊 Build Environment:"
    echo "  - Flutter: $(flutter --version | head -1)"
    echo "  - Java: $(java -version 2>&1 | head -1)"
    echo "  - Xcode: $(xcodebuild -version | head -1)"
    echo "  - CocoaPods: $(pod --version)"
    echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
    echo "  - Profile Type: $PROFILE_TYPE"
    echo "  - Build Type: $BUILD_TYPE"
    
    # Target-Only Mode Configuration
    echo "🛡️ Target-Only Mode Configuration:"
    echo "  - TARGET_ONLY_MODE: $TARGET_ONLY_MODE"
    echo "  - ENABLE_COLLISION_FIX: $ENABLE_COLLISION_FIX"
    echo "  - ENABLE_FRAMEWORK_BUNDLE_UPDATE: $ENABLE_FRAMEWORK_BUNDLE_UPDATE"
    echo "  - ENABLE_BUNDLE_ID_ECHO: $ENABLE_BUNDLE_ID_ECHO"
    
    # Validate target-only mode configuration
    if [ "$TARGET_ONLY_MODE" = "true" ]; then
        log_success "Target-Only Mode is enabled"
        if [ "$ENABLE_COLLISION_FIX" = "false" ]; then
            log_success "Collision fix is disabled (correct for target-only mode)"
        else
            log_warning "Collision fix is enabled (should be disabled in target-only mode)"
        fi
        
        if [ "$ENABLE_FRAMEWORK_BUNDLE_UPDATE" = "false" ]; then
            log_success "Framework bundle update is disabled (correct for target-only mode)"
        else
            log_warning "Framework bundle update is enabled (should be disabled in target-only mode)"
        fi
    else
        log_warning "Target-Only Mode is disabled"
    fi
}

# Function to verify Xcode and iOS SDK compatibility
verify_xcode_compatibility() {
    log_step "Verifying Xcode and iOS SDK compatibility"
    
    # Check Xcode version
    local xcode_version=$(xcodebuild -version | grep "Xcode" | cut -d' ' -f2)
    local major_version=$(echo "$xcode_version" | cut -d'.' -f1)
    
    if [ "$major_version" -ge "14" ]; then
        log_success "Xcode version $xcode_version is compatible"
    else
        log_warning "Xcode version $xcode_version might have compatibility issues"
    fi
    
    # Check iOS SDK
    local sdk_path=$(xcodebuild -showsdks | grep "iOS" | tail -1 | awk '{print $NF}')
    if [ -n "$sdk_path" ]; then
        log_success "iOS SDK found: $sdk_path"
    else
        log_error "No iOS SDK found"
        return 1
    fi
}

# Function to install Flutter dependencies
install_flutter_dependencies() {
    log_step "Installing Flutter dependencies"
    
    # Install Flutter dependencies
    if flutter pub get; then
        log_success "Flutter dependencies installed successfully"
    else
        log_error "Failed to install Flutter dependencies"
        return 1
    fi
    
    # Verify rename package installation
    log_info "Verifying rename package installation..."
    if grep -q "rename:" pubspec.yaml; then
        log_success "Rename package found in pubspec.yaml"
        
        # Try to run rename command
        if flutter pub run rename --help >/dev/null 2>&1; then
            log_success "Rename package verified via command availability"
        else
            log_warning "Rename command not available, but package is in pubspec.yaml"
            log_info "This is normal for dev_dependencies in CI environment"
        fi
    else
        log_warning "Rename package not found in pubspec.yaml"
        log_info "Current dev_dependencies in pubspec.yaml:"
        grep -A 10 "dev_dependencies:" pubspec.yaml || echo "   No dev_dependencies section found"
    fi
}

# Function to perform pre-build cleanup
perform_prebuild_cleanup() {
    log_step "Performing pre-build cleanup"
    
    # Clean Flutter
    flutter clean
    
    # Clean various caches and build artifacts
    rm -rf ~/.gradle/caches/ 2>/dev/null || true
    rm -rf .dart_tool/ 2>/dev/null || true
    rm -rf ios/Pods/ 2>/dev/null || true
    rm -rf ios/build/ 2>/dev/null || true
    rm -rf build/ 2>/dev/null || true
    rm -rf output/ 2>/dev/null || true
    
    log_success "Pre-build cleanup completed"
}

# Function to optimize build environment
optimize_build_environment() {
    log_step "Optimizing build environment"
    
    # Set iOS optimization flags
    export XCODE_FAST_BUILD=true
    export XCODE_SKIP_SIGNING=false
    export XCODE_OPTIMIZATION=true
    export XCODE_CLEAN_BUILD=true
    export XCODE_PARALLEL_BUILD=true
    
    # Set CocoaPods optimization flags
    export COCOAPODS_FAST_INSTALL=true
    export COCOAPODS_PARALLEL_INSTALL=true
    
    # Set Flutter optimization flags
    export FLUTTER_PUB_CACHE=true
    export FLUTTER_VERBOSE=false
    export FLUTTER_ANALYZE=true
    export FLUTTER_TEST=false
    
    log_success "Build environment optimization completed"
}

# Function to generate environment configuration for Dart
generate_environment_config() {
    log_step "Generating environment configuration for Dart"
    
    if [ -f "lib/scripts/utils/env_generator.sh" ]; then
        chmod +x lib/scripts/utils/env_generator.sh
        if ./lib/scripts/utils/env_generator.sh; then
            log_success "Environment configuration generated successfully"
        else
            log_error "Environment configuration generation failed"
            return 1
        fi
    else
        log_warning "Environment generator script not found at lib/scripts/utils/env_generator.sh"
        log_info "Attempting to use fallback method..."
        
        # Fallback: Create basic env.g.dart if the script doesn't exist
        if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
            chmod +x lib/scripts/utils/gen_env_config.sh
            if ./lib/scripts/utils/gen_env_config.sh; then
                log_success "Fallback environment configuration generated successfully"
            else
                log_error "Fallback environment configuration failed"
                return 1
            fi
        else
            log_error "No environment configuration scripts found"
            return 1
        fi
    fi
}

# Function to setup iOS certificates and provisioning profiles
setup_ios_signing() {
    log_step "Setting up iOS certificates and provisioning profiles"
    
    # Download certificate if provided
    if [[ -n "${CERT_P12_URL:-}" ]]; then
        local cert_path="ios/Runner/Certificates.p12"
        mkdir -p "$(dirname "$cert_path")"
        
        if curl -L -o "$cert_path" "$CERT_P12_URL"; then
            log_success "Certificate downloaded successfully"
            
            # Import certificate to keychain
            if security import "$cert_path" -k login.keychain -P "${CERT_PASSWORD:-}" -T /usr/bin/codesign; then
                log_success "Certificate imported to keychain"
            else
                log_error "Failed to import certificate to keychain"
                return 1
            fi
        else
            log_error "Failed to download certificate from $CERT_P12_URL"
            return 1
        fi
    else
        log_warning "No certificate URL provided"
    fi
    
    # Download provisioning profile if provided
    if [[ -n "${PROFILE_URL:-}" ]]; then
        local profile_path="ios/Runner/Runner.mobileprovision"
        
        if curl -L -o "$profile_path" "$PROFILE_URL"; then
            log_success "Provisioning profile downloaded successfully"
            
            # Install provisioning profile
            mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/
            cp "$profile_path" ~/Library/MobileDevice/Provisioning\ Profiles/
            log_success "Provisioning profile installed"
        else
            log_error "Failed to download provisioning profile from $PROFILE_URL"
            return 1
        fi
    else
        log_warning "No provisioning profile URL provided"
    fi
}

# Function to setup Firebase configuration
setup_firebase_config() {
    if [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
        log_step "Setting up iOS Firebase configuration"
        
        local firebase_config_path="ios/Runner/GoogleService-Info.plist"
        
        if curl -L -o "$firebase_config_path" "$FIREBASE_CONFIG_IOS"; then
            log_success "iOS Firebase configuration downloaded successfully"
        else
            log_error "Failed to download iOS Firebase configuration"
            return 1
        fi
    else
        log_info "No iOS Firebase configuration provided"
    fi
}

# Function to setup APNS configuration
setup_apns_config() {
    if [[ -n "${APNS_AUTH_KEY_URL:-}" ]]; then
        log_step "Setting up APNS authentication key"
        
        local apns_key_path="ios/Runner/AuthKey_${APNS_KEY_ID:-}.p8"
        
        if curl -L -o "$apns_key_path" "$APNS_AUTH_KEY_URL"; then
            log_success "APNS authentication key downloaded successfully"
        else
            log_error "Failed to download APNS authentication key"
            return 1
        fi
    else
        log_info "No APNS authentication key provided"
    fi
}

# Function to update iOS project configuration
update_ios_project_config() {
    log_step "Updating iOS project configuration"
    
    # Update bundle identifier if provided
    if [[ -n "${BUNDLE_ID:-}" ]]; then
        log_info "Updating bundle identifier to: $BUNDLE_ID"
        
        # Update Info.plist
        if [ -f "ios/Runner/Info.plist" ]; then
            sed -i.bak "s/CFBundleIdentifier.*/CFBundleIdentifier = $BUNDLE_ID;/" \
                ios/Runner/Info.plist
            log_success "Info.plist bundle identifier updated"
        fi
        
        # Update project.pbxproj
        if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
            sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" \
                ios/Runner.xcodeproj/project.pbxproj
            log_success "Project.pbxproj bundle identifier updated"
        fi
        
        log_success "Bundle identifier updated to: $BUNDLE_ID"
    fi
    
    # Update app name if provided
    if [[ -n "${APP_NAME:-}" ]]; then
        log_info "Updating app name to: $APP_NAME"
        
        # Update Info.plist
        if [ -f "ios/Runner/Info.plist" ]; then
            sed -i.bak "s/CFBundleDisplayName.*/CFBundleDisplayName = $APP_NAME;/" \
                ios/Runner/Info.plist
            log_success "App name updated to: $APP_NAME"
        fi
    fi
    
    # Update team ID if provided
    if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
        log_info "Updating team ID to: $APPLE_TEAM_ID"
        
        # Update project.pbxproj
        if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
            sed -i.bak "s/DEVELOPMENT_TEAM = .*;/DEVELOPMENT_TEAM = $APPLE_TEAM_ID;/g" \
                ios/Runner.xcodeproj/project.pbxproj
            log_success "Team ID updated to: $APPLE_TEAM_ID"
        fi
    fi
}

# Function to setup feature integrations
setup_feature_integrations() {
    log_step "Setting up feature integrations"
    
    if [ -f "lib/scripts/utils/feature_integration.sh" ]; then
        chmod +x lib/scripts/utils/feature_integration.sh
        if ./lib/scripts/utils/feature_integration.sh; then
            log_success "Feature integrations configured successfully"
        else
            log_warning "Feature integration had issues, but continuing with build"
        fi
    else
        log_warning "Feature integration script not found"
    fi
}

# Main execution function
main() {
    log_info "Starting iOS workflow pre-build setup"
    
    # Display build environment
    display_build_environment
    
    # Verify Xcode compatibility
    verify_xcode_compatibility
    
    # Install Flutter dependencies
    install_flutter_dependencies
    
    # Perform pre-build cleanup
    perform_prebuild_cleanup
    
    # Optimize build environment
    optimize_build_environment
    
    # Generate environment configuration
    generate_environment_config
    
    # Setup iOS signing
    setup_ios_signing
    
    # Setup Firebase configuration
    setup_firebase_config
    
    # Setup APNS configuration
    setup_apns_config
    
    # Update iOS project configuration
    update_ios_project_config
    
    # Setup feature integrations
    setup_feature_integrations
    
    log_success "iOS workflow pre-build setup completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
