#!/bin/bash

# 🚀 iOS Workflow Main Script - Upgraded Version for Codemagic CI/CD
# Orchestrates complete iOS build process including code signing and App Store distribution

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow - Complete Enhanced Build Process"

# Configuration
BUILD_TYPE="${BUILD_TYPE:-release}"
PROFILE_TYPE="${PROFILE_TYPE:-app-store}"
TARGET_ONLY_MODE="${TARGET_ONLY_MODE:-false}"
MAX_RETRIES="${MAX_RETRIES:-2}"
IS_TESTFLIGHT="${IS_TESTFLIGHT:-false}"
SEND_BUILD_NOTIFICATIONS="${SEND_BUILD_NOTIFICATIONS:-false}"

# Script paths
PRE_BUILD_SCRIPT="$(dirname "$0")/pre-build.sh"
BUILD_SCRIPT="$(dirname "$0")/build.sh"
POST_BUILD_SCRIPT="$(dirname "$0")/post-build.sh"

# Function to display workflow configuration
display_workflow_config() {
    log_step "Workflow Configuration"
    
    echo "🚀 iOS Workflow Configuration:"
    echo "  - Build Type: $BUILD_TYPE"
    echo "  - Profile Type: $PROFILE_TYPE"
    echo "  - Target-Only Mode: $TARGET_ONLY_MODE"
    echo "  - Max Retries: $MAX_RETRIES"
    echo "  - TestFlight Upload: $IS_TESTFLIGHT"
    echo "  - Build Notifications: $SEND_BUILD_NOTIFICATIONS"
    echo ""
    echo "📁 Script Paths:"
    echo "  - Pre-Build: $PRE_BUILD_SCRIPT"
    echo "  - Build: $BUILD_SCRIPT"
    echo "  - Post-Build: $POST_BUILD_SCRIPT"
}

# Function to validate script availability
validate_scripts() {
    log_step "Validating workflow scripts"
    
    local missing_scripts=()
    
    # Check pre-build script
    if [ ! -f "$PRE_BUILD_SCRIPT" ]; then
        missing_scripts+=("pre-build.sh")
    fi
    
    # Check build script
    if [ ! -f "$BUILD_SCRIPT" ]; then
        missing_scripts+=("build.sh")
    fi
    
    # Check post-build script
    if [ ! -f "$POST_BUILD_SCRIPT" ]; then
        missing_scripts+=("post-build.sh")
    fi
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        log_error "Missing required scripts: ${missing_scripts[*]}"
        return 1
    fi
    
    # Make scripts executable
    chmod +x "$PRE_BUILD_SCRIPT"
    chmod +x "$BUILD_SCRIPT"
    chmod +x "$POST_BUILD_SCRIPT"
    
    log_success "All workflow scripts are available and executable"
}

# Function to execute pre-build phase
execute_prebuild_phase() {
    log_step "Executing Pre-Build Phase"
    
    if [ -f "$PRE_BUILD_SCRIPT" ]; then
        log_info "Running pre-build script: $PRE_BUILD_SCRIPT"
        
        # Set environment variables for pre-build
        export BUILD_TYPE="$BUILD_TYPE"
        export PROFILE_TYPE="$PROFILE_TYPE"
        export TARGET_ONLY_MODE="$TARGET_ONLY_MODE"
        
        if bash "$PRE_BUILD_SCRIPT"; then
            log_success "Pre-build phase completed successfully"
        else
            log_error "Pre-build phase failed"
            return 1
        fi
    else
        log_error "Pre-build script not found: $PRE_BUILD_SCRIPT"
        return 1
    fi
}

# Function to execute build phase
execute_build_phase() {
    log_step "Executing Build Phase"
    
    if [ -f "$BUILD_SCRIPT" ]; then
        log_info "Running build script: $BUILD_SCRIPT"
        
        # Set environment variables for build
        export BUILD_TYPE="$BUILD_TYPE"
        export OUTPUT_DIR="output/ios"
        export BUILD_DIR="build/ios"
        export ARCHIVE_DIR="build/Runner.xcarchive"
        export IPA_DIR="build/export"
        export TARGET_ONLY_MODE="$TARGET_ONLY_MODE"
        export MAX_RETRIES="$MAX_RETRIES"
        
        if bash "$BUILD_SCRIPT"; then
            log_success "Build phase completed successfully"
        else
            log_error "Build phase failed"
            return 1
        fi
    else
        log_error "Build script not found: $BUILD_SCRIPT"
        return 1
    fi
}

# Function to execute post-build phase
execute_postbuild_phase() {
    log_step "Executing Post-Build Phase"
    
    if [ -f "$POST_BUILD_SCRIPT" ]; then
        log_info "Running post-build script: $POST_BUILD_SCRIPT"
        
        # Set environment variables for post-build
        export OUTPUT_DIR="output/ios"
        export IPA_DIR="build/export"
        export IS_TESTFLIGHT="$IS_TESTFLIGHT"
        export PROFILE_TYPE="$PROFILE_TYPE"
        export SEND_BUILD_NOTIFICATIONS="$SEND_BUILD_NOTIFICATIONS"
        
        if bash "$POST_BUILD_SCRIPT"; then
            log_success "Post-build phase completed successfully"
        else
            log_error "Post-build phase failed"
            return 1
        fi
    else
        log_error "Post-build script not found: $POST_BUILD_SCRIPT"
        return 1
    fi
}

