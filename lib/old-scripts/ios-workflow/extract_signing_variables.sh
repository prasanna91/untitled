#!/bin/bash

# 🔍 Extract Signing Variables from Certificate and Profile Files
# This script extracts required variables from certificate and profile files

set -euo pipefail

# Enhanced logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

log_info "🔍 Starting signing variables extraction..."

# Function to extract UUID from provisioning profile
extract_profile_uuid() {
    local profile_path="$1"
    
    if [ ! -f "$profile_path" ]; then
        log_error "Provisioning profile not found: $profile_path"
        return 1
    fi
    
    # Extract UUID using security command and save to temp file
    local temp_plist="/tmp/profile_temp.plist"
    security cms -D -i "$profile_path" > "$temp_plist" 2>/dev/null
    
    if [ ! -f "$temp_plist" ]; then
        log_error "Failed to decode provisioning profile"
        return 1
    fi
    
    # Extract UUID from temp file
    local uuid=$(/usr/libexec/PlistBuddy -c "Print :UUID" "$temp_plist" 2>/dev/null || echo "")
    
    # Clean up temp file
    rm -f "$temp_plist"
    
    if [ -n "$uuid" ]; then
        log_success "✅ Extracted UUID from profile: $uuid"
        echo "$uuid"
    else
        log_error "❌ Failed to extract UUID from profile: $profile_path"
        return 1
    fi
}

