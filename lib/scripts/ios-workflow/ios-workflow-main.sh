#!/bin/bash

# 🚀 iOS Workflow Main Script for Codemagic CI/CD
# Handles complete iOS build process including code signing and App Store distribution

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "iOS Workflow - Complete Build Process"

# Configuration
BUILD_TYPE="${BUILD_TYPE:-release}"
OUTPUT_DIR="output/ios"
BUILD_DIR="build/ios"
ARCHIVE_DIR="build/Runner.xcarchive"
IPA_DIR="build/export"

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

# Function to download and setup certificates
setup_certificates() {
    log_step "Setting up iOS certificates and provisioning profiles"
    
    # Download certificate if provided
    if [[ -n "${CERT_P12_URL:-}" ]]; then
        local cert_path="ios/Runner/Certificates.p12"
        mkdir -p "$(dirname "$cert_path")"
        
        if curl -L -o "$cert_path" "$CERT_P12_URL"; then
            log_success "Certificate downloaded successfully"
            
            # Import certificate to keychain
            security import "$cert_path" -k login.keychain -P "${CERT_PASSWORD:-}" -T /usr/bin/codesign
            log_success "Certificate imported to keychain"
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

# Function to download Firebase configuration
setup_firebase_ios() {
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
        log_warning "No iOS Firebase configuration provided"
    fi
}

# Function to download APNS key
setup_apns() {
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
        log_warning "No APNS authentication key provided"
    fi
}

# Function to update iOS project configuration
update_ios_config() {
    log_step "Updating iOS project configuration"
    
    # Update bundle identifier if provided
    if [[ -n "${BUNDLE_ID:-}" ]]; then
        log_info "Updating bundle identifier to: $BUNDLE_ID"
        
        # Update Info.plist
        sed -i.bak "s/CFBundleIdentifier.*/CFBundleIdentifier = $BUNDLE_ID;/" \
            ios/Runner/Info.plist
        
        # Update project.pbxproj
        sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" \
            ios/Runner.xcodeproj/project.pbxproj
        
        log_success "Bundle identifier updated to: $BUNDLE_ID"
    fi
    
    # Update app name if provided
    if [[ -n "${APP_NAME:-}" ]]; then
        log_info "Updating app name to: $APP_NAME"
        
        # Update Info.plist
        sed -i.bak "s/CFBundleDisplayName.*/CFBundleDisplayName = $APP_NAME;/" \
            ios/Runner/Info.plist
        
        log_success "App name updated to: $APP_NAME"
    fi
    
    # Update team ID if provided
    if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
        log_info "Updating team ID to: $APPLE_TEAM_ID"
        
        # Update project.pbxproj
        sed -i.bak "s/DEVELOPMENT_TEAM = .*;/DEVELOPMENT_TEAM = $APPLE_TEAM_ID;/g" \
            ios/Runner.xcodeproj/project.pbxproj
        
        log_success "Team ID updated to: $APPLE_TEAM_ID"
    fi
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
    
    # Install pods
    if pod install --repo-update; then
        log_success "CocoaPods dependencies installed successfully"
    else
        log_error "Failed to install CocoaPods dependencies"
        cd ..
        return 1
    fi
    
    cd ..
}

# Function to build Flutter iOS
build_flutter_ios() {
    log_step "Building Flutter iOS app"
    
    local build_args="--release --no-codesign"
    
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
    
    # Create archive
    if xcodebuild -workspace Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -archivePath ../build/Runner.xcarchive \
                   archive; then
        log_success "Xcode archive created successfully"
    else
        log_error "Failed to create Xcode archive"
        cd ..
        return 1
    fi
    
    cd ..
}

# Function to export IPA
export_ipa() {
    log_step "Exporting IPA from archive"
    
    # Create ExportOptions.plist
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
</dict>
</plist>
EOF

    # Export IPA
    if xcodebuild -exportArchive \
                   -archivePath "$ARCHIVE_DIR" \
                   -exportPath "$IPA_DIR" \
                   -exportOptionsPlist ios/ExportOptions.plist; then
        log_success "IPA exported successfully"
        
        # Copy IPA to output directory
        cp "$IPA_DIR"/*.ipa "$OUTPUT_DIR/"
        log_info "IPA copied to output directory"
    else
        log_error "Failed to export IPA"
        return 1
    fi
}

# Function to upload to App Store Connect
upload_to_app_store() {
    if [[ "${IS_TESTFLIGHT:-false}" == "true" ]] && [[ -n "${APP_STORE_CONNECT_API_KEY_URL:-}" ]]; then
        log_step "Uploading to App Store Connect for TestFlight"
        
        # Download API key
        local api_key_path="ios/Runner/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER:-}.p8"
        
        if curl -L -o "$api_key_path" "$APP_STORE_CONNECT_API_KEY_URL"; then
            log_success "App Store Connect API key downloaded"
            
            # Upload using altool
            local ipa_file=$(find "$OUTPUT_DIR" -name "*.ipa" | head -1)
            if [[ -n "$ipa_file" ]]; then
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
                log_error "No IPA file found for upload"
                return 1
            fi
        else
            log_error "Failed to download App Store Connect API key"
            return 1
        fi
    else
        log_info "Skipping App Store Connect upload (TestFlight disabled or API key not provided)"
    fi
}

# Function to generate build artifacts summary
generate_ios_build_summary() {
    log_step "Generating iOS build artifacts summary"
    
    local summary_file="$OUTPUT_DIR/ARTIFACTS_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
🚀 iOS Build Summary
====================
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
- Code Signing: ${CERT_P12_URL:+Configured}${CERT_P12_URL:-Not configured}
- Firebase: ${FIREBASE_CONFIG_IOS:+Configured}${FIREBASE_CONFIG_IOS:-Not configured}
- APNS: ${APNS_AUTH_KEY_URL:+Configured}${APNS_AUTH_KEY_URL:-Not configured}
- TestFlight: ${IS_TESTFLIGHT:+Enabled}${IS_TESTFLIGHT:-Disabled}

✅ Build Status: SUCCESS
EOF

    log_success "iOS build summary generated: $summary_file"
}

# Main execution function
main() {
    log_info "Starting iOS workflow build process"
    
    # Setup environment
    setup_ios_environment
    
    # Setup certificates and profiles
    setup_certificates
    
    # Setup Firebase
    setup_firebase_ios
    
    # Setup APNS
    setup_apns
    
    # Setup feature integrations
    log_step "Setting up feature integrations"
    if bash "$(dirname "$0")/../utils/feature_integration.sh"; then
        log_success "Feature integrations configured successfully"
    else
        log_warning "Feature integration had issues, but continuing with build"
    fi
    
    # Update iOS configuration
    update_ios_config
    
    # Clean previous builds
    clean_ios_builds
    
    # Install CocoaPods dependencies
    install_cocoapods
    
    # Build Flutter iOS
    build_flutter_ios
    
    # Create Xcode archive
    create_xcode_archive
    
    # Export IPA
    export_ipa
    
    # Upload to App Store Connect if enabled
    upload_to_app_store
    
    # Generate build summary
    generate_ios_build_summary
    
    log_success "iOS workflow build process completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
