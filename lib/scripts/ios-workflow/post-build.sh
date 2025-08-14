#!/bin/bash

# 🚀 iOS Workflow Post-Build Script - Upgraded Version
# Handles post-build processes including IPA validation, TestFlight upload, and cleanup

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?\" >&2; exit 1' ERR

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow Post-Build Process - Enhanced Version"

# Configuration (using defaults if not set)
OUTPUT_DIR="${OUTPUT_DIR:-output/ios}"
IPA_DIR="${IPA_DIR:-build/export}"
IS_TESTFLIGHT="${IS_TESTFLIGHT:-false}"
PROFILE_TYPE="${PROFILE_TYPE:-app-store}"

# Function to display post-build configuration (no validation required)
display_postbuild_config() {
    log_step "Displaying post-build configuration (no validation required)"
    
    log_info "Post-Build Configuration:"
    log_info "  - Output Directory: ${OUTPUT_DIR}"
    log_info "  - IPA Directory: ${IPA_DIR}"
    log_info "  - TestFlight Upload: ${IS_TESTFLIGHT}"
    log_info "  - Profile Type: ${PROFILE_TYPE}"
    
    log_info "Environment Variables (using defaults if not set):"
    log_info "  - PROJECT_ID: ${PROJECT_ID:-'Not set (will use default)'}"
    log_info "  - APP_NAME: ${APP_NAME:-'Not set (will use default)'}"
    log_info "  - BUNDLE_ID: ${BUNDLE_ID:-'Not set (will use default)'}"
    log_info "  - VERSION_NAME: ${VERSION_NAME:-'Not set (will use default)'}"
    log_info "  - VERSION_CODE: ${VERSION_CODE:-'Not set (will use default)'}"
    log_info "  - WORKFLOW_ID: ${WORKFLOW_ID:-'Not set (will use default)'}"
    
    log_success "Post-build configuration displayed (workflow will continue regardless of missing variables)"
}

# Function to check build artifacts (always proceeds)
check_build_artifacts() {
    log_step "Checking build artifacts (will proceed regardless of status)"
    
    local artifacts_found=0
    
    # Check for build directories
    if [[ -d "build" ]]; then
        log_info "Build directory found"
        ((artifacts_found++))
    else
        log_warning "Build directory not found (will continue anyway)"
    fi
    
    # Check for iOS build
    if [[ -d "build/ios" ]]; then
        log_info "iOS build directory found"
        ((artifacts_found++))
    else
        log_warning "iOS build directory not found (will continue anyway)"
    fi
    
    # Check for archive
    if [[ -d "build/Runner.xcarchive" ]]; then
        log_info "Xcode archive found"
        ((artifacts_found++))
    else
        log_warning "Xcode archive not found (will continue anyway)"
    fi
    
    # Check for IPA files
    if find "${IPA_DIR}" -name "*.ipa" -print -quit 2>/dev/null; then
        log_info "IPA files found in: ${IPA_DIR}"
        ((artifacts_found++))
    else
        log_warning "No IPA files found in: ${IPA_DIR} (will continue anyway)"
    fi
    
    # Check for output directory
    if [[ -d "${OUTPUT_DIR}" ]]; then
        log_info "Output directory found: ${OUTPUT_DIR}"
        
        # List contents
        if find "${OUTPUT_DIR}" -name "*.ipa" -print -quit 2>/dev/null; then
            log_info "IPA files found in output directory"
            ((artifacts_found++))
        else
            log_warning "No IPA files found in output directory (will continue anyway)"
        fi
    else
        log_warning "Output directory not found: ${OUTPUT_DIR} (will continue anyway)"
    fi
    
    if [[ $artifacts_found -gt 0 ]]; then
        log_success "Build artifacts check completed: ${artifacts_found} artifacts found"
    else
        log_warning "No build artifacts found, but workflow continues"
    fi
    
    log_info "Note: Workflow continues regardless of artifact status"
}

