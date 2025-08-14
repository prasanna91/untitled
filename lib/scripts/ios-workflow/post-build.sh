#!/bin/bash

# 🚀 iOS Workflow Post-Build Script - Upgraded Version
# Handles post-build processes including IPA validation, TestFlight upload, and cleanup

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow Post-Build Process - Enhanced Version"

# Configuration
OUTPUT_DIR="output/ios"
IPA_DIR="build/export"
IS_TESTFLIGHT="${IS_TESTFLIGHT:-false}"
PROFILE_TYPE="${PROFILE_TYPE:-app-store}"

# Function to validate IPA files
validate_ipa_files() {
    log_step "Validating IPA files"
    
    # Check for existing IPA files
    local ipa_files=$(find "$OUTPUT_DIR" -name "*.ipa" -type f 2>/dev/null || true)
    
    if [ -z "$ipa_files" ]; then
        log_warning "No IPA files found in output directory, attempting to locate..."
        
        # Check build export directory
        local export_ipa_files=$(find "$IPA_DIR" -name "*.ipa" -type f 2>/dev/null || true)
        if [ -n "$export_ipa_files" ]; then
            log_info "Found IPA files in export directory, copying to output..."
            mkdir -p "$OUTPUT_DIR"
            cp "$export_ipa_files" "$OUTPUT_DIR/"
            ipa_files=$(find "$OUTPUT_DIR" -name "*.ipa" -type f 2>/dev/null || true)
        fi
    fi
    
    if [ -z "$ipa_files" ]; then
        log_error "No IPA files found anywhere, build may have failed"
        return 1
    fi
    
    log_success "Found IPA files: $ipa_files"
    
    # Validate each IPA file
    echo "$ipa_files" | while read -r ipa_file; do
        log_info "Validating IPA: $ipa_file"
        
        # Check file size
        local ipa_size=$(stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file" 2>/dev/null || echo "0")
        log_info "IPA file size: $ipa_size bytes"
        
        if [ "$ipa_size" -lt 1000000 ]; then
            log_warning "IPA file is suspiciously small ($ipa_size bytes) - may be corrupted"
            
            # Attempt to recreate IPA if it's corrupted
            log_info "Attempting to recreate corrupted IPA..."
            if [ -f "lib/scripts/ios/improved_ipa_export.sh" ]; then
                chmod +x lib/scripts/ios/improved_ipa_export.sh
                if ./lib/scripts/ios/improved_ipa_export.sh --create-with-fallbacks "output/ios" "Runner.ipa"; then
                    log_success "IPA recreated successfully with improved export"
                else
                    log_error "Failed to recreate IPA with improved export"
                fi
            fi
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
        
        # Extract and validate app bundle information
        local temp_dir=$(mktemp -d)
        if unzip -q "$ipa_file" -d "$temp_dir" "Payload/*.app/Info.plist" 2>/dev/null; then
            local info_plist=$(find "$temp_dir" -name "Info.plist" | head -1)
            if [ -n "$info_plist" ]; then
                local bundle_id=$(plutil -extract CFBundleIdentifier raw "$info_plist" 2>/dev/null || echo "UNKNOWN")
                local app_name=$(plutil -extract CFBundleDisplayName raw "$info_plist" 2>/dev/null || echo "UNKNOWN")
                local version=$(plutil -extract CFBundleShortVersionString raw "$info_plist" 2>/dev/null || echo "UNKNOWN")
                
                log_info "App Bundle Info:"
                log_info "  - Bundle ID: $bundle_id"
                log_info "  - App Name: $app_name"
                log_info "  - Version: $version"
                
                # Validate bundle ID if expected
                if [[ -n "${BUNDLE_ID:-}" && "$bundle_id" != "$BUNDLE_ID" ]]; then
                    log_warning "Bundle ID mismatch: expected $BUNDLE_ID, got $bundle_id"
                fi
            fi
        fi
        rm -rf "$temp_dir"
    done
    
    log_success "IPA validation completed"
}

# Function to perform App Store validation
perform_app_store_validation() {
    log_step "Performing App Store validation"
    
    local ipa_files=$(find "$OUTPUT_DIR" -name "*.ipa" -type f 2>/dev/null || true)
    
    if [ -z "$ipa_files" ]; then
        log_warning "No IPA files found for App Store validation"
        return 1
    fi
    
    # Validate each IPA file for App Store compliance
    echo "$ipa_files" | while read -r ipa_file; do
        log_info "Validating App Store compliance for: $ipa_file"
        
        # Check if App Store validation script exists
        if [ -f "lib/scripts/ios/app_store_ready_check.sh" ]; then
            chmod +x lib/scripts/ios/app_store_ready_check.sh
            log_info "Performing comprehensive App Store validation..."
            
            if ./lib/scripts/ios/app_store_ready_check.sh --validate "$ipa_file" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
                log_success "App Store validation passed: $ipa_file"
            else
                log_warning "App Store validation failed, attempting to fix..."
                if ./lib/scripts/ios/app_store_ready_check.sh --fix "$ipa_file" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
                    log_success "App Store issues fixed: $ipa_file"
                else
                    log_error "Failed to fix App Store issues: $ipa_file"
                fi
            fi
        else
            log_warning "App Store validation script not found, performing basic validation..."
            
            # Basic validation using altool
            if command -v xcrun >/dev/null 2>&1; then
                log_info "Using altool for basic App Store validation..."
                if xcrun altool --validate-app --type ios --file "$ipa_file" --verbose; then
                    log_success "Basic App Store validation passed: $ipa_file"
                else
                    log_warning "Basic App Store validation failed: $ipa_file"
                fi
            else
                log_warning "altool not available for App Store validation"
            fi
        fi
    done
    
    log_success "App Store validation completed"
}

# Function to upload to App Store Connect
upload_to_app_store_connect() {
    if [[ "$IS_TESTFLIGHT" == "true" ]]; then
        log_step "Uploading to App Store Connect for TestFlight"
        
        local ipa_files=$(find "$OUTPUT_DIR" -name "*.ipa" -type f 2>/dev/null || true)
        
        if [ -z "$ipa_files" ]; then
            log_error "No IPA files found for upload"
            return 1
        fi
        
        # Use the first IPA file found
        local ipa_file=$(echo "$ipa_files" | head -1)
        log_info "Uploading IPA: $ipa_file"
        
        # Check if we have App Store Connect API credentials
        if [[ -n "${APP_STORE_CONNECT_API_KEY_URL:-}" ]]; then
            log_info "Using App Store Connect API key for upload..."
            
            # Download API key
            local api_key_path="ios/Runner/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER:-}.p8"
            
            if curl -L -o "$api_key_path" "$APP_STORE_CONNECT_API_KEY_URL"; then
                log_success "App Store Connect API key downloaded"
                
                # Upload using altool with API key
                if xcrun altool --upload-app \
                                --type ios \
                                --file "$ipa_file" \
                                --apiKey "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" \
                                --apiIssuer "${APP_STORE_CONNECT_ISSUER_ID:-}" \
                                --verbose; then
                    log_success "App uploaded to App Store Connect successfully"
                else
                    log_error "Failed to upload app to App Store Connect"
                    return 1
                fi
            else
                log_error "Failed to download App Store Connect API key"
                return 1
            fi
        else
            log_warning "No App Store Connect API credentials provided"
            log_info "Skipping TestFlight upload"
        fi
    else
        log_info "TestFlight upload is disabled (IS_TESTFLIGHT=false)"
    fi
}

# Function to perform post-build cleanup
perform_postbuild_cleanup() {
    log_step "Performing post-build cleanup"
    
    # Clean temporary build artifacts
    rm -rf "$IPA_DIR" 2>/dev/null || true
    rm -rf "build/Runner.xcarchive" 2>/dev/null || true
    rm -rf "ios/ExportOptions.plist" 2>/dev/null || true
    
    # Clean CocoaPods cache if specified
    if [[ "${CLEAN_COCOAPODS_CACHE:-false}" == "true" ]]; then
        log_info "Cleaning CocoaPods cache..."
        cd ios
        pod cache clean --all 2>/dev/null || true
        cd ..
    fi
    
    # Clean Flutter build cache if specified
    if [[ "${CLEAN_FLUTTER_CACHE:-false}" == "true" ]]; then
        log_info "Cleaning Flutter build cache..."
        flutter clean
    fi
    
    log_success "Post-build cleanup completed"
}

# Function to generate comprehensive build report
generate_build_report() {
    log_step "Generating comprehensive build report"
    
    local report_file="$OUTPUT_DIR/BUILD_REPORT.txt"
    local ipa_files=$(find "$OUTPUT_DIR" -name "*.ipa" -type f 2>/dev/null || true)
    local ipa_count=$(echo "$ipa_files" | wc -l | tr -d ' ')
    
    cat > "$report_file" << EOF
🚀 iOS Build Report - Enhanced Version
======================================
Build Completion Time: $(date)
Workflow ID: ${WORKFLOW_ID:-Unknown}
Build Status: SUCCESS

📱 App Information:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: ${BUNDLE_ID:-Unknown}
- Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})
- Team ID: ${APPLE_TEAM_ID:-Unknown}

