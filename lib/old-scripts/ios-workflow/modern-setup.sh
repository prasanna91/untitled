#!/bin/bash

# Modern iOS Workflow Setup Script
# Helps users configure the iOS workflow with minimal required variables

set -euo pipefail

echo "🚀 Modern iOS Workflow Setup"
echo "============================"
echo ""

# Function to display help
show_help() {
    echo "📋 Modern iOS Workflow Configuration"
    echo "===================================="
    echo ""
    echo "🎯 Essential Variables (Required):"
    echo "   BUNDLE_ID              - Your app's bundle identifier"
    echo "   APPLE_TEAM_ID         - Your Apple Developer Team ID"
    echo "   PROFILE_TYPE          - Distribution type (app-store, ad-hoc, development)"
    echo ""
    echo "🔑 App Store Connect API (Optional for TestFlight):"
    echo "   APP_STORE_CONNECT_KEY_IDENTIFIER - Your API key ID"
    echo "   APP_STORE_CONNECT_ISSUER_ID     - Your issuer ID"
    echo "   APP_STORE_CONNECT_API_KEY_URL   - URL to your .p8 API key file"
    echo ""
    echo "📱 Optional Variables:"
    echo "   IS_TESTFLIGHT                    - Enable TestFlight upload (true/false)"
    echo "   ENABLE_DEVICE_SPECIFIC_BUILDS   - Enable device-specific builds (true/false)"
    echo ""
    echo "💡 Example Configuration:"
    echo "   BUNDLE_ID=com.yourcompany.yourapp"
    echo "   APPLE_TEAM_ID=ABC123DEF4"
    echo "   PROFILE_TYPE=app-store"
    echo "   IS_TESTFLIGHT=true"
    echo "   APP_STORE_CONNECT_KEY_IDENTIFIER=ABC123DEF4"
    echo "   APP_STORE_CONNECT_ISSUER_ID=12345678-1234-1234-1234-123456789012"
    echo "   APP_STORE_CONNECT_API_KEY_URL=https://your-server.com/AuthKey_ABC123DEF4.p8"
    echo ""
}

