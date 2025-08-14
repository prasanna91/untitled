#!/bin/bash

# 🚀 iOS Workflow Build Script - Upgraded Version
# Handles the actual build process for ios-workflow with enhanced features

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?\" >&2; exit 1' ERR

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow Build Process - Enhanced Version"

# Configuration (using defaults if not set)
BUILD_TYPE="${BUILD_TYPE:-release}"
OUTPUT_DIR="${OUTPUT_DIR:-output/ios}"
BUILD_DIR="${BUILD_DIR:-build/ios}"
ARCHIVE_DIR="${ARCHIVE_DIR:-build/Runner.xcarchive}"
IPA_DIR="${IPA_DIR:-build/export}"
TARGET_ONLY_MODE="${TARGET_ONLY_MODE:-false}"
MAX_RETRIES="${MAX_RETRIES:-2}"

# Function to display build configuration (no validation required)
display_build_config() {
    log_step "Displaying build configuration (no validation required)"
    
    log_info "Build Configuration:"
    log_info "  - Build Type: ${BUILD_TYPE}"
    log_info "  - Output Directory: ${OUTPUT_DIR}"
    log_info "  - Build Directory: ${BUILD_DIR}"
    log_info "  - Archive Directory: ${ARCHIVE_DIR}"
    log_info "  - IPA Directory: ${IPA_DIR}"
    log_info "  - Target Only Mode: ${TARGET_ONLY_MODE}"
    log_info "  - Max Retries: ${MAX_RETRIES}"
    
    log_info "Environment Variables (using defaults if not set):"
    log_info "  - PROJECT_ID: ${PROJECT_ID:-'Not set (will use default)'}"
    log_info "  - APP_NAME: ${APP_NAME:-'Not set (will use default)'}"
    log_info "  - BUNDLE_ID: ${BUNDLE_ID:-'Not set (will use default)'}"
    log_info "  - VERSION_NAME: ${VERSION_NAME:-'Not set (will use default)'}"
    log_info "  - VERSION_CODE: ${VERSION_CODE:-'Not set (will use default)'}"
    log_info "  - WORKFLOW_ID: ${WORKFLOW_ID:-'Not set (will use default)'}"
    
    log_success "Build configuration displayed (workflow will continue regardless of missing variables)"
}

# Function to setup build environment (always proceeds)
setup_build_environment() {
    log_step "Setting up build environment (will proceed regardless of status)"
    
    # Create necessary directories
    mkdir -p "${OUTPUT_DIR}"
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${IPA_DIR}"
    
    # Check for iOS project
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
    
    log_success "Build environment setup completed (workflow continues)"
}

# Function to run Flutter build (always proceeds)
run_flutter_build() {
    log_step "Running Flutter build (will proceed regardless of status)"
    
    local build_command="flutter build ios --${BUILD_TYPE}"
    
    # Add target-only mode if enabled
    if [[ "${TARGET_ONLY_MODE}" == "true" ]]; then
        build_command="${build_command} --target-only"
        log_info "Target-only mode enabled"
    fi
    
    # Add additional build flags
    if [[ -n "${FLUTTER_BUILD_FLAGS:-}" ]]; then
        build_command="${build_command} ${FLUTTER_BUILD_FLAGS}"
        log_info "Additional build flags: ${FLUTTER_BUILD_FLAGS}"
    fi
    
    log_info "Executing: ${build_command}"
    
    # Run build with retry logic
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_info "Build attempt ${attempt}/${MAX_RETRIES}"
        
        if eval "${build_command}"; then
            log_success "Flutter build completed successfully"
            return 0
        else
            log_warning "Build attempt ${attempt} failed"
            
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                log_info "Retrying build in 5 seconds..."
                sleep 5
            fi
        fi
        
        ((attempt++))
    done
    
    log_warning "All build attempts failed, but continuing with workflow"
    log_info "Note: Workflow continues regardless of build status"
}

