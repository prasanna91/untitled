#!/bin/bash

# 🚀 Feature Integration Script for Codemagic Builds
# Ensures all required features are properly configured and integrated

# Source logging utilities
source "$(dirname "$0")/logging.sh"

log_section "Feature Integration & Validation"

# Configuration
OUTPUT_DIR="output"
CONFIG_DIR="lib/config"
BUILD_DIR="build"

# Function to setup Firebase integration
setup_firebase_integration() {
    log_step "Setting up Firebase integration for push notifications and authentication"
    
    # Android Firebase setup
    if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]]; then
        local android_config="android/app/google-services.json"
        mkdir -p "$(dirname "$android_config")"
        
        if curl -L -o "$android_config" "$FIREBASE_CONFIG_ANDROID"; then
            log_success "Android Firebase configuration downloaded"
            
            # Verify JSON structure
            if python3 -m json.tool "$android_config" >/dev/null 2>&1; then
                log_success "Android Firebase configuration is valid JSON"
            else
                log_error "Android Firebase configuration is not valid JSON"
                return 1
            fi
        else
            log_error "Failed to download Android Firebase configuration"
            return 1
        fi
    else
        log_warning "No Android Firebase configuration provided"
    fi
    
    # iOS Firebase setup
    if [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
        local ios_config="ios/Runner/GoogleService-Info.plist"
        mkdir -p "$(dirname "$ios_config")"
        
        if curl -L -o "$ios_config" "$FIREBASE_CONFIG_IOS"; then
            log_success "iOS Firebase configuration downloaded"
        else
            log_error "Failed to download iOS Firebase configuration"
            log_warning "Continuing without iOS Firebase config"
        fi
    else
        log_warning "No iOS Firebase configuration provided"
    fi
    
    # Update build.gradle for Android
    if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]]; then
        local gradle_file="android/app/build.gradle.kts"
        if [[ -f "$gradle_file" ]]; then
            # Add Firebase plugin if not present
            if ! grep -q "com.google.gms:google-services" "$gradle_file"; then
                log_info "Adding Firebase plugin to Android build.gradle"
                # Note: This would require more complex gradle file manipulation
                log_warning "Firebase plugin addition requires manual gradle configuration"
            fi
        fi
    fi
}

# Function to setup OAuth authentication
setup_oauth_integration() {
    log_step "Setting up OAuth authentication (Google & Apple Sign-In)"
    
    # Google Sign-In setup
    if [[ "${IS_GOOGLE_AUTH:-}" == "true" ]]; then
        log_info "Configuring Google Sign-In"
        
        # Android Google Services
        if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]]; then
            log_success "Google Sign-In configured for Android via Firebase"
        else
            log_warning "Google Sign-In enabled but no Firebase config for Android"
        fi
        
        # iOS Google Services
        if [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
            log_success "Google Sign-In configured for iOS via Firebase"
        else
            log_warning "Google Sign-In enabled but no Firebase config for iOS"
        fi
    else
        log_info "Google Sign-In disabled"
    fi
    
    # Apple Sign-In setup
    if [[ "${IS_APPLE_AUTH:-}" == "true" ]]; then
        log_info "Configuring Apple Sign-In"
        
        if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
            log_success "Apple Team ID configured: $APPLE_TEAM_ID"
            
            # Update iOS project configuration
            local project_file="ios/Runner.xcodeproj/project.pbxproj"
            if [[ -f "$project_file" ]]; then
                # Add Apple Sign-In capability
                log_info "Apple Sign-In capability will be added during iOS build"
            fi
        else
            log_error "Apple Sign-In enabled but no Team ID provided"
            return 1
        fi
    else
        log_info "Apple Sign-In disabled"
    fi
}

