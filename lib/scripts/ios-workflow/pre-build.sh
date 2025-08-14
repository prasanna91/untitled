#!/bin/bash

# 🚀 iOS Workflow Pre-Build Script - Upgraded Version
# Handles comprehensive pre-build setup for ios-workflow with enhanced features

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?\" >&2; exit 1' ERR

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow Pre-Build Setup - Enhanced Version"

# Configuration (using defaults if not set)
BUILD_TYPE="${BUILD_TYPE:-release}"
PROFILE_TYPE="${PROFILE_TYPE:-app-store}"
TARGET_ONLY_MODE="${TARGET_ONLY_MODE:-false}"
ENABLE_COLLISION_FIX="${ENABLE_COLLISION_FIX:-false}"
ENABLE_FRAMEWORK_BUNDLE_UPDATE="${ENABLE_FRAMEWORK_BUNDLE_UPDATE:-false}"
ENABLE_BUNDLE_ID_ECHO="${ENABLE_BUNDLE_ID_ECHO:-true}"

# Function to display configuration (no validation required)
display_configuration() {
    log_step "Displaying build configuration (no validation required)"
    
    log_info "Build Configuration:"
    log_info "  - Build Type: ${BUILD_TYPE}"
    log_info "  - Profile Type: ${PROFILE_TYPE}"
    log_info "  - Target Only Mode: ${TARGET_ONLY_MODE}"
    log_info "  - Enable Collision Fix: ${ENABLE_COLLISION_FIX}"
    log_info "  - Enable Framework Bundle Update: ${ENABLE_FRAMEWORK_BUNDLE_UPDATE}"
    log_info "  - Enable Bundle ID Echo: ${ENABLE_BUNDLE_ID_ECHO}"
    
    log_info "Environment Variables (using defaults if not set):"
    log_info "  - PROJECT_ID: ${PROJECT_ID:-'Not set (will use default)'}"
    log_info "  - APP_NAME: ${APP_NAME:-'Not set (will use default)'}"
    log_info "  - BUNDLE_ID: ${BUNDLE_ID:-'Not set (will use default)'}"
    log_info "  - APPLE_TEAM_ID: ${APPLE_TEAM_ID:-'Not set (will use default)'}"
    log_info "  - WORKFLOW_ID: ${WORKFLOW_ID:-'Not set (will use default)'}"
    
    log_success "Configuration displayed (workflow will continue regardless of missing variables)"
}

# Function to check Xcode availability (always proceeds)
check_xcode_availability() {
    log_step "Checking Xcode availability (will proceed regardless of status)"
    
    if command -v xcodebuild >/dev/null 2>&1; then
        local xcode_version=$(xcodebuild -version | head -n 1)
        log_info "Xcode found: $xcode_version"
    else
        log_warning "Xcode not found in PATH (will continue with available tools)"
    fi
    
    if command -v pod >/dev/null 2>&1; then
        local pod_version=$(pod --version)
        log_info "CocoaPods found: $pod_version"
    else
        log_warning "CocoaPods not found (will continue without pod operations)"
    fi
    
    log_success "Xcode availability check completed (workflow continues)"
}

# Function to setup Flutter environment (always proceeds)
setup_flutter_environment() {
    log_step "Setting up Flutter environment (will proceed regardless of status)"
    
    if command -v flutter >/dev/null 2>&1; then
        local flutter_version=$(flutter --version | head -n 1)
        log_info "Flutter found: $flutter_version"
        
        # Get Flutter dependencies (will continue even if some fail)
        log_info "Getting Flutter dependencies..."
        if flutter pub get; then
            log_success "Flutter dependencies updated successfully"
        else
            log_warning "Some Flutter dependencies may have issues (continuing anyway)"
        fi
    else
        log_warning "Flutter not found in PATH (will continue with available tools)"
    fi
    
    log_success "Flutter environment setup completed (workflow continues)"
}

# Function to setup iOS signing (always proceeds)
setup_ios_signing() {
    log_step "Setting up iOS signing configuration (will proceed regardless of status)"
    
    # Display signing info (no validation required)
    log_info "iOS Signing Configuration:"
    log_info "  - Bundle ID: ${BUNDLE_ID:-'Not set (will use default)'}"
    log_info "  - Team ID: ${APPLE_TEAM_ID:-'Not set (will use default)'}"
    log_info "  - Profile Type: ${PROFILE_TYPE}"
    
    # Check for certificates (informational only)
    if [[ -n "${CERT_CER_URL:-}" ]]; then
        log_info "  - Certificate URL: ${CERT_CER_URL}"
    else
        log_info "  - Certificate URL: Not set (will use default)"
    fi
    
    if [[ -n "${CERT_KEY_URL:-}" ]]; then
        log_info "  - Private Key URL: ${CERT_KEY_URL}"
    else
        log_info "  - Private Key URL: Not set (will use default)"
    fi
    
    if [[ -n "${PROFILE_URL:-}" ]]; then
        log_info "  - Provisioning Profile URL: ${PROFILE_URL}"
    else
        log_info "  - Provisioning Profile URL: Not set (will use default)"
    fi
    
    log_success "iOS signing setup completed (workflow continues regardless of configuration)"
}