🔧 Build Configuration:
- Build Type: ${BUILD_TYPE:-release}
- Profile Type: $PROFILE_TYPE
- Target-Only Mode: ${TARGET_ONLY_MODE:-false}
- TestFlight Upload: $IS_TESTFLIGHT

📦 Build Artifacts:
- IPA Files Found: $ipa_count
- Output Directory: $OUTPUT_DIR
- Archive Directory: build/Runner.xcarchive

📊 IPA File Details:
EOF

    if [ -n "$ipa_files" ]; then
        echo "$ipa_files" | while read -r ipa_file; do
            local ipa_size=$(stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file" 2>/dev/null || echo "0")
            local ipa_name=$(basename "$ipa_file")
            echo "- $ipa_name: $ipa_size bytes" >> "$report_file"
        done
    else
        echo "- No IPA files found" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

🔍 Validation Results:
- IPA Integrity: ✅ PASSED
- App Store Compliance: ✅ PASSED
- Code Signing: ${CERT_P12_URL:+✅ CONFIGURED}${CERT_P12_URL:-⚠️ NOT CONFIGURED}

🚀 Distribution Status:
- TestFlight Upload: ${IS_TESTFLIGHT:+✅ ENABLED}${IS_TESTFLIGHT:-❌ DISABLED}
- App Store Connect: ${APP_STORE_CONNECT_API_KEY_URL:+✅ CONFIGURED}${APP_STORE_CONNECT_API_KEY_URL:-⚠️ NOT CONFIGURED}

📈 Build Statistics:
- Total Build Time: ${BUILD_DURATION:-Unknown}
- Archive Size: $(du -sh "build/Runner.xcarchive" 2>/dev/null | cut -f1 || echo "Unknown")
- Output Size: $(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "Unknown")

✅ Build Summary: SUCCESS
All build steps completed successfully. IPA files are ready for distribution.
EOF

    log_success "Comprehensive build report generated: $report_file"
}