# Function to extract team ID from provisioning profile
extract_team_id() {
    local profile_path="$1"
    
    if [ ! -f "$profile_path" ]; then
        log_error "Provisioning profile not found: $profile_path"
        return 1
    fi
    
    # Extract team ID using security command and save to temp file
    local temp_plist="/tmp/profile_temp.plist"
    security cms -D -i "$profile_path" > "$temp_plist" 2>/dev/null
    
    if [ ! -f "$temp_plist" ]; then
        log_error "Failed to decode provisioning profile"
        return 1
    fi
    
    # Extract team ID from temp file
    local team_id=$(/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" "$temp_plist" 2>/dev/null || echo "")
    
    # Clean up temp file
    rm -f "$temp_plist"
    
    if [ -n "$team_id" ]; then
        log_success "✅ Extracted Team ID from profile: $team_id"
        echo "$team_id"
    else
        log_error "❌ Failed to extract Team ID from profile: $profile_path"
        return 1
    fi
}

# Function to extract bundle ID from provisioning profile
extract_bundle_id() {
    local profile_path="$1"
    
    if [ ! -f "$profile_path" ]; then
        log_error "Provisioning profile not found: $profile_path"
        return 1
    fi
    
    # Extract bundle ID using security command and save to temp file
    local temp_plist="/tmp/profile_temp.plist"
    security cms -D -i "$profile_path" > "$temp_plist" 2>/dev/null
    
    if [ ! -f "$temp_plist" ]; then
        log_error "Failed to decode provisioning profile"
        return 1
    fi
    
    # Extract bundle ID from temp file
    local bundle_id=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" "$temp_plist" 2>/dev/null | \
                     sed 's/.*\.//' || echo "")
    
    # Clean up temp file
    rm -f "$temp_plist"
    
    if [ -n "$bundle_id" ]; then
        log_success "✅ Extracted Bundle ID from profile: $bundle_id"
        echo "$bundle_id"
    else
        log_error "❌ Failed to extract Bundle ID from profile: $profile_path"
        return 1
    fi
}

# Function to extract certificate information
extract_certificate_info() {
    local cert_path="$1"
    
    if [ ! -f "$cert_path" ]; then
        log_error "Certificate not found: $cert_path"
        return 1
    fi
    
    # Extract certificate information
    local cert_info=$(openssl x509 -in "$cert_path" -text -noout 2>/dev/null || echo "")
    
    if [ -n "$cert_info" ]; then
        log_success "✅ Certificate information extracted"
        echo "$cert_info"
    else
        log_error "❌ Failed to extract certificate information: $cert_path"
        return 1
    fi
}

# Main extraction logic
log_info "🔍 Extracting signing variables..."

# Check if we have a provisioning profile URL
if [ -n "${PROFILE_URL:-}" ]; then
    log_info "📥 Downloading provisioning profile from: $PROFILE_URL"
    
    # Download profile
    PROFILE_PATH="/tmp/profile.mobileprovision"
    if curl -fSL "$PROFILE_URL" -o "$PROFILE_PATH" 2>/dev/null; then
        log_success "✅ Provisioning profile downloaded"
        
        # Extract UUID
        PROFILE_UUID=$(extract_profile_uuid "$PROFILE_PATH")
        if [ -n "$PROFILE_UUID" ]; then
            export UUID="$PROFILE_UUID"
            log_success "✅ Set UUID: $UUID"
        else
            # Fallback: Use improved_ios_workflow.sh method
            log_warning "⚠️ Primary UUID extraction failed, trying fallback method..."
            security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist 2>/dev/null
            if [ -f "/tmp/profile.plist" ]; then
                FALLBACK_UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
                if [ -n "$FALLBACK_UUID" ]; then
                    export UUID="$FALLBACK_UUID"
                    log_success "✅ Set UUID using fallback method: $UUID"
                else
                    log_error "❌ Failed to extract UUID using both methods"
                fi
                rm -f /tmp/profile.plist
            fi
        fi
        
        # Extract Team ID
        TEAM_ID_FROM_PROFILE=$(extract_team_id "$PROFILE_PATH")
        if [ -n "$TEAM_ID_FROM_PROFILE" ]; then
            # Only set if not already provided
            if [ -z "${APPLE_TEAM_ID:-}" ]; then
                export APPLE_TEAM_ID="$TEAM_ID_FROM_PROFILE"
                log_success "✅ Set APPLE_TEAM_ID from profile: $APPLE_TEAM_ID"
            else
                log_info "ℹ️ APPLE_TEAM_ID already set: $APPLE_TEAM_ID"
            fi
        else
            # Fallback: Use improved_ios_workflow.sh method
            log_warning "⚠️ Primary Team ID extraction failed, trying fallback method..."
            security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist 2>/dev/null
            if [ -f "/tmp/profile.plist" ]; then
                FALLBACK_TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" /tmp/profile.plist 2>/dev/null || echo "")
                if [ -n "$FALLBACK_TEAM_ID" ] && [ -z "${APPLE_TEAM_ID:-}" ]; then
                    export APPLE_TEAM_ID="$FALLBACK_TEAM_ID"
                    log_success "✅ Set APPLE_TEAM_ID using fallback method: $APPLE_TEAM_ID"
                fi
                rm -f /tmp/profile.plist
            fi
        fi
        
        # Extract Bundle ID
        BUNDLE_ID_FROM_PROFILE=$(extract_bundle_id "$PROFILE_PATH")
        if [ -n "$BUNDLE_ID_FROM_PROFILE" ]; then
            # Only set if not already provided
            if [ -z "${BUNDLE_ID:-}" ]; then
                export BUNDLE_ID="$BUNDLE_ID_FROM_PROFILE"
                log_success "✅ Set BUNDLE_ID from profile: $BUNDLE_ID"
            else
                log_info "ℹ️ BUNDLE_ID already set: $BUNDLE_ID"
            fi
        else
            # Fallback: Use improved_ios_workflow.sh method
            log_warning "⚠️ Primary Bundle ID extraction failed, trying fallback method..."
            security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist 2>/dev/null
            if [ -f "/tmp/profile.plist" ]; then
                FALLBACK_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
                if [ -n "$FALLBACK_BUNDLE_ID" ] && [ -z "${BUNDLE_ID:-}" ]; then
                    export BUNDLE_ID="$FALLBACK_BUNDLE_ID"
                    log_success "✅ Set BUNDLE_ID using fallback method: $BUNDLE_ID"
                fi
                rm -f /tmp/profile.plist
            fi
        fi
        
    else
        log_error "❌ Failed to download provisioning profile"
    fi
else
    log_warning "⚠️ PROFILE_URL not provided, skipping profile extraction"
fi

# Check if we have certificate files
if [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
    log_info "📥 Downloading certificate files..."
    
    # Download certificate files
    CERT_CER_PATH="/tmp/cert.cer"
    CERT_KEY_PATH="/tmp/cert.key"
    
    if curl -fSL "$CERT_CER_URL" -o "$CERT_CER_PATH" 2>/dev/null && \
       curl -fSL "$CERT_KEY_URL" -o "$CERT_KEY_PATH" 2>/dev/null; then
        log_success "✅ Certificate files downloaded"
        
        # Extract certificate information
        CERT_INFO=$(extract_certificate_info "$CERT_CER_PATH")
        if [ -n "$CERT_INFO" ]; then
            log_success "✅ Certificate information extracted"
        fi
        
    else
        log_error "❌ Failed to download certificate files"
        log_info "ℹ️ Checking for P12 certificate as fallback..."
    fi
fi

# Check for P12 certificate (either as primary or fallback)
if [ -n "${CERT_P12_URL:-}" ]; then
    log_info "📥 Downloading P12 certificate..."
    
    # Download P12 certificate
    CERT_P12_PATH="/tmp/cert.p12"
    
    if curl -fSL "$CERT_P12_URL" -o "$CERT_P12_PATH" 2>/dev/null; then
        log_success "✅ P12 certificate downloaded"
        
        # Extract certificate information from P12
        if [ -n "${CERT_PASSWORD:-}" ]; then
            CERT_INFO=$(openssl pkcs12 -in "$CERT_P12_PATH" -passin pass:"$CERT_PASSWORD" -info -noout 2>/dev/null || echo "")
            if [ -n "$CERT_INFO" ]; then
                log_success "✅ P12 certificate information extracted"
            fi
        else
            log_warning "⚠️ CERT_PASSWORD not provided, cannot extract P12 info"
        fi
        
    else
        log_error "❌ Failed to download P12 certificate"
    fi
elif [ -z "${CERT_CER_URL:-}" ] && [ -z "${CERT_KEY_URL:-}" ]; then
    log_warning "⚠️ Certificate URLs not provided, skipping certificate extraction"
fi

# Validate required variables
log_info "🔍 Validating required variables..."

MISSING_VARS=()

if [ -z "${UUID:-}" ]; then
    MISSING_VARS+=("UUID")
    log_error "❌ UUID is required but could not be extracted from profile"
    log_info "📋 Attempting manual UUID extraction as last resort..."
    
    # Last resort: Try to extract UUID manually
    if [ -f "$PROFILE_PATH" ]; then
        MANUAL_UUID=$(security cms -D -i "$PROFILE_PATH" 2>/dev/null | grep -o '"[A-F0-9]\{8\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{12\}"' | head -1 | tr -d '"' || echo "")
        if [ -n "$MANUAL_UUID" ]; then
            export UUID="$MANUAL_UUID"
            log_success "✅ Set UUID using manual extraction: $UUID"
        else
            log_error "❌ All UUID extraction methods failed"
        fi
    fi
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    MISSING_VARS+=("APPLE_TEAM_ID")
fi

if [ -z "${BUNDLE_ID:-}" ]; then
    MISSING_VARS+=("BUNDLE_ID")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_error "❌ Missing required variables: ${MISSING_VARS[*]}"
    log_info "📋 Current variables:"
    log_info "  UUID: ${UUID:-NOT SET}"
    log_info "  APPLE_TEAM_ID: ${APPLE_TEAM_ID:-NOT SET}"
    log_info "  BUNDLE_ID: ${BUNDLE_ID:-NOT SET}"
    log_info "  PROFILE_URL: ${PROFILE_URL:-NOT SET}"
    log_info "  CERT_CER_URL: ${CERT_CER_URL:-NOT SET}"
    log_info "  CERT_KEY_URL: ${CERT_KEY_URL:-NOT SET}"
    log_info "  CERT_P12_URL: ${CERT_P12_URL:-NOT SET}"
    exit 1
fi

log_success "✅ All required variables are set:"
log_info "  UUID: $UUID"
log_info "  APPLE_TEAM_ID: $APPLE_TEAM_ID"
log_info "  BUNDLE_ID: $BUNDLE_ID"

# Create a summary file
log_info "📋 Creating variables summary..."
cat > signing_variables_summary.txt << EOF
Signing Variables Summary
=========================

Extracted Variables:
- UUID: $UUID
- APPLE_TEAM_ID: $APPLE_TEAM_ID
- BUNDLE_ID: $BUNDLE_ID

Source Files:
- PROFILE_URL: ${PROFILE_URL:-NOT PROVIDED}
- CERT_CER_URL: ${CERT_CER_URL:-NOT PROVIDED}
- CERT_KEY_URL: ${CERT_KEY_URL:-NOT PROVIDED}
- CERT_P12_URL: ${CERT_P12_URL:-NOT PROVIDED}

Extraction Date: $(date)
EOF

log_success "✅ Variables summary created: signing_variables_summary.txt"

log_success "🎉 Signing variables extraction completed successfully!" 