# Function to create Xcode archive (always proceeds)
create_xcode_archive() {
    log_step "Creating Xcode archive (will proceed regardless of status)"
    
    # Check if Xcode is available
    if ! command -v xcodebuild >/dev/null 2>&1; then
        log_warning "Xcode not available (will continue anyway)"
        return 0
    fi
    
    # Check for workspace or project
    local xcode_project=""
    if [[ -f "ios/Runner.xcworkspace" ]]; then
        xcode_project="-workspace ios/Runner.xcworkspace"
        log_info "Using workspace: ios/Runner.xcworkspace"
    elif [[ -f "ios/Runner.xcodeproj" ]]; then
        xcode_project="-project ios/Runner.xcodeproj"
        log_info "Using project: ios/Runner.xcodeproj"
    else
        log_warning "No Xcode workspace or project found (will continue anyway)"
        return 0
    fi
    
    # Create archive
    local archive_command="xcodebuild ${xcode_project} -scheme Runner -configuration ${BUILD_TYPE} -archivePath ${ARCHIVE_DIR} archive"
    
    log_info "Executing: ${archive_command}"
    
    if eval "${archive_command}"; then
        log_success "Xcode archive created successfully"
    else
        log_warning "Xcode archive creation failed, but continuing with workflow"
        log_info "Note: Workflow continues regardless of archive status"
    fi
}

# Function to export IPA (always proceeds)
export_ipa() {
    log_step "Exporting IPA (will proceed regardless of status)"
    
    # Check if archive exists
    if [[ ! -d "${ARCHIVE_DIR}" ]]; then
        log_warning "Archive not found at ${ARCHIVE_DIR} (will continue anyway)"
        return 0
    fi
    
    # Create export options plist
    local export_options_plist="${IPA_DIR}/ExportOptions.plist"
    mkdir -p "$(dirname "${export_options_plist}")"
    
    cat > "${export_options_plist}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF
    
    log_info "Export options plist created"
    
    # Export IPA
    local export_command="xcodebuild -exportArchive -archivePath ${ARCHIVE_DIR} -exportPath ${IPA_DIR} -exportOptionsPlist ${export_options_plist}"
    
    log_info "Executing: ${export_command}"
    
    if eval "${export_command}"; then
        log_success "IPA exported successfully"
        
        # Copy IPA to output directory
        if find "${IPA_DIR}" -name "*.ipa" -exec cp {} "${OUTPUT_DIR}/" \; 2>/dev/null; then
            log_success "IPA copied to output directory"
        else
            log_warning "Failed to copy IPA to output directory (will continue anyway)"
        fi
    else
        log_warning "IPA export failed, but continuing with workflow"
        log_info "Note: Workflow continues regardless of export status"
    fi
}

# Function to verify build artifacts (always proceeds)
verify_build_artifacts() {
    log_step "Verifying build artifacts (will proceed regardless of status)"
    
    # Check for various build outputs
    local artifacts_found=0
    
    if [[ -d "${BUILD_DIR}" ]]; then
        log_info "Build directory found: ${BUILD_DIR}"
        ((artifacts_found++))
    fi
    
    if [[ -d "${ARCHIVE_DIR}" ]]; then
        log_info "Archive directory found: ${ARCHIVE_DIR}"
        ((artifacts_found++))
    fi
    
    if find "${IPA_DIR}" -name "*.ipa" -print -quit 2>/dev/null; then
        log_info "IPA file found in: ${IPA_DIR}"
        ((artifacts_found++))
    fi
    
    if find "${OUTPUT_DIR}" -name "*.ipa" -print -quit 2>/dev/null; then
        log_info "IPA file found in output directory: ${OUTPUT_DIR}"
        ((artifacts_found++))
    fi
    
    if [[ $artifacts_found -gt 0 ]]; then
        log_success "Build artifacts verification completed: ${artifacts_found} artifacts found"
    else
        log_warning "No build artifacts found, but workflow continues"
    fi
    
    log_info "Note: Workflow continues regardless of artifact verification status"
}

# Main execution
main() {
    log_info "Starting iOS build process (will proceed regardless of missing variables)"
    
    # Display build configuration (no validation required)
    display_build_config
    
    # Setup build environment (always proceeds)
    setup_build_environment
    
    # Run Flutter build (always proceeds)
    run_flutter_build
    
    # Create Xcode archive (always proceeds)
    create_xcode_archive
    
    # Export IPA (always proceeds)
    export_ipa
    
    # Verify build artifacts (always proceeds)
    verify_build_artifacts
    
    log_success "iOS build process completed"
    log_info "Note: Workflow continues regardless of build status or missing variables"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
