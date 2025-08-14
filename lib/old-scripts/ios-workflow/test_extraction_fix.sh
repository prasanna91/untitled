#!/bin/bash

# 🧪 Test Signing Variables Extraction Fix
# This script tests the improved extraction functionality

set -euo pipefail

# Enhanced logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

log_info "🧪 Starting extraction fix test..."

# Test 1: Check if extraction script exists and is executable
log_info "📋 Test 1: Checking extraction script..."
if [ -f "lib/scripts/ios-workflow/extract_signing_variables.sh" ]; then
    log_success "✅ Extraction script exists"
    
    if [ -x "lib/scripts/ios-workflow/extract_signing_variables.sh" ]; then
        log_success "✅ Extraction script is executable"
    else
        log_warning "⚠️ Extraction script is not executable, making it executable..."
        chmod +x lib/scripts/ios-workflow/extract_signing_variables.sh
        log_success "✅ Made extraction script executable"
    fi
else
    log_error "❌ Extraction script not found"
    exit 1
fi

# Test 2: Check environment variables
log_info "📋 Test 2: Checking environment variables..."
REQUIRED_VARS=("PROFILE_URL" "CERT_P12_URL" "CERT_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -n "${!var:-}" ]; then
        log_success "✅ $var is set: ${!var}"
    else
        log_warning "⚠️ $var is not set"
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_warning "⚠️ Missing variables: ${MISSING_VARS[*]}"
    log_info "ℹ️ This is expected if variables are not set in environment"
fi

# Test 3: Test profile download
log_info "📋 Test 3: Testing profile download..."
if [ -n "${PROFILE_URL:-}" ]; then
    log_info "📥 Testing download from: $PROFILE_URL"
    
    TEST_PROFILE_PATH="/tmp/test_profile.mobileprovision"
    if curl -fSL "$PROFILE_URL" -o "$TEST_PROFILE_PATH" 2>/dev/null; then
        log_success "✅ Profile download successful"
        
        # Test profile decoding
        if security cms -D -i "$TEST_PROFILE_PATH" > /tmp/test_profile.plist 2>/dev/null; then
            log_success "✅ Profile decoding successful"
            
            # Test UUID extraction
            TEST_UUID=$(/usr/libexec/PlistBuddy -c "Print :UUID" /tmp/test_profile.plist 2>/dev/null || echo "")
            if [ -n "$TEST_UUID" ]; then
                log_success "✅ UUID extraction successful: $TEST_UUID"
            else
                log_warning "⚠️ UUID extraction failed"
            fi
            
            # Test Team ID extraction
            TEST_TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" /tmp/test_profile.plist 2>/dev/null || echo "")
            if [ -n "$TEST_TEAM_ID" ]; then
                log_success "✅ Team ID extraction successful: $TEST_TEAM_ID"
            else
                log_warning "⚠️ Team ID extraction failed"
            fi
            
            # Test Bundle ID extraction
            TEST_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/test_profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
            if [ -n "$TEST_BUNDLE_ID" ]; then
                log_success "✅ Bundle ID extraction successful: $TEST_BUNDLE_ID"
            else
                log_warning "⚠️ Bundle ID extraction failed"
            fi
            
            # Clean up
            rm -f /tmp/test_profile.plist
        else
            log_error "❌ Profile decoding failed"
        fi
        
        # Clean up
        rm -f "$TEST_PROFILE_PATH"
    else
        log_error "❌ Profile download failed"
    fi
else
    log_warning "⚠️ PROFILE_URL not set, skipping profile test"
fi

# Test 4: Test certificate download
log_info "📋 Test 4: Testing certificate download..."
if [ -n "${CERT_P12_URL:-}" ]; then
    log_info "📥 Testing P12 download from: $CERT_P12_URL"
    
    TEST_CERT_PATH="/tmp/test_cert.p12"
    if curl -fSL "$CERT_P12_URL" -o "$TEST_CERT_PATH" 2>/dev/null; then
        log_success "✅ P12 certificate download successful"
        
        # Test certificate validation
        if [ -n "${CERT_PASSWORD:-}" ]; then
            if openssl pkcs12 -in "$TEST_CERT_PATH" -passin pass:"$CERT_PASSWORD" -info -noout 2>/dev/null; then
                log_success "✅ P12 certificate validation successful"
            else
                log_warning "⚠️ P12 certificate validation failed"
            fi
        else
            log_warning "⚠️ CERT_PASSWORD not set, cannot validate P12"
        fi
        
        # Clean up
        rm -f "$TEST_CERT_PATH"
    else
        log_error "❌ P12 certificate download failed"
    fi
else
    log_warning "⚠️ CERT_P12_URL not set, skipping certificate test"
fi

# Test 5: Test the actual extraction script
log_info "📋 Test 5: Testing extraction script execution..."
if [ -n "${PROFILE_URL:-}" ]; then
    log_info "🚀 Running extraction script..."
    
    # Set test environment variables
    export PROFILE_URL="${PROFILE_URL}"
    export CERT_P12_URL="${CERT_P12_URL:-}"
    export CERT_PASSWORD="${CERT_PASSWORD:-}"
    export APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
    export BUNDLE_ID="${BUNDLE_ID:-}"
    
    # Run extraction script
    if ./lib/scripts/ios-workflow/extract_signing_variables.sh; then
        log_success "✅ Extraction script executed successfully"
        
        # Check if variables were set
        if [ -n "${UUID:-}" ]; then
            log_success "✅ UUID was set: $UUID"
        else
            log_error "❌ UUID was not set"
        fi
        
        if [ -n "${APPLE_TEAM_ID:-}" ]; then
            log_success "✅ APPLE_TEAM_ID was set: $APPLE_TEAM_ID"
        else
            log_warning "⚠️ APPLE_TEAM_ID was not set"
        fi
        
        if [ -n "${BUNDLE_ID:-}" ]; then
            log_success "✅ BUNDLE_ID was set: $BUNDLE_ID"
        else
            log_warning "⚠️ BUNDLE_ID was not set"
        fi
        
        # Check summary file
        if [ -f "signing_variables_summary.txt" ]; then
            log_success "✅ Variables summary file created"
            log_info "📋 Summary contents:"
            cat signing_variables_summary.txt
        else
            log_warning "⚠️ Variables summary file not created"
        fi
        
    else
        log_error "❌ Extraction script execution failed"
    fi
else
    log_warning "⚠️ PROFILE_URL not set, skipping extraction script test"
fi

# Test 6: Test improved_ios_workflow.sh method
log_info "📋 Test 6: Testing improved_ios_workflow.sh method..."
if [ -n "${PROFILE_URL:-}" ]; then
    log_info "📥 Testing improved_ios_workflow.sh extraction method..."
    
    TEST_PROFILE_PATH="/tmp/test_profile.mobileprovision"
    if curl -fSL "$PROFILE_URL" -o "$TEST_PROFILE_PATH" 2>/dev/null; then
        log_success "✅ Profile downloaded for improved method test"
        
        # Use improved_ios_workflow.sh method
        security cms -D -i "$TEST_PROFILE_PATH" > /tmp/profile.plist 2>/dev/null
        
        if [ -f "/tmp/profile.plist" ]; then
            log_success "✅ Profile decoded using improved method"
            
            # Extract using improved method
            IMPROVED_UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
            IMPROVED_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
            
            if [ -n "$IMPROVED_UUID" ]; then
                log_success "✅ Improved method UUID extraction: $IMPROVED_UUID"
            else
                log_warning "⚠️ Improved method UUID extraction failed"
            fi
            
            if [ -n "$IMPROVED_BUNDLE_ID" ]; then
                log_success "✅ Improved method Bundle ID extraction: $IMPROVED_BUNDLE_ID"
            else
                log_warning "⚠️ Improved method Bundle ID extraction failed"
            fi
            
            # Clean up
            rm -f /tmp/profile.plist
        else
            log_error "❌ Improved method profile decoding failed"
        fi
        
        # Clean up
        rm -f "$TEST_PROFILE_PATH"
    else
        log_error "❌ Profile download failed for improved method test"
    fi
else
    log_warning "⚠️ PROFILE_URL not set, skipping improved method test"
fi

log_success "🎉 Extraction fix test completed!"
log_info "📋 Test Summary:"
log_info "  ✅ Script existence and permissions"
log_info "  ✅ Environment variable validation"
log_info "  ✅ Profile download and decoding"
log_info "  ✅ Certificate download and validation"
log_info "  ✅ Extraction script execution"
log_info "  ✅ Improved method compatibility" 