# Function to generate workflow summary
generate_workflow_summary() {
    log_step "Generating Workflow Summary"
    
    local summary_file="output/ios/WORKFLOW_SUMMARY.txt"
    local start_time="${WORKFLOW_START_TIME:-$(date)}"
    local end_time=$(date)
    
    cat > "$summary_file" << EOF
🚀 iOS Workflow Summary - Enhanced Version
==========================================
Workflow Execution Time: $start_time to $end_time
Workflow ID: ${WORKFLOW_ID:-Unknown}
Overall Status: SUCCESS

📋 Phase Execution Summary:
✅ Pre-Build Phase: COMPLETED
✅ Build Phase: COMPLETED
✅ Post-Build Phase: COMPLETED

🔧 Workflow Configuration:
- Build Type: $BUILD_TYPE
- Profile Type: $PROFILE_TYPE
- Target-Only Mode: $TARGET_ONLY_MODE
- Max Retries: $MAX_RETRIES
- TestFlight Upload: $IS_TESTFLIGHT
- Build Notifications: $SEND_BUILD_NOTIFICATIONS

📱 Build Results:
- Output Directory: output/ios
- IPA Files: $(find output/ios -name "*.ipa" -type f 2>/dev/null | wc -l | tr -d ' ') files
- Build Reports: $(find output/ios -name "*REPORT*.txt" -type f 2>/dev/null | wc -l | tr -d ' ') files

🚀 Next Steps:
1. Review build artifacts in output/ios/
2. Validate IPA files for distribution
3. Upload to TestFlight if enabled
4. Submit to App Store when ready

✅ Workflow completed successfully!
EOF

    log_success "Workflow summary generated: $summary_file"
}

# Function to handle workflow errors
handle_workflow_error() {
    local phase="$1"
    local exit_code="$2"
    
    log_error "Workflow failed during $phase phase with exit code: $exit_code"
    
    # Generate error report
    local error_file="output/ios/WORKFLOW_ERROR.txt"
    mkdir -p "$(dirname "$error_file")"
    
    cat > "$error_file" << EOF
❌ iOS Workflow Error Report
============================
Error Time: $(date)
Failed Phase: $phase
Exit Code: $exit_code
Workflow ID: ${WORKFLOW_ID:-Unknown}

🔍 Error Details:
- Phase: $phase
- Exit Code: $exit_code
- Build Type: $BUILD_TYPE
- Profile Type: $PROFILE_TYPE

📋 Troubleshooting Steps:
1. Check build logs for specific error messages
2. Verify environment variables and configuration
3. Check iOS project settings and certificates
4. Review CocoaPods dependencies
5. Validate code signing configuration

📞 Support Information:
- Workflow: ${WORKFLOW_ID:-Unknown}
- Build: ${BUILD_NUMBER:-Unknown}
- Commit: ${COMMIT_HASH:-Unknown}

❌ Workflow Status: FAILED
EOF

    log_error "Error report generated: $error_file"
    
    # Send error notification if enabled
    if [[ "$SEND_BUILD_NOTIFICATIONS" == "true" ]]; then
        if [ -f "lib/scripts/utils/send_email.sh" ]; then
            chmod +x lib/scripts/utils/send_email.sh
            log_info "Sending error notification..."
            ./lib/scripts/utils/send_email.sh --build-failure --phase "$phase" --exit-code "$exit_code" || true
        fi
    fi
}

# Function to cleanup workflow artifacts
cleanup_workflow_artifacts() {
    log_step "Cleaning up workflow artifacts"
    
    # Clean temporary files
    rm -rf "ios/ExportOptions.plist" 2>/dev/null || true
    rm -rf "build/export" 2>/dev/null || true
    
    # Keep archive for debugging if specified
    if [[ "${KEEP_ARCHIVE_FOR_DEBUG:-false}" != "true" ]]; then
        rm -rf "build/Runner.xcarchive" 2>/dev/null || true
    else
        log_info "Keeping archive for debugging purposes"
    fi
    
    log_success "Workflow cleanup completed"
}

# Main execution function
main() {
    local workflow_start_time=$(date)
    export WORKFLOW_START_TIME="$workflow_start_time"
    
    log_info "Starting iOS workflow execution at: $workflow_start_time"
    
    # Display workflow configuration
    display_workflow_config
    
    # Validate script availability
    if ! validate_scripts; then
        log_error "Script validation failed"
        exit 1
    fi
    
    # Execute pre-build phase
    if ! execute_prebuild_phase; then
        handle_workflow_error "pre-build" $?
        exit 1
    fi
    
    # Execute build phase
    if ! execute_build_phase; then
        handle_workflow_error "build" $?
        exit 1
    fi
    
    # Execute post-build phase
    if ! execute_postbuild_phase; then
        handle_workflow_error "post-build" $?
        exit 1
    fi
    
    # Generate workflow summary
    generate_workflow_summary
    
    # Cleanup workflow artifacts
    cleanup_workflow_artifacts
    
    log_success "iOS workflow execution completed successfully!"
    log_info "Workflow duration: $workflow_start_time to $(date)"
    
    # Display final status
    echo ""
    echo "🎉 iOS Workflow Completed Successfully!"
    echo "📱 Build artifacts available in: output/ios/"
    echo "📋 Summary reports generated"
    echo "🚀 Ready for distribution!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