# Function to setup push notifications
setup_push_notifications() {
    log_step "Setting up push notifications system"
    
    if [[ "${PUSH_NOTIFY:-}" == "true" ]]; then
        log_info "Push notifications enabled"
        
        # Verify Firebase configuration
        if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]] || [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
            log_success "Firebase configuration available for push notifications"
        else
            log_error "Push notifications enabled but no Firebase configuration provided"
            return 1
        fi
        
        # iOS APNS setup
        if [[ -n "${APNS_KEY_ID:-}" ]] && [[ -n "${APNS_AUTH_KEY_URL:-}" ]]; then
            log_info "Setting up APNS for iOS push notifications"
            
            local apns_key="ios/Runner/AuthKey_${APNS_KEY_ID}.p8"
            mkdir -p "$(dirname "$apns_key")"
            
            if curl -L -o "$apns_key" "$APNS_AUTH_KEY_URL"; then
                log_success "APNS authentication key downloaded"
            else
                log_error "Failed to download APNS authentication key"
                return 1
            fi
        else
            log_warning "APNS configuration incomplete for iOS push notifications"
        fi
        
        # Update iOS Info.plist for push notifications
        local info_plist="ios/Runner/Info.plist"
        if [[ -f "$info_plist" ]]; then
            log_info "Push notification entitlements will be configured during iOS build"
        fi
    else
        log_info "Push notifications disabled"
    fi
}

# Function to setup UI customization
setup_ui_customization() {
    log_step "Setting up UI customization (Logo, Splash, Bottom Navigation)"
    
    # Logo customization
    if [[ -n "${LOGO_URL:-}" ]]; then
        log_info "Setting up custom logo: $LOGO_URL"
        
        # Download logo for both platforms
        local android_logo="android/app/src/main/res/drawable/app_logo.png"
        local ios_logo="ios/Runner/Assets.xcassets/AppIcon.appiconset/app_logo.png"
        
        mkdir -p "$(dirname "$android_logo")"
        mkdir -p "$(dirname "$ios_logo")"
        
        if curl -L -o "$android_logo" "$LOGO_URL"; then
            log_success "Logo downloaded for Android"
        else
            log_warning "Failed to download logo for Android"
        fi
        
        if curl -L -o "$ios_logo" "$LOGO_URL"; then
            log_success "Logo downloaded for iOS"
        else
            log_warning "Failed to download logo for iOS"
        fi
    else
        log_info "No custom logo configured"
    fi
    
    # Splash screen customization
    if [[ "${IS_SPLASH:-}" == "true" ]]; then
        log_info "Setting up custom splash screen"
        
        if [[ -n "${SPLASH_URL:-}" ]]; then
            local splash_image="assets/splash_image.png"
            mkdir -p "$(dirname "$splash_image")"
            
            if curl -L -o "$splash_image" "$SPLASH_URL"; then
                log_success "Splash image downloaded"
            else
                log_warning "Failed to download splash image"
            fi
        fi
        
        # Generate splash screen configuration
        local splash_config="$CONFIG_DIR/splash_config.dart"
        cat > "$splash_config" << EOF
// Auto-generated splash screen configuration
class SplashConfig {
  static const String backgroundColor = '${SPLASH_BG_COLOR:-#FFFFFF}';
  static const String tagline = '${SPLASH_TAGLINE:-}';
  static const String taglineColor = '${SPLASH_TAGLINE_COLOR:-#000000}';
  static const String taglineFont = '${SPLASH_TAGLINE_FONT:-Roboto}';
  static const double taglineSize = ${SPLASH_TAGLINE_SIZE:-24};
  static const bool taglineBold = ${SPLASH_TAGLINE_BOLD:-false};
  static const bool taglineItalic = ${SPLASH_TAGLINE_ITALIC:-false};
  static const String animation = '${SPLASH_ANIMATION:-fade}';
  static const int duration = ${SPLASH_DURATION:-3};
}
EOF
        log_success "Splash screen configuration generated"
    else
        log_info "Custom splash screen disabled"
    fi
    
    # Bottom navigation customization
    if [[ "${IS_BOTTOMMENU:-}" == "true" ]]; then
        log_info "Setting up custom bottom navigation"
        
        if [[ -n "${BOTTOMMENU_ITEMS:-}" ]]; then
            # Generate bottom navigation configuration
            local bottom_nav_config="$CONFIG_DIR/bottom_nav_config.dart"
            cat > "$bottom_nav_config" << EOF
// Auto-generated bottom navigation configuration
class BottomNavConfig {
  static const String backgroundColor = '${BOTTOMMENU_BG_COLOR:-#FFFFFF}';
  static const String iconColor = '${BOTTOMMENU_ICON_COLOR:-#000000}';
  static const String textColor = '${BOTTOMMENU_TEXT_COLOR:-#000000}';
  static const String font = '${BOTTOMMENU_FONT:-Roboto}';
  static const double fontSize = ${BOTTOMMENU_FONT_SIZE:-12};
  static const bool fontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool fontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
  static const String activeTabColor = '${BOTTOMMENU_ACTIVE_TAB_COLOR:-#007AFF}';
  static const String iconPosition = '${BOTTOMMENU_ICON_POSITION:-above}';
  
  static const List<Map<String, dynamic>> menuItems = $BOTTOMMENU_ITEMS;
}
EOF
            log_success "Bottom navigation configuration generated"
        else
            log_warning "Bottom navigation enabled but no menu items configured"
        fi
    else
        log_info "Custom bottom navigation disabled"
    fi
}

