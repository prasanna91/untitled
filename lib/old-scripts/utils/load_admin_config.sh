#!/bin/bash
set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ADMIN_CONFIG] $1" >&2; }

# Load admin configuration
load_admin_config() {
    log "📋 Loading admin configuration from lib/config/admin_config.env..."
    
    if [ -f "lib/config/admin_config.env" ]; then
        log "✅ Found admin_config.env file"
        
        # Load environment variables from admin_config.env
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            if [[ ! "$key" =~ ^# ]] && [[ -n "$key" ]]; then
                # Remove any leading/trailing whitespace
                key=$(echo "$key" | xargs)
                value=$(echo "$value" | xargs)
                
                # Only set if not already set (allow override from Codemagic/API)
                if [ -z "${!key:-}" ]; then
                    export "$key=$value"
                    log "   Set $key=$value"
                else
                    log "   Skipped $key (already set to ${!key})"
                fi
            fi
        done < lib/config/admin_config.env
        
        log "✅ Admin configuration loaded successfully"
    else
        log "⚠️ admin_config.env file not found - continuing without fallback"
    fi
}

# Validate required variables
validate_required_variables() {
    log "🔍 Validating required variables..."
    
    # List of required variables for different workflows
    local required_vars=()
    
    # Common required variables
    required_vars+=("WORKFLOW_ID" "APP_ID" "VERSION_NAME" "VERSION_CODE" "APP_NAME" "ORG_NAME" "WEB_URL" "EMAIL_ID" "USER_NAME")
    
    # Check if Firebase is required
    local push_notify=${PUSH_NOTIFY:-false}
    local is_google_auth=${IS_GOOGLE_AUTH:-false}
    
    # Android specific
    if [[ "${WORKFLOW_ID:-}" == "android-free" ]] || [[ "${WORKFLOW_ID:-}" == "android-paid" ]] || [[ "${WORKFLOW_ID:-}" == "android-publish" ]] || [[ "${WORKFLOW_ID:-}" == "combined" ]]; then
        required_vars+=("PKG_NAME")
        
        # Add Firebase config if required
        if [[ "$push_notify" == "true" ]] || [[ "$is_google_auth" == "true" ]]; then
            required_vars+=("FIREBASE_CONFIG_ANDROID")
        fi
    fi
    
    # iOS specific
    if [[ "${WORKFLOW_ID:-}" == "ios-workflow" ]] || [[ "${WORKFLOW_ID:-}" == "combined" ]]; then
        required_vars+=("BUNDLE_ID" "APPLE_TEAM_ID" "PROFILE_URL" "CERT_PASSWORD")
        
        # Add Firebase config if required
        if [[ "$push_notify" == "true" ]] || [[ "$is_google_auth" == "true" ]]; then
            required_vars+=("FIREBASE_CONFIG_IOS")
        fi
    fi
    
    # Check each required variable
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    # Report missing variables
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "❌ Missing required variables:"
        for var in "${missing_vars[@]}"; do
            log_error "   - $var"
        done
        log_error "Please provide these variables in your API response or Codemagic environment."
        return 1
    else
        log "✅ All required variables are present"
        return 0
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_admin_config
    validate_required_variables
fi