# Function to validate bundle ID format
validate_bundle_id() {
    local bundle_id="$1"
    if [[ "$bundle_id" =~ ^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate team ID format
validate_team_id() {
    local team_id="$1"
    if [[ "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate API key ID format
validate_api_key_id() {
    local api_key_id="$1"
    if [[ "$api_key_id" =~ ^[A-Z0-9]{10}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate issuer ID format
validate_issuer_id() {
    local issuer_id="$1"
    if [[ "$issuer_id" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if URL is accessible
check_url_accessible() {
    local url="$1"
    if curl -I "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to validate configuration
validate_configuration() {
    echo "🔍 Validating Modern iOS Configuration"
    echo "====================================="
    echo ""
    
    local errors=0
    
    # Check essential variables
    echo "🎯 Essential Variables:"
    
    if [ -z "${BUNDLE_ID:-}" ]; then
        echo "❌ BUNDLE_ID is not set"
        errors=$((errors + 1))
    else
        if validate_bundle_id "$BUNDLE_ID"; then
            echo "✅ BUNDLE_ID: $BUNDLE_ID"
        else
            echo "❌ BUNDLE_ID format is invalid: $BUNDLE_ID"
            echo "   Expected format: com.company.appname"
            errors=$((errors + 1))
        fi
    fi
    
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        echo "❌ APPLE_TEAM_ID is not set"
        errors=$((errors + 1))
    else
        if validate_team_id "$APPLE_TEAM_ID"; then
            echo "✅ APPLE_TEAM_ID: $APPLE_TEAM_ID"
        else
            echo "❌ APPLE_TEAM_ID format is invalid: $APPLE_TEAM_ID"
            echo "   Expected format: ABC123DEF4 (10 characters)"
            errors=$((errors + 1))
        fi
    fi
    
    if [ -z "${PROFILE_TYPE:-}" ]; then
        echo "❌ PROFILE_TYPE is not set"
        errors=$((errors + 1))
    else
        case "$PROFILE_TYPE" in
            app-store|ad-hoc|development)
                echo "✅ PROFILE_TYPE: $PROFILE_TYPE"
                ;;
            *)
                echo "❌ PROFILE_TYPE is invalid: $PROFILE_TYPE"
                echo "   Valid options: app-store, ad-hoc, development"
                errors=$((errors + 1))
                ;;
        esac
    fi
    
    echo ""
    echo "🔑 App Store Connect API (Optional):"
    
    if [ "${IS_TESTFLIGHT:-true}" = "true" ]; then
        echo "📤 TestFlight upload is enabled"
        
        if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ]; then
            echo "⚠️ APP_STORE_CONNECT_KEY_IDENTIFIER is not set"
            echo "   TestFlight upload will be skipped"
        else
            if validate_api_key_id "$APP_STORE_CONNECT_KEY_IDENTIFIER"; then
                echo "✅ APP_STORE_CONNECT_KEY_IDENTIFIER: $APP_STORE_CONNECT_KEY_IDENTIFIER"
            else
                echo "❌ APP_STORE_CONNECT_KEY_IDENTIFIER format is invalid: $APP_STORE_CONNECT_KEY_IDENTIFIER"
                echo "   Expected format: ABC123DEF4 (10 characters)"
                errors=$((errors + 1))
            fi
        fi
        
        if [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
            echo "⚠️ APP_STORE_CONNECT_ISSUER_ID is not set"
            echo "   TestFlight upload will be skipped"
        else
            if validate_issuer_id "$APP_STORE_CONNECT_ISSUER_ID"; then
                echo "✅ APP_STORE_CONNECT_ISSUER_ID: $APP_STORE_CONNECT_ISSUER_ID"
            else
                echo "❌ APP_STORE_CONNECT_ISSUER_ID format is invalid: $APP_STORE_CONNECT_ISSUER_ID"
                echo "   Expected format: 12345678-1234-1234-1234-123456789012"
                errors=$((errors + 1))
            fi
        fi
        
        if [ -z "${APP_STORE_CONNECT_API_KEY_URL:-}" ]; then
            echo "⚠️ APP_STORE_CONNECT_API_KEY_URL is not set"
            echo "   TestFlight upload will be skipped"
        else
            echo "✅ APP_STORE_CONNECT_API_KEY_URL: $APP_STORE_CONNECT_API_KEY_URL"
            if check_url_accessible "$APP_STORE_CONNECT_API_KEY_URL"; then
                echo "✅ API key URL is accessible"
            else
                echo "❌ API key URL is not accessible"
                echo "   Please check the URL and ensure it's publicly accessible"
                errors=$((errors + 1))
            fi
        fi
    else
        echo "ℹ️ TestFlight upload is disabled (IS_TESTFLIGHT=false)"
    fi
    
    echo ""
    echo "📱 Optional Variables:"
    echo "   IS_TESTFLIGHT: ${IS_TESTFLIGHT:-true}"
    echo "   ENABLE_DEVICE_SPECIFIC_BUILDS: ${ENABLE_DEVICE_SPECIFIC_BUILDS:-false}"
    
    echo ""
    echo "====================================="
    
    if [ $errors -eq 0 ]; then
        echo "✅ Configuration validation passed!"
        echo "🚀 Your iOS workflow is ready to run"
        return 0
    else
        echo "❌ Found $errors configuration errors"
        echo "🔧 Please fix the issues above before running the workflow"
        return 1
    fi
}

# Function to generate example configuration
generate_example_config() {
    echo "📝 Example Configuration"
    echo "======================="
    echo ""
    echo "# Essential Variables (Required)"
    echo "BUNDLE_ID=com.yourcompany.yourapp"
    echo "APPLE_TEAM_ID=ABC123DEF4"
    echo "PROFILE_TYPE=app-store"
    echo ""
    echo "# App Store Connect API (Optional for TestFlight)"
    echo "IS_TESTFLIGHT=true"
    echo "APP_STORE_CONNECT_KEY_IDENTIFIER=ABC123DEF4"
    echo "APP_STORE_CONNECT_ISSUER_ID=12345678-1234-1234-1234-123456789012"
    echo "APP_STORE_CONNECT_API_KEY_URL=https://your-server.com/AuthKey_ABC123DEF4.p8"
    echo ""
    echo "# Optional Variables"
    echo "ENABLE_DEVICE_SPECIFIC_BUILDS=false"
    echo ""
}

# Function to test API credentials
test_api_credentials() {
    echo "🧪 Testing App Store Connect API Credentials"
    echo "==========================================="
    echo ""
    
    if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] || [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ] || [ -z "${APP_STORE_CONNECT_API_KEY_URL:-}" ]; then
        echo "❌ Missing API credentials for testing"
        echo "   Please set APP_STORE_CONNECT_KEY_IDENTIFIER, APP_STORE_CONNECT_ISSUER_ID, and APP_STORE_CONNECT_API_KEY_URL"
        return 1
    fi
    
    echo "📥 Downloading API key for testing..."
    API_KEY_PATH="/tmp/test_AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
    
    if curl -L -o "$API_KEY_PATH" "$APP_STORE_CONNECT_API_KEY_URL" 2>/dev/null; then
        chmod 600 "$API_KEY_PATH"
        echo "✅ API key downloaded successfully"
        
        echo "🔍 Testing API credentials..."
        if xcrun altool --list-providers --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" --apiKeyPath "$API_KEY_PATH" >/dev/null 2>&1; then
            echo "✅ API credentials are valid"
            echo "✅ You can upload to TestFlight"
        else
            echo "❌ API credentials are invalid"
            echo "   Please check your API key ID, issuer ID, and API key file"
        fi
        
        # Clean up
        rm -f "$API_KEY_PATH"
    else
        echo "❌ Failed to download API key"
        echo "   Please check the URL: $APP_STORE_CONNECT_API_KEY_URL"
        return 1
    fi
}

# Main function
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --validate|-v)
            validate_configuration
            ;;
        --example|-e)
            generate_example_config
            ;;
        --test-api|-t)
            test_api_credentials
            ;;
        *)
            echo "🚀 Modern iOS Workflow Setup"
            echo "============================"
            echo ""
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  --help, -h      Show this help message"
            echo "  --validate, -v  Validate current configuration"
            echo "  --example, -e   Generate example configuration"
            echo "  --test-api, -t  Test App Store Connect API credentials"
            echo ""
            echo "💡 Quick Start:"
            echo "  1. Set your essential variables (BUNDLE_ID, APPLE_TEAM_ID, PROFILE_TYPE)"
            echo "  2. Run: $0 --validate"
            echo "  3. If TestFlight upload is needed, set API credentials and run: $0 --test-api"
            echo ""
            ;;
    esac
}

# Run main function
main "$@" 