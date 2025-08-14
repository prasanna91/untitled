#!/usr/bin/env bash

# Test script using exact variables from the user's build log
# This will help identify the specific issue causing the env_config.dart error

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }
log() { echo "📌 $1"; }

# Set the exact variables from the user's build log
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
export SPLASH_BG_COLOR="#cbdbf5"
export SPLASH_TAGLINE="GARBCODE"
export SPLASH_TAGLINE_COLOR="#a30237"
export SPLASH_TAGLINE_FONT="Roboto"
export SPLASH_TAGLINE_SIZE="16"
export SPLASH_ANIMATION="zoom"
export SPLASH_DURATION="4"
export BOTTOMMENU_ITEMS=""
export BOTTOMMENU_BG_COLOR="#FFFFFF"
export BOTTOMMENU_ICON_COLOR="#6d6e8c"
export BOTTOMMENU_TEXT_COLOR="#6d6e8c"
export BOTTOMMENU_FONT="DM Sans"
export BOTTOMMENU_FONT_SIZE="12"
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"
export BOTTOMMENU_ACTIVE_TAB_COLOR="#a30237"
export BOTTOMMENU_ICON_POSITION="above"
export FIREBASE_CONFIG_ANDROID=""
export FIREBASE_CONFIG_IOS="https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-gc.plist"
export KEY_STORE_URL=""
export CM_KEYSTORE_PASSWORD=""
export CM_KEY_ALIAS=""
export CM_KEY_PASSWORD=""
export APPLE_TEAM_ID="9H2AD7NQ49"
export APNS_KEY_ID="6VB3VLTXV6"
export APNS_AUTH_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_V566SWNF69.p8"
export CERT_TYPE="p12"
export CERT_PASSWORD="quikapp2025"
export PROFILE_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode_sign_app_profile.mobileprovision"
export CERT_P12_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/Certificates.p12"
export CERT_CER_URL=""
export CERT_KEY_URL=""
export PROFILE_TYPE="app-store"
export APP_STORE_CONNECT_KEY_IDENTIFIER="S95LCWAH99"
export ENABLE_EMAIL_NOTIFICATIONS="true"
export EMAIL_SMTP_SERVER="smtp.gmail.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="prasannasrie@gmail.com"
export EMAIL_SMTP_PASS="lrnu krfm aarp urux"
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
export IS_BOTTOMMENU="false"
export IS_LOAD_IND="true"
export IS_GOOGLE_AUTH="true"
export IS_APPLE_AUTH="true"

# Permissions
export IS_CAMERA="false"
export IS_LOCATION="false"
export IS_MIC="true"
export IS_NOTIFICATION="true"
export IS_CONTACT="false"
export IS_BIOMETRIC="false"
export IS_CALENDAR="false"
export IS_STORAGE="false"

# Splash screen settings
export SPLASH_TAGLINE_BOLD="false"
export SPLASH_TAGLINE_ITALIC="false"

# Bottom menu settings
export BOTTOMMENU_FONT_BOLD="false"
export BOTTOMMENU_FONT_ITALIC="false"

# Test environment configuration generation
test_fix_env_config() {
    log_info "🧪 Testing environment configuration generation with exact Codemagic variables..."
    
    # Create backup
    if [ -f "lib/config/env_config.dart" ]; then
        cp lib/config/env_config.dart lib/config/env_config.dart.backup.fix_test
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
                
                # Show the specific lines that were causing issues
                log "Checking line 75 (the problematic line):"
                sed -n '75p' lib/config/env_config.dart
                
                log "Checking Firebase configuration lines:"
                grep -n "firebaseConfig" lib/config/env_config.dart
                
                return 0
            else
                log_error "❌ Environment configuration has syntax errors"
                log "Flutter analyze output:"
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
    log_info "🧪 Starting fix test with exact Codemagic variables..."
    
    if test_fix_env_config; then
        log_success "🎉 Environment configuration fix test passed!"
        exit 0
    else
        log_error "❌ Environment configuration fix test failed!"
        exit 1
    fi
}

# Run main function
main "$@" 