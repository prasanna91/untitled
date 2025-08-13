#!/bin/bash

# 🚀 Combined Build Script for Codemagic CI/CD
# Handles both Android and iOS builds in a single workflow

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "Combined Build Process (Android + iOS)"

# Configuration
BUILD_TYPE="${BUILD_TYPE:-release}"
ANDROID_BUILD_MODE="${ANDROID_BUILD_MODE:-both}"
OUTPUT_DIR="output"
ANDROID_OUTPUT_DIR="$OUTPUT_DIR/android"
IOS_OUTPUT_DIR="$OUTPUT_DIR/ios"

# Function to setup combined build environment
setup_combined_environment() {
    log_step "Setting up combined build environment"
    
    # Create output directories
    mkdir -p "$ANDROID_OUTPUT_DIR"
    mkdir -p "$IOS_OUTPUT_DIR"
    
    # Set optimization flags for both platforms
    export GRADLE_DAEMON=true
    export GRADLE_PARALLEL=true
    export GRADLE_CACHING=true
    export XCODE_FAST_BUILD=true
    export COCOAPODS_FAST_INSTALL=true
    export FLUTTER_PUB_CACHE=true
    export FLUTTER_VERBOSE=false
    export FLUTTER_ANALYZE=true
    export FLUTTER_TEST=false
    
    log_success "Combined build environment setup completed"
}

# Function to generate environment configuration
generate_environment_config() {
    log_step "Generating environment configuration for both platforms"
    
    # Run environment generator
    if bash "$(dirname "$0")/../utils/env_generator.sh"; then
        log_success "Environment configuration generated successfully"
    else
        log_warning "Environment configuration generation had issues, but continuing"
    fi
}

# Function to build Android
build_android() {
    log_step "Building Android application"
    
    # Set build mode for Android
    export BUILD_MODE="$ANDROID_BUILD_MODE"
    
    if bash "$(dirname "$0")/../android/main.sh"; then
        log_success "Android build completed successfully"
        return 0
    else
        log_error "Android build failed"
        return 1
    fi
}

# Function to build iOS
build_ios() {
    log_step "Building iOS application"
    
    if bash "$(dirname "$0")/../ios-workflow/ios-workflow-main.sh"; then
        log_success "iOS build completed successfully"
        return 0
    else
        log_error "iOS build failed"
        return 1
    fi
}

