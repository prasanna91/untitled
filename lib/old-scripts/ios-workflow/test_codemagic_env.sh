#!/usr/bin/env bash

# Test script for Codemagic environment variables
# Simulates the actual environment variables from the build log

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }
log() { echo "📌 $1"; }

# Set Codemagic environment variables (from the build log)
export PROJECT_ID="d432f107-c367-45a5-9fdd-86ec00ae78b8"
export APP_ID="10023"
export VERSION_NAME="1.0.21"
export VERSION_CODE="117"
export APP_NAME="Garbcode App"
export ORG_NAME="Garbcode Apparels Private Limited"
export WEB_URL="https://garbcode.com/"
export USER_NAME="prasannasrie"
export EMAIL_ID="prasannasrinivasan32@gmail.com"
export WORKFLOW_ID="ios-workflow"
export BUNDLE_ID="com.garbcode.garbcodeapp"
export LOGO_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
export SPLASH_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png"
export SPLASH_BG_URL=""
export SPLASH_BG_COLOR="#FFFFFF"
export SPLASH_TAGLINE=""
export SPLASH_TAGLINE_COLOR="#000000"
export SPLASH_TAGLINE_FONT="Roboto"
export SPLASH_TAGLINE_SIZE="16"
export SPLASH_ANIMATION="none"
export SPLASH_DURATION="3"
export BOTTOMMENU_ITEMS='[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://example.com/"}]'
export BOTTOMMENU_BG_COLOR="#FFFFFF"
export BOTTOMMENU_ICON_COLOR="#000000"
export BOTTOMMENU_TEXT_COLOR="#000000"
export BOTTOMMENU_FONT="DM Sans"
export BOTTOMMENU_FONT_SIZE="14.0"
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"
export BOTTOMMENU_ACTIVE_TAB_COLOR="#0000FF"
export BOTTOMMENU_ICON_POSITION="top"
export BOTTOMMENU_VISIBLE_ON=""
export FIREBASE_CONFIG_ANDROID=""
export FIREBASE_CONFIG_IOS=""
export KEY_STORE_URL=""
export CM_KEYSTORE_PASSWORD=""
export CM_KEY_ALIAS=""
export CM_KEY_PASSWORD=""
export APPLE_TEAM_ID="9H2AD7NQ49"
export APNS_KEY_ID=""
export APNS_AUTH_KEY_URL=""
export CERT_PASSWORD="testpass"
export PROFILE_URL="https://example.com/profile.mobileprovision"
export CERT_P12_URL=""
export CERT_CER_URL=""
export CERT_KEY_URL=""
export PROFILE_TYPE="app-store"
export APP_STORE_CONNECT_KEY_IDENTIFIER=""
export ENABLE_EMAIL_NOTIFICATIONS="false"
export EMAIL_SMTP_SERVER=""
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER=""
export EMAIL_SMTP_PASS=""
export BUILD_ID="test-build"
export BUILD_DIR=""
export PROJECT_ROOT=""
export OUTPUT_DIR="output"
export GRADLE_OPTS=""
export XCODE_PARALLEL_JOBS="4"
export FLUTTER_BUILD_ARGS=""

# Feature flags
export PUSH_NOTIFY="true"
export IS_CHATBOT="true"
export IS_DOMAIN_URL="true"
export IS_SPLASH="true"
export IS_PULLDOWN="true"
export IS_BOTTOMMENU="true"
export IS_LOAD_IND="true"

# Permissions
export IS_CAMERA="false"
export IS_LOCATION="false"
export IS_MIC="true"
export IS_NOTIFICATION="true"
export IS_CONTACT="false"
export IS_BIOMETRIC="false"
export IS_CALENDAR="false"
export IS_STORAGE="false"

# OAuth
export IS_GOOGLE_AUTH="false"
export IS_APPLE_AUTH="false"

# Splash screen settings
export SPLASH_TAGLINE_BOLD="false"
export SPLASH_TAGLINE_ITALIC="false"

# Bottom menu settings
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"

# Test environment configuration generation
test_codemagic_env_config() {
    log_info "🧪 Testing Codemagic environment configuration generation..."
    
    # Create backup
    if [ -f "lib/config/env_config.dart" ]; then
        cp lib/config/env_config.dart lib/config/env_config.dart.backup.codemagic
        log "Backed up existing env_config.dart"
    fi
    
    # Run the environment configuration generation
    if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
        chmod +x lib/scripts/utils/gen_env_config.sh
        if ./lib/scripts/utils/gen_env_config.sh; then
            log_success "Environment configuration generated successfully"
            
            # Test if the file is valid Dart
            if flutter analyze lib/config/env_config.dart >/dev/null 2>&1; then
                log_success "✅ Environment configuration is valid Dart code"
                
                # Show a preview of the generated file
                log "Generated file preview:"
                head -30 lib/config/env_config.dart | while IFS= read -r line; do
                    log "   $line"
                done
                
                return 0
            else
                log_error "❌ Environment configuration has syntax errors"
                flutter analyze lib/config/env_config.dart
                return 1
            fi
        else
            log_error "❌ Environment configuration generation failed"
            return 1
        fi
    else
        log_error "❌ gen_env_config.sh script not found"
        return 1
    fi
}

# Main test execution
main() {
    log_info "🧪 Starting Codemagic environment configuration test..."
    
    if test_codemagic_env_config; then
        log_success "🎉 Codemagic environment configuration test passed!"
        exit 0
    else
        log_error "❌ Codemagic environment configuration test failed!"
        exit 1
    fi
}

# Run main function
main "$@" 