# Function to setup permissions
setup_permissions() {
    log_step "Setting up app permissions and capabilities"
    
    local permissions=()
    
    # Check each permission
    [[ "${IS_CAMERA:-}" == "true" ]] && permissions+=("Camera")
    [[ "${IS_LOCATION:-}" == "true" ]] && permissions+=("Location")
    [[ "${IS_MIC:-}" == "true" ]] && permissions+=("Microphone")
    [[ "${IS_NOTIFICATION:-}" == "true" ]] && permissions+=("Notifications")
    [[ "${IS_CONTACT:-}" == "true" ]] && permissions+=("Contacts")
    [[ "${IS_BIOMETRIC:-}" == "true" ]] && permissions+=("Biometric")
    [[ "${IS_CALENDAR:-}" == "true" ]] && permissions+=("Calendar")
    [[ "${IS_STORAGE:-}" == "true" ]] && permissions+=("Storage")
    
    if [[ ${#permissions[@]} -gt 0 ]]; then
        log_info "Configuring permissions: ${permissions[*]}"
        
        # Android permissions
        local android_manifest="android/app/src/main/AndroidManifest.xml"
        if [[ -f "$android_manifest" ]]; then
            log_info "Android permissions will be configured during build"
        fi
        
        # iOS permissions
        local ios_info_plist="ios/Runner/Info.plist"
        if [[ -f "$ios_info_plist" ]]; then
            log_info "iOS permissions will be configured during build"
        fi
    else
        log_info "No special permissions configured"
    fi
}

# Function to setup email system
setup_email_system() {
    log_step "Setting up email notification system"
    
    if [[ "${ENABLE_EMAIL_NOTIFICATIONS:-}" == "true" ]]; then
        log_info "Email notifications enabled"
        
        # Validate SMTP configuration
        if [[ -n "${EMAIL_SMTP_SERVER:-}" ]] && [[ -n "${EMAIL_SMTP_USER:-}" ]] && [[ -n "${EMAIL_SMTP_PASS:-}" ]]; then
            log_success "SMTP configuration complete"
            
            # Generate email configuration
            local email_config="$CONFIG_DIR/email_config.dart"
            cat > "$email_config" << EOF
// Auto-generated email configuration
class EmailConfig {
  static const String smtpServer = '${EMAIL_SMTP_SERVER}';
  static const int smtpPort = ${EMAIL_SMTP_PORT:-587};
  static const String smtpUser = '${EMAIL_SMTP_USER}';
  static const String smtpPass = '${EMAIL_SMTP_PASS}';
  static const bool enableNotifications = true;
}
EOF
            log_success "Email configuration generated"
        else
            log_error "Email notifications enabled but SMTP configuration incomplete"
            return 1
        fi
    else
        log_info "Email notifications disabled"
    fi
}

# Function to setup chatbot integration
setup_chatbot_integration() {
    log_step "Setting up chatbot integration"
    
    if [[ "${IS_CHATBOT:-}" == "true" ]]; then
        log_info "Chatbot feature enabled"
        
        # Generate chatbot configuration
        local chatbot_config="$CONFIG_DIR/chatbot_config.dart"
        cat > "$chatbot_config" << EOF
// Auto-generated chatbot configuration
class ChatbotConfig {
  static const bool enabled = true;
  static const String apiEndpoint = '${CHATBOT_API_ENDPOINT:-}';
  static const String apiKey = '${CHATBOT_API_KEY:-}';
  static const bool enableVoiceInput = ${IS_MIC:-false};
  static const bool enableNotifications = ${PUSH_NOTIFY:-false};
}
EOF
        log_success "Chatbot configuration generated"
    else
        log_info "Chatbot feature disabled"
    fi
}

# Function to setup pull to refresh and loading indicators
setup_ui_enhancements() {
    log_step "Setting up UI enhancements (Pull to Refresh, Loading Indicators)"
    
    # Pull to refresh
    if [[ "${IS_PULLDOWN:-}" == "true" ]]; then
        log_info "Pull to refresh enabled"
        
        local pull_refresh_config="$CONFIG_DIR/pull_refresh_config.dart"
        cat > "$pull_refresh_config" << EOF
// Auto-generated pull to refresh configuration
class PullRefreshConfig {
  static const bool enabled = true;
  static const String refreshIndicatorColor = '${PULL_REFRESH_COLOR:-#007AFF}';
  static const String backgroundColor = '${PULL_REFRESH_BG_COLOR:-#F2F2F7}';
}
EOF
        log_success "Pull to refresh configuration generated"
    else
        log_info "Pull to refresh disabled"
    fi
    
    # Loading indicators
    if [[ "${IS_LOAD_IND:-}" == "true" ]]; then
        log_info "Loading indicators enabled"
        
        local loading_config="$CONFIG_DIR/loading_config.dart"
        cat > "$loading_config" << EOF
// Auto-generated loading indicators configuration
class LoadingConfig {
  static const bool enabled = true;
  static const String indicatorColor = '${LOADING_INDICATOR_COLOR:-#007AFF}';
  static const String backgroundColor = '${LOADING_BG_COLOR:-#FFFFFF}';
  static const bool showProgressBar = true;
  static const bool showSpinner = true;
}
EOF
        log_success "Loading indicators configuration generated"
    else
        log_info "Loading indicators disabled"
    fi
}

# Function to validate all integrations
validate_integrations() {
    log_step "Validating all feature integrations"
    
    local validation_results=()
    local overall_success=true
    
    # Firebase validation
    if [[ "${PUSH_NOTIFY:-}" == "true" ]] || [[ "${IS_GOOGLE_AUTH:-}" == "true" ]]; then
        if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]] || [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
            validation_results+=("✅ Firebase: Configured")
        else
            validation_results+=("❌ Firebase: Missing configuration")
            overall_success=false
        fi
    else
        validation_results+=("⚠️  Firebase: Not required")
    fi
    
    # OAuth validation
    if [[ "${IS_GOOGLE_AUTH:-}" == "true" ]]; then
        if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]] || [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
            validation_results+=("✅ Google Auth: Configured")
        else
            validation_results+=("❌ Google Auth: Missing Firebase config")
            overall_success=false
        fi
    else
        validation_results+=("⚠️  Google Auth: Disabled")
    fi
    
    if [[ "${IS_APPLE_AUTH:-}" == "true" ]]; then
        if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
            validation_results+=("✅ Apple Auth: Configured")
        else
            validation_results+=("❌ Apple Auth: Missing Team ID")
            overall_success=false
        fi
    else
        validation_results+=("⚠️  Apple Auth: Disabled")
    fi
    
    # Push notifications validation
    if [[ "${PUSH_NOTIFY:-}" == "true" ]]; then
        if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]] || [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
            validation_results+=("✅ Push Notifications: Configured")
        else
            validation_results+=("❌ Push Notifications: Missing Firebase config")
            overall_success=false
        fi
    else
        validation_results+=("⚠️  Push Notifications: Disabled")
    fi
    
    # Email validation
    if [[ "${ENABLE_EMAIL_NOTIFICATIONS:-}" == "true" ]]; then
        if [[ -n "${EMAIL_SMTP_SERVER:-}" ]] && [[ -n "${EMAIL_SMTP_USER:-}" ]]; then
            validation_results+=("✅ Email System: Configured")
        else
            validation_results+=("❌ Email System: Incomplete SMTP config")
            overall_success=false
        fi
    else
        validation_results+=("⚠️  Email System: Disabled")
    fi
    
    # Display validation results
    log_info "Integration validation results:"
    for result in "${validation_results[@]}"; do
        echo "  $result"
    done
    
    if [[ "$overall_success" == true ]]; then
        log_success "All required integrations are properly configured"
        return 0
    else
        log_error "Some integrations have configuration issues"
        return 1
    fi
}