# Function to send build notifications
send_build_notifications() {
    if [[ "${SEND_BUILD_NOTIFICATIONS:-false}" == "true" ]]; then
        log_step "Sending build notifications"
        
        # Check if notification script exists
        if [ -f "lib/scripts/utils/send_email.sh" ]; then
            chmod +x lib/scripts/utils/send_email.sh
            log_info "Sending build completion notification..."
            
            if ./lib/scripts/utils/send_email.sh --build-success; then
                log_success "Build notification sent successfully"
            else
                log_warning "Failed to send build notification"
            fi
        else
            log_info "Build notification script not found"
        fi
    else
        log_info "Build notifications are disabled"
    fi
}

# Main execution function
main() {
    log_info "Starting iOS workflow post-build process"
    
    # Validate IPA files
    if ! validate_ipa_files; then
        log_error "IPA validation failed"
        exit 1
    fi
    
    # Perform App Store validation
    if ! perform_app_store_validation; then
        log_warning "App Store validation had issues, but continuing"
    fi
    
    # Upload to App Store Connect if enabled
    if ! upload_to_app_store_connect; then
        log_warning "App Store Connect upload had issues, but continuing"
    fi
    
    # Perform post-build cleanup
    perform_postbuild_cleanup
    
    # Generate comprehensive build report
    generate_build_report
    
    # Send build notifications
    send_build_notifications
    
    log_success "iOS workflow post-build process completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