# Function to validate build artifacts
validate_artifacts() {
    log_step "Validating build artifacts"
    
    local android_artifacts=0
    local ios_artifacts=0
    
    # Check Android artifacts
    if [[ -f "$ANDROID_OUTPUT_DIR/app-release.apk" ]]; then
        android_artifacts=$((android_artifacts + 1))
        log_info "Android APK found: $(ls -lh "$ANDROID_OUTPUT_DIR/app-release.apk")"
    fi
    
    if [[ -f "$ANDROID_OUTPUT_DIR/app-release.aab" ]]; then
        android_artifacts=$((android_artifacts + 1))
        log_info "Android AAB found: $(ls -lh "$ANDROID_OUTPUT_DIR/app-release.aab")"
    fi
    
    # Check iOS artifacts
    if [[ -f "$IOS_OUTPUT_DIR"/*.ipa ]]; then
        ios_artifacts=$((ios_artifacts + 1))
        log_info "iOS IPA found: $(ls -lh "$IOS_OUTPUT_DIR"/*.ipa)"
    fi
    
    log_info "Artifact summary: $android_artifacts Android, $ios_artifacts iOS"
    
    if [[ $android_artifacts -gt 0 ]] || [[ $ios_artifacts -gt 0 ]]; then
        log_success "Build artifacts validation completed"
        return 0
    else
        log_error "No build artifacts found"
        return 1
    fi
}

# Function to generate combined build summary
generate_combined_summary() {
    log_step "Generating combined build summary"
    
    local summary_file="$OUTPUT_DIR/COMBINED_BUILD_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
🚀 Combined Build Summary (Android + iOS)
=========================================
Build Time: $(date)
Workflow: ${WORKFLOW_ID:-Unknown}
App Name: ${APP_NAME:-Unknown}
Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})

📱 Android Artifacts:
$(ls -la "$ANDROID_OUTPUT_DIR"/*.apk "$ANDROID_OUTPUT_DIR"/*.aab 2>/dev/null || echo "No Android artifacts found")

🍎 iOS Artifacts:
$(ls -la "$IOS_OUTPUT_DIR"/*.ipa 2>/dev/null || echo "No iOS artifacts found")

🔧 Build Configuration:
- Build Type: $BUILD_TYPE
- Android Build Mode: $ANDROID_BUILD_MODE
- Android Signing: ${KEY_STORE_URL:+Configured}${KEY_STORE_URL:-Not configured}
- iOS Signing: ${CERT_P12_URL:+Configured}${CERT_P12_URL:-Not configured}
- Firebase Android: ${FIREBASE_CONFIG_ANDROID:+Configured}${FIREBASE_CONFIG_ANDROID:-Not configured}
- Firebase iOS: ${FIREBASE_CONFIG_IOS:+Configured}${FIREBASE_CONFIG_IOS:-Not configured}

📊 Build Results:
- Android: ${android_build_success:+SUCCESS}${android_build_success:-FAILED}
- iOS: ${ios_build_success:+SUCCESS}${ios_build_success:-FAILED}

✅ Overall Status: ${overall_success:+SUCCESS}${overall_success:-FAILED}
EOF

    log_success "Combined build summary generated: $summary_file"
}

# Function to cleanup temporary files
cleanup_temp_files() {
    log_step "Cleaning up temporary files"
    
    # Remove temporary iOS files
    rm -f ios/Runner/Certificates.p12
    rm -f ios/Runner/Runner.mobileprovision
    rm -f ios/Runner/GoogleService-Info.plist
    rm -f ios/Runner/AuthKey_*.p8
    rm -f ios/ExportOptions.plist
    
    # Remove temporary Android files
    rm -f android/app/keystore.jks
    rm -f android/app/google-services.json
    
    # Remove backup files
    find . -name "*.bak" -delete 2>/dev/null || true
    
    log_success "Temporary files cleanup completed"
}

# Main execution function
main() {
    log_info "Starting combined build process"
    log_info "Build Type: $BUILD_TYPE, Android Mode: $ANDROID_BUILD_MODE"
    
    # Initialize success flags
    android_build_success=false
    ios_build_success=false
    overall_success=false
    
    # Setup environment
    setup_combined_environment
    
    # Generate environment configuration
    generate_environment_config
    
    # Setup feature integrations
    log_step "Setting up feature integrations for both platforms"
    if bash "$(dirname "$0")/../utils/feature_integration.sh"; then
        log_success "Feature integrations configured successfully"
    else
        log_warning "Feature integration had issues, but continuing with build"
    fi
    
    # Build Android
    if build_android; then
        android_build_success=true
        log_success "Android build phase completed successfully"
    else
        log_error "Android build phase failed"
    fi
    
    # Build iOS
    if build_ios; then
        ios_build_success=true
        log_success "iOS build phase completed successfully"
    else
        log_error "iOS build phase failed"
    fi
    
    # Determine overall success
    if [[ "$android_build_success" == true ]] || [[ "$ios_build_success" == true ]]; then
        overall_success=true
    fi
    
    # Validate artifacts
    if ! validate_artifacts; then
        log_warning "Some build artifacts are missing"
    fi
    
    # Generate combined summary
    generate_combined_summary
    
    # Cleanup temporary files
    cleanup_temp_files
    
    # Final status
    if [[ "$overall_success" == true ]]; then
        log_success "Combined build process completed successfully"
        log_info "At least one platform built successfully"
        exit 0
    else
        log_error "Combined build process failed - no platforms built successfully"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