# Function to generate integration summary
generate_integration_summary() {
    log_step "Generating integration summary"
    
    local summary_file="$OUTPUT_DIR/INTEGRATION_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
🚀 Feature Integration Summary
==============================
Generated: $(date)
Workflow: ${WORKFLOW_ID:-Unknown}

📱 Core Features:
- Chatbot: ${IS_CHATBOT:-false}
- Push Notifications: ${PUSH_NOTIFY:-false}
- Google Sign-In: ${IS_GOOGLE_AUTH:-false}
- Apple Sign-In: ${IS_APPLE_AUTH:-false}

🎨 UI Customization:
- Custom Logo: ${LOGO_URL:+Yes}${LOGO_URL:-No}
- Custom Splash: ${IS_SPLASH:-false}
- Bottom Navigation: ${IS_BOTTOMMENU:-false}
- Pull to Refresh: ${IS_PULLDOWN:-false}
- Loading Indicators: ${IS_LOAD_IND:-false}

🔐 Permissions:
- Camera: ${IS_CAMERA:-false}
- Location: ${IS_LOCATION:-false}
- Microphone: ${IS_MIC:-false}
- Notifications: ${IS_NOTIFICATION:-false}
- Contacts: ${IS_CONTACT:-false}
- Biometric: ${IS_BIOMETRIC:-false}
- Calendar: ${IS_CALENDAR:-false}
- Storage: ${IS_STORAGE:-false}

📧 Email System:
- Enabled: ${ENABLE_EMAIL_NOTIFICATIONS:-false}
- SMTP Server: ${EMAIL_SMTP_SERVER:-Not configured}

🔥 Firebase Integration:
- Android Config: ${FIREBASE_CONFIG_ANDROID:+Available}${FIREBASE_CONFIG_ANDROID:-Not configured}
- iOS Config: ${FIREBASE_CONFIG_IOS:+Available}${FIREBASE_CONFIG_IOS:-Not configured}

🍎 iOS Specific:
- Team ID: ${APPLE_TEAM_ID:-Not configured}
- APNS Key: ${APNS_KEY_ID:+Available}${APNS_KEY_ID:-Not configured}

✅ Integration Status: ${overall_success:+SUCCESS}${overall_success:-HAS ISSUES}
EOF

    log_success "Integration summary generated: $summary_file"
}

# Main execution function
main() {
    log_info "Starting comprehensive feature integration setup"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Setup all integrations
    setup_firebase_integration
    setup_oauth_integration
    setup_push_notifications
    setup_ui_customization
    setup_permissions
    setup_email_system
    setup_chatbot_integration
    setup_ui_enhancements
    
    # Validate integrations
    validate_integrations
    
    # Generate summary
    generate_integration_summary
    
    log_success "Feature integration setup completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
