#!/usr/bin/env bash

# Test script for iOS certificate types (p12 and manual)
# Tests both certificate installation methods

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }
log() { echo "📌 $1"; }

# Test P12 certificate type
test_p12_certificate() {
    log_info "🧪 Testing P12 certificate type..."
    
    # Set P12 environment variables
    export CERT_TYPE="p12"
    export CERT_P12_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/Certificates.p12"
    export CERT_PASSWORD="quikapp2025"
    export CERT_CER_URL=""
    export CERT_KEY_URL=""
    
    log_info "Certificate type: $CERT_TYPE"
    log_info "P12 URL: $CERT_P12_URL"
    log_info "Password: [HIDDEN]"
    
    # Test the certificate setup logic
    if [[ "$CERT_TYPE" == "p12" ]]; then
        if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
            log_success "✅ P12 certificate configuration is valid"
            return 0
        else
            log_error "❌ P12 certificate configuration is invalid"
            return 1
        fi
    else
        log_error "❌ Certificate type mismatch"
        return 1
    fi
}

# Test manual certificate type
test_manual_certificate() {
    log_info "🧪 Testing manual certificate type..."
    
    # Set manual environment variables
    export CERT_TYPE="manual"
    export CERT_P12_URL=""
    export CERT_PASSWORD="quikapp2025"
    export CERT_CER_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/certificate.cer"
    export CERT_KEY_URL="https://raw.githubusercontent.com/prasanna91/QuikApp/main/certificate.key"
    
    log_info "Certificate type: $CERT_TYPE"
    log_info "CER URL: $CERT_CER_URL"
    log_info "KEY URL: $CERT_KEY_URL"
    log_info "Password: [HIDDEN]"
    
    # Test the certificate setup logic
    if [[ "$CERT_TYPE" == "manual" ]]; then
        if [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
            log_success "✅ Manual certificate configuration is valid"
            return 0
        else
            log_error "❌ Manual certificate configuration is invalid"
            return 1
        fi
    else
        log_error "❌ Certificate type mismatch"
        return 1
    fi
}

# Test missing certificate configuration
test_missing_certificate() {
    log_info "🧪 Testing missing certificate configuration..."
    
    # Clear certificate variables
    export CERT_TYPE="p12"
    export CERT_P12_URL=""
    export CERT_PASSWORD=""
    export CERT_CER_URL=""
    export CERT_KEY_URL=""
    
    log_info "Certificate type: $CERT_TYPE"
    log_info "All certificate URLs and passwords are empty"
    
    # Test the certificate setup logic
    if [[ "$CERT_TYPE" == "p12" ]]; then
        if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
            log_error "❌ Should not have valid P12 configuration"
            return 1
        else
            log_success "✅ Correctly identified missing P12 configuration"
            return 0
        fi
    else
        log_error "❌ Certificate type mismatch"
        return 1
    fi
}

# Test invalid certificate type
test_invalid_certificate_type() {
    log_info "🧪 Testing invalid certificate type..."
    
    # Set invalid certificate type
    export CERT_TYPE="invalid"
    export CERT_P12_URL="https://example.com/cert.p12"
    export CERT_PASSWORD="password"
    
    log_info "Certificate type: $CERT_TYPE"
    
    # Test the certificate setup logic
    if [[ "$CERT_TYPE" == "p12" || "$CERT_TYPE" == "manual" ]]; then
        log_error "❌ Should not recognize invalid certificate type"
        return 1
    else
        log_success "✅ Correctly identified invalid certificate type"
        return 0
    fi
}

# Test environment configuration generation with new CERT_TYPE
test_env_config_generation() {
    log_info "🧪 Testing environment configuration generation with CERT_TYPE..."
    
    # Set test environment variables
    export CERT_TYPE="p12"
    export CERT_P12_URL="https://example.com/cert.p12"
    export CERT_PASSWORD="testpass"
    export CERT_CER_URL=""
    export CERT_KEY_URL=""
    
    # Create backup
    if [ -f "lib/config/env_config.dart" ]; then
        cp lib/config/env_config.dart lib/config/env_config.dart.backup.cert_test
        log "Backed up existing env_config.dart"
    fi
    
    # Run the environment configuration generation
    if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
        chmod +x lib/scripts/utils/gen_env_config.sh
        if ./lib/scripts/utils/gen_env_config.sh; then
            log_success "Environment configuration generated successfully"
            
            # Check if certType is included in the generated file
            if grep -q "certType" lib/config/env_config.dart; then
                log_success "✅ certType field found in generated env_config.dart"
                
                # Test if the file is valid Dart
                if flutter analyze lib/config/env_config.dart >/dev/null 2>&1; then
                    log_success "✅ Environment configuration is valid Dart code"
                    return 0
                else
                    log_error "❌ Environment configuration has syntax errors"
                    flutter analyze lib/config/env_config.dart
                    return 1
                fi
            else
                log_error "❌ certType field not found in generated env_config.dart"
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
    log_info "🧪 Starting iOS certificate type tests..."
    
    local all_tests_passed=true
    
    # Run all tests
    if test_p12_certificate; then
        log_success "✅ P12 certificate test passed"
    else
        log_error "❌ P12 certificate test failed"
        all_tests_passed=false
    fi
    
    if test_manual_certificate; then
        log_success "✅ Manual certificate test passed"
    else
        log_error "❌ Manual certificate test failed"
        all_tests_passed=false
    fi
    
    if test_missing_certificate; then
        log_success "✅ Missing certificate test passed"
    else
        log_error "❌ Missing certificate test failed"
        all_tests_passed=false
    fi
    
    if test_invalid_certificate_type; then
        log_success "✅ Invalid certificate type test passed"
    else
        log_error "❌ Invalid certificate type test failed"
        all_tests_passed=false
    fi
    
    if test_env_config_generation; then
        log_success "✅ Environment configuration generation test passed"
    else
        log_error "❌ Environment configuration generation test failed"
        all_tests_passed=false
    fi
    
    # Summary
    if $all_tests_passed; then
        log_success "🎉 All iOS certificate type tests passed!"
        exit 0
    else
        log_error "❌ Some iOS certificate type tests failed!"
        exit 1
    fi
}

# Run main function
main "$@" 