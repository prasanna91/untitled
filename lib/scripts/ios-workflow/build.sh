#!/bin/bash

# 🚀 iOS Workflow Build Script - Upgraded Version
# Handles the actual build process for ios-workflow with enhanced features

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow Build Process - Enhanced Version"

# Configuration
BUILD_TYPE="${BUILD_TYPE:-release}"
OUTPUT_DIR="output/ios"
BUILD_DIR="build/ios"
ARCHIVE_DIR="build/Runner.xcarchive"
IPA_DIR="build/export"
TARGET_ONLY_MODE="${TARGET_ONLY_MODE:-false}"
MAX_RETRIES="${MAX_RETRIES:-2}"

# Function to validate build configuration
validate_build_config() {
    log_step "Validating build configuration"
    
    # Target-Only Mode Configuration
    echo "🛡️ Target-Only Mode Build Configuration:"
    echo "  - TARGET_ONLY_MODE: $TARGET_ONLY_MODE"
    echo "  - BUILD_TYPE: $BUILD_TYPE"
    echo "  - MAX_RETRIES: $MAX_RETRIES"
    
    # Validate target-only mode if required
    if [ "${TARGET_ONLY_MODE:-false}" != "true" ]; then
        log_warning "TARGET_ONLY_MODE is not enabled"
        log_info "This workflow works best with TARGET_ONLY_MODE=true"
    else
        log_success "Target-Only Mode validation passed"
    fi
    
    # Validate required environment variables
    local required_vars=("BUNDLE_ID" "APP_NAME" "VERSION_NAME" "VERSION_CODE")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_warning "Missing environment variables: ${missing_vars[*]}"
        log_info "Build will continue with default values"
    else
        log_success "All required environment variables are set"
    fi
}

# Function to setup iOS build environment
setup_ios_environment() {
    log_step "Setting up iOS build environment"
    
    # Create output directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$IPA_DIR"
    
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
    
    log_success "iOS build environment setup completed"
}

# Function to clean previous builds
clean_ios_builds() {
    log_step "Cleaning previous iOS builds"
    
    # Clean Flutter
    flutter clean
    
    # Clean iOS build artifacts
    rm -rf ios/build/
    rm -rf ios/Pods/
    rm -rf "$BUILD_DIR"
    rm -rf "$ARCHIVE_DIR"
    rm -rf "$IPA_DIR"
    
    # Clean CocoaPods
    cd ios
    pod deintegrate 2>/dev/null || true
    pod cache clean --all 2>/dev/null || true
    cd ..
    
    log_success "iOS build cleanup completed"
}

# Function to install CocoaPods dependencies
install_cocoapods() {
    log_step "Installing CocoaPods dependencies"
    
    cd ios
    
    # Install CocoaPods if not available
    if ! command -v pod &> /dev/null; then
        log_info "Installing CocoaPods..."
        sudo gem install cocoapods
    fi
    
    # Install pods with enhanced error handling
    local pod_install_attempts=0
    local max_pod_attempts=3
    
    while [ $pod_install_attempts -lt $max_pod_attempts ]; do
        pod_install_attempts=$((pod_install_attempts + 1))
        log_info "CocoaPods installation attempt $pod_install_attempts of $max_pod_attempts"
        
        if pod install --repo-update; then
            log_success "CocoaPods dependencies installed successfully"
            break
        else
            log_warning "CocoaPods installation failed on attempt $pod_install_attempts"
            
            if [ $pod_install_attempts -lt $max_pod_attempts ]; then
                log_info "Cleaning and retrying in 10 seconds..."
                pod deintegrate 2>/dev/null || true
                pod cache clean --all 2>/dev/null || true
                sleep 10
            else
                log_error "Failed to install CocoaPods dependencies after $max_pod_attempts attempts"
                cd ..
                return 1
            fi
        fi
    done
    
    cd ..
}

# Function to build Flutter iOS
build_flutter_ios() {
    log_step "Building Flutter iOS app"
    
    local build_args="--release --no-codesign"
    
    # Add additional build flags if available
    if [[ -n "${FLUTTER_BUILD_FLAGS:-}" ]]; then
        build_args="$build_args $FLUTTER_BUILD_FLAGS"
    fi
    
    log_info "Build arguments: $build_args"
    
    if flutter build ios $build_args; then
        log_success "Flutter iOS build completed successfully"
    else
        log_error "Flutter iOS build failed"
        return 1
    fi
}

# Function to create Xcode archive
create_xcode_archive() {
    log_step "Creating Xcode archive"
    
    cd ios
    
    # Create archive with enhanced error handling
    local archive_attempts=0
    local max_archive_attempts=2
    
    while [ $archive_attempts -lt $max_archive_attempts ]; do
        archive_attempts=$((archive_attempts + 1))
        log_info "Archive creation attempt $archive_attempts of $max_archive_attempts"
        
        if xcodebuild -workspace Runner.xcworkspace \
                       -scheme Runner \
                       -configuration Release \
                       -archivePath ../build/Runner.xcarchive \
                       archive; then
            log_success "Xcode archive created successfully"
            break
        else
            log_warning "Archive creation failed on attempt $archive_attempts"
            
            if [ $archive_attempts -lt $max_archive_attempts ]; then
                log_info "Cleaning and retrying in 10 seconds..."
                flutter clean
                sleep 10
            else
                log_error "Failed to create Xcode archive after $max_archive_attempts attempts"
                cd ..
                return 1
            fi
        fi
    done
    
    cd ..
}