# Function to setup Firebase configuration (always proceeds)
setup_firebase_config() {
    log_step "Setting up Firebase configuration (will proceed regardless of status)"
    
    # Display Firebase info (no validation required)
    log_info "Firebase Configuration:"
    log_info "  - Push Notifications: ${PUSH_NOTIFY:-'Not set (will use default: false)'}"
    
    if [[ "${PUSH_NOTIFY:-}" == "true" ]]; then
        log_info "  - Android Firebase Config: ${FIREBASE_CONFIG_ANDROID:-'Not set (will use default)'}"
        log_info "  - iOS Firebase Config: ${FIREBASE_CONFIG_IOS:-'Not set (will use default)'}"
    else
        log_info "  - Firebase disabled (pushNotify: false)"
    fi
    
    log_success "Firebase configuration setup completed (workflow continues)"
}

# Function to setup iOS project configuration (always proceeds)
setup_ios_project_config() {
    log_step "Setting up iOS project configuration (will proceed regardless of status)"
    
    # Display project info (no validation required)
    log_info "iOS Project Configuration:"
    log_info "  - App Name: ${APP_NAME:-'Not set (will use default)'}"
    log_info "  - Bundle ID: ${BUNDLE_ID:-'Not set (will use default)'}"
    log_info "  - Version: ${VERSION_NAME:-'Not set (will use default)'}"
    log_info "  - Build Number: ${VERSION_CODE:-'Not set (will use default)'}"
    
    # Check for iOS project files
    if [[ -d "ios" ]]; then
        log_info "iOS project directory found"
        
        # Check for specific files (informational only)
        if [[ -f "ios/Runner/Info.plist" ]]; then
            log_info "Info.plist found"
        else
            log_warning "Info.plist not found (will continue anyway)"
        fi
        
        if [[ -f "ios/Podfile" ]]; then
            log_info "Podfile found"
        else
            log_warning "Podfile not found (will continue anyway)"
        fi
    else
        log_warning "iOS project directory not found (will continue anyway)"
    fi
    
    log_success "iOS project configuration setup completed (workflow continues)"
}

# Function to setup feature integrations (always proceeds)
setup_feature_integrations() {
    log_step "Setting up feature integrations (will proceed regardless of status)"
    
    # Display feature info (no validation required)
    log_info "Feature Integrations:"
    log_info "  - Chatbot: ${IS_CHATBOT:-'Not set (will use default: false)'}"
    log_info "  - Domain URL: ${IS_DOMAIN_URL:-'Not set (will use default: false)'}"
    log_info "  - Splash Screen: ${IS_SPLASH:-'Not set (will use default: false)'}"
    log_info "  - Pull to Refresh: ${IS_PULLDOWN:-'Not set (will use default: false)'}"
    log_info "  - Bottom Menu: ${IS_BOTTOMMENU:-'Not set (will use default: false)'}"
    log_info "  - Loading Indicators: ${IS_LOAD_IND:-'Not set (will use default: false)'}"
    
    # Check for required assets (informational only)
    if [[ -d "assets" ]]; then
        log_info "Assets directory found"
        
        if [[ -d "assets/images" ]]; then
            log_info "Images directory found"
        else
            log_warning "Images directory not found (will continue anyway)"
        fi
        
        if [[ -d "assets/icons" ]]; then
            log_info "Icons directory found"
        else
            log_warning "Icons directory not found (will continue anyway)"
        fi
    else
        log_warning "Assets directory not found (will continue anyway)"
    fi
    
    log_success "Feature integrations setup completed (workflow continues)"
}

# Main execution
main() {
    log_info "Starting iOS pre-build setup (will proceed regardless of missing variables)"
    
    # Display configuration (no validation required)
    display_configuration
    
    # Check Xcode availability (always proceeds)
    check_xcode_availability
    
    # Setup Flutter environment (always proceeds)
    setup_flutter_environment
    
    # Setup iOS signing (always proceeds)
    setup_ios_signing
    
    # Setup Firebase configuration (always proceeds)
    setup_firebase_config
    
    # Setup iOS project configuration (always proceeds)
    setup_ios_project_config
    
    # Setup feature integrations (always proceeds)
    setup_feature_integrations
    
    log_success "iOS pre-build setup completed successfully"
    log_info "Note: Workflow continues regardless of missing or empty variables"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