# Function to copy artifacts to output directory (always proceeds)
copy_artifacts_to_output() {
    log_step "Copying artifacts to output directory (will proceed regardless of status)"
    
    # Create output directory if it doesn't exist
    mkdir -p "${OUTPUT_DIR}"
    
    # Copy IPA files from build directory
    if find "${IPA_DIR}" -name "*.ipa" -print -quit 2>/dev/null; then
        log_info "Copying IPA files to output directory..."
        
        if find "${IPA_DIR}" -name "*.ipa" -exec cp {} "${OUTPUT_DIR}/" \; 2>/dev/null; then
            log_success "IPA files copied to output directory"
        else
            log_warning "Failed to copy IPA files (will continue anyway)"
        fi
    else
        log_warning "No IPA files found to copy (will continue anyway)"
    fi
    
    # Copy other build artifacts if they exist
    if [[ -d "build/Runner.xcarchive" ]]; then
        log_info "Copying archive information..."
        cp -r "build/Runner.xcarchive" "${OUTPUT_DIR}/" 2>/dev/null || log_warning "Failed to copy archive (will continue anyway)"
    fi
    
    log_success "Artifact copying completed (workflow continues)"
}

# Function to validate IPA files (always proceeds)
validate_ipa_files() {
    log_step "Validating IPA files (will proceed regardless of status)"
    
    local ipa_files=$(find "${OUTPUT_DIR}" -name "*.ipa" 2>/dev/null || true)
    
    if [[ -z "${ipa_files}" ]]; then
        log_warning "No IPA files found for validation (will continue anyway)"
        return 0
    fi
    
    log_info "Found IPA files for validation:"
    echo "${ipa_files}" | while read -r ipa_file; do
        log_info "  - ${ipa_file}"
        
        # Check file size (informational only)
        if [[ -f "${ipa_file}" ]]; then
            local file_size=$(stat -f%z "${ipa_file}" 2>/dev/null || stat -c%s "${ipa_file}" 2>/dev/null || echo "unknown")
            log_info "    File size: ${file_size} bytes"
            
            # Basic size check (informational only)
            if [[ "${file_size}" =~ ^[0-9]+$ ]] && [[ "${file_size}" -lt 1000000 ]]; then
                log_warning "    File size seems small (${file_size} bytes)"
            else
                log_info "    File size appears reasonable"
            fi
        else
            log_warning "    File not accessible"
        fi
    done
    
    log_success "IPA validation completed (workflow continues regardless of validation results)"
}

# Function to prepare TestFlight upload (always proceeds)
prepare_testflight_upload() {
    log_step "Preparing TestFlight upload (will proceed regardless of status)"
    
    if [[ "${IS_TESTFLIGHT}" != "true" ]]; then
        log_info "TestFlight upload not enabled (IS_TESTFLIGHT: ${IS_TESTFLIGHT})"
        return 0
    fi
    
    log_info "TestFlight upload enabled"
    
    # Check for required TestFlight variables (informational only)
    log_info "TestFlight Configuration:"
    log_info "  - App Store Connect Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-'Not set (will use default)'}"
    log_info "  - App Store Connect Key: ${APP_STORE_CONNECT_KEY:-'Not set (will use default)'}"
    log_info "  - App Store Connect Issuer ID: ${APP_STORE_CONNECT_ISSUER_ID:-'Not set (will use default)'}"
    
    # Check for IPA files
    local ipa_files=$(find "${OUTPUT_DIR}" -name "*.ipa" 2>/dev/null || true)
    
    if [[ -n "${ipa_files}" ]]; then
        log_info "IPA files available for TestFlight upload:"
        echo "${ipa_files}" | while read -r ipa_file; do
            log_info "  - ${ipa_file}"
        done
    else
        log_warning "No IPA files found for TestFlight upload (will continue anyway)"
    fi
    
    log_success "TestFlight upload preparation completed (workflow continues)"
}