# Function to export IPA
export_ipa() {
    log_step "Exporting IPA from archive"
    
    # Create ExportOptions.plist with enhanced configuration
    cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${PROFILE_TYPE:-app-store}</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID:-com.example.app}</key>
        <string>${PROVISIONING_PROFILE_NAME:-}</string>
    </dict>
    <key>signingCertificate</key>
    <string>${SIGNING_CERTIFICATE:-}</string>
</dict>
</plist>
EOF

    log_info "ExportOptions.plist created with enhanced configuration"
    
    # Export IPA with retry logic
    local export_attempts=0
    local max_export_attempts=2
    
    while [ $export_attempts -lt $max_export_attempts ]; do
        export_attempts=$((export_attempts + 1))
        log_info "IPA export attempt $export_attempts of $max_export_attempts"
        
        if xcodebuild -exportArchive \
                       -archivePath "$ARCHIVE_DIR" \
                       -exportPath "$IPA_DIR" \
                       -exportOptionsPlist ios/ExportOptions.plist; then
            log_success "IPA exported successfully"
            
            # Copy IPA to output directory
            cp "$IPA_DIR"/*.ipa "$OUTPUT_DIR/"
            log_info "IPA copied to output directory"
            break
        else
            log_warning "IPA export failed on attempt $export_attempts"
            
            if [ $export_attempts -lt $max_export_attempts ]; then
                log_info "Retrying in 10 seconds..."
                sleep 10
            else
                log_error "Failed to export IPA after $max_export_attempts attempts"
                return 1
            fi
        fi
    done
}

# Function to validate build artifacts
validate_build_artifacts() {
    log_step "Validating build artifacts"
    
    # Check if IPA file exists and has reasonable size
    local ipa_files=$(find "$OUTPUT_DIR" -name "*.ipa" -type f 2>/dev/null || true)
    
    if [ -z "$ipa_files" ]; then
        log_error "No IPA files found in output directory"
        return 1
    fi
    
    # Validate each IPA file
    echo "$ipa_files" | while read -r ipa_file; do
        log_info "Validating IPA: $ipa_file"
        
        # Check file size
        local ipa_size=$(stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file" 2>/dev/null || echo "0")
        log_info "IPA file size: $ipa_size bytes"
        
        if [ "$ipa_size" -lt 1000000 ]; then
            log_warning "IPA file is suspiciously small ($ipa_size bytes)"
        else
            log_success "IPA file size validation passed"
        fi
        
        # Check if IPA can be extracted (basic validation)
        if unzip -t "$ipa_file" >/dev/null 2>&1; then
            log_success "IPA file integrity validation passed"
        else
            log_error "IPA file integrity validation failed"
            return 1
        fi
    done
    
    log_success "Build artifacts validation completed"
}

# Function to generate build summary
generate_build_summary() {
    log_step "Generating build summary"
    
    local summary_file="$OUTPUT_DIR/BUILD_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
🚀 iOS Build Summary - Enhanced Version
========================================
Build Time: $(date)
Workflow: ${WORKFLOW_ID:-Unknown}
App Name: ${APP_NAME:-Unknown}
Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})
Bundle ID: ${BUNDLE_ID:-Unknown}
Team ID: ${APPLE_TEAM_ID:-Unknown}

📱 Build Artifacts:
$(ls -la "$OUTPUT_DIR"/*.ipa 2>/dev/null || echo "No IPA files found")

🔧 Build Configuration:
- Build Type: $BUILD_TYPE
- Profile Type: ${PROFILE_TYPE:-Unknown}
- Target-Only Mode: $TARGET_ONLY_MODE
- Code Signing: ${CERT_P12_URL:+Configured}${CERT_P12_URL:-Not configured}
- Firebase: ${FIREBASE_CONFIG_IOS:+Configured}${FIREBASE_CONFIG_IOS:-Not configured}
- APNS: ${APNS_AUTH_KEY_URL:+Configured}${APNS_AUTH_KEY_URL:-Not configured}

📊 Build Statistics:
- Archive Size: $(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo "Unknown")
- Output Directory: $(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "Unknown")
- Build Duration: ${BUILD_DURATION:-Unknown}

✅ Build Status: SUCCESS
EOF

    log_success "Build summary generated: $summary_file"
}

# Main execution function with retry logic
main() {
    log_info "Starting iOS workflow build process"
    
    # Validate build configuration
    validate_build_config
    
    # Setup environment
    setup_ios_environment
    
    # Enhanced build with retry logic
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        retry_count=$((retry_count + 1))
        log_info "Build attempt $retry_count of $MAX_RETRIES"
        
        # Clean previous builds
        clean_ios_builds
        
        # Install CocoaPods dependencies
        if ! install_cocoapods; then
            log_error "CocoaPods installation failed"
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_info "Retrying in 15 seconds..."
                sleep 15
                continue
            else
                exit 1
            fi
        fi
        
        # Build Flutter iOS
        if ! build_flutter_ios; then
            log_error "Flutter iOS build failed"
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_info "Retrying in 15 seconds..."
                sleep 15
                continue
            else
                exit 1
            fi
        fi
        
        # Create Xcode archive
        if ! create_xcode_archive; then
            log_error "Xcode archive creation failed"
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_info "Retrying in 15 seconds..."
                sleep 15
                continue
            else
                exit 1
            fi
        fi
        
        # Export IPA
        if ! export_ipa; then
            log_error "IPA export failed"
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_info "Retrying in 15 seconds..."
                sleep 15
                continue
            else
                exit 1
            fi
        fi
        
        # If we reach here, build was successful
        log_success "Build completed successfully on attempt $retry_count!"
        break
    done
    
    # Validate build artifacts
    validate_build_artifacts
    
    # Generate build summary
    generate_build_summary
    
    log_success "iOS workflow build process completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