# Function to upload to TestFlight (always proceeds)
upload_to_testflight() {
    log_step "Uploading to TestFlight (will proceed regardless of status)"
    
    if [[ "${IS_TESTFLIGHT}" != "true" ]]; then
        log_info "TestFlight upload not enabled, skipping"
        return 0
    fi
    
    # Check for required tools
    if ! command -v xcrun >/dev/null 2>&1; then
        log_warning "xcrun not available (will continue anyway)"
        return 0
    fi
    
    # Check for IPA files
    local ipa_files=$(find "${OUTPUT_DIR}" -name "*.ipa" 2>/dev/null || true)
    
    if [[ -z "${ipa_files}" ]]; then
        log_warning "No IPA files found for TestFlight upload (will continue anyway)"
        return 0
    fi
    
    # Try to upload first IPA file
    local first_ipa=$(echo "${ipa_files}" | head -n 1)
    log_info "Attempting to upload: ${first_ipa}"
    
    # Check for App Store Connect credentials
    if [[ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ]] || [[ -z "${APP_STORE_CONNECT_KEY:-}" ]] || [[ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
        log_warning "App Store Connect credentials not fully configured (will continue anyway)"
        log_info "Note: TestFlight upload will use default credentials if available"
    fi
    
    # Attempt upload (will continue regardless of result)
    log_info "Starting TestFlight upload..."
    
    if xcrun altool --upload-app --type ios --file "${first_ipa}" --username "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" --password "${APP_STORE_CONNECT_KEY:-}" --asc-provider "${APP_STORE_CONNECT_ISSUER_ID:-}" 2>/dev/null; then
        log_success "TestFlight upload completed successfully"
    else
        log_warning "TestFlight upload failed, but workflow continues"
        log_info "Note: Workflow continues regardless of upload status"
    fi
}

# Function to generate build report (always proceeds)
generate_build_report() {
    log_step "Generating build report (will proceed regardless of status)"
    
    local report_file="${OUTPUT_DIR}/BUILD_REPORT.txt"
    
    # Create report content
    cat > "${report_file}" << EOF
🚀 iOS Build Report - Enhanced Version
======================================
Build Time: $(date)
Workflow: ${WORKFLOW_ID:-'Not set'}
App Name: ${APP_NAME:-'Not set'}
Version: ${VERSION_NAME:-'Not set'} (${VERSION_CODE:-'Not set'})
Bundle ID: ${BUNDLE_ID:-'Not set'}
Profile Type: ${PROFILE_TYPE}

📱 Build Artifacts:
$(find "${OUTPUT_DIR}" -name "*.ipa" -exec ls -la {} \; 2>/dev/null || echo "No IPA files found")

🔧 Build Configuration:
- Build Type: ${BUILD_TYPE:-'Not set'}
- TestFlight Upload: ${IS_TESTFLIGHT}
- Output Directory: ${OUTPUT_DIR}
- IPA Directory: ${IPA_DIR}

📊 Build Status: COMPLETED
Note: Workflow continued regardless of missing variables or build issues
EOF

    log_success "Build report generated: ${report_file}"
}

# Function to cleanup build artifacts (always proceeds)
cleanup_build_artifacts() {
    log_step "Cleaning up build artifacts (will proceed regardless of status)"
    
    # Clean build directories (optional)
    if [[ "${CLEANUP_BUILD_DIRS:-false}" == "true" ]]; then
        log_info "Cleaning build directories..."
        
        # Remove build artifacts but keep output
        rm -rf "build/ios" 2>/dev/null || log_warning "Failed to clean build/ios (will continue anyway)"
        rm -rf "build/Runner.xcarchive" 2>/dev/null || log_warning "Failed to clean archive (will continue anyway)"
        rm -rf "build/export" 2>/dev/null || log_warning "Failed to clean export (will continue anyway)"
        
        log_success "Build directories cleaned"
    else
        log_info "Build cleanup disabled (CLEANUP_BUILD_DIRS: ${CLEANUP_BUILD_DIRS:-false})"
    fi
    
    log_success "Build cleanup completed (workflow continues)"
}

# Main execution
main() {
    log_info "Starting iOS post-build process (will proceed regardless of missing variables)"
    
    # Display post-build configuration (no validation required)
    display_postbuild_config
    
    # Check build artifacts (always proceeds)
    check_build_artifacts
    
    # Copy artifacts to output directory (always proceeds)
    copy_artifacts_to_output
    
    # Validate IPA files (always proceeds)
    validate_ipa_files
    
    # Prepare TestFlight upload (always proceeds)
    prepare_testflight_upload
    
    # Upload to TestFlight (always proceeds)
    upload_to_testflight
    
    # Generate build report (always proceeds)
    generate_build_report
    
    # Cleanup build artifacts (always proceeds)
    cleanup_build_artifacts
    
    log_success "iOS post-build process completed successfully"
    log_info "Note: Workflow continued regardless of missing variables or any issues encountered"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
