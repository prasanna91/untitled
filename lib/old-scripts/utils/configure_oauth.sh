#!/bin/bash
set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [OAUTH_CONFIG] $1" >&2; }

# Configure OAuth dependencies based on environment variables
configure_oauth_dependencies() {
    log "🔐 Configuring OAuth dependencies..."

    # Check if Google Auth is enabled
    if [ "${IS_GOOGLE_AUTH:-false}" = "true" ]; then
        log "✅ Google Auth is enabled"
        
        # Ensure google_sign_in is in pubspec.yaml
        if ! grep -q "google_sign_in:" pubspec.yaml; then
            log "❌ google_sign_in dependency not found in pubspec.yaml"
            exit 1
        fi
    else
        log "⚠️ Google Auth is disabled"
    fi

    # Check if Apple Auth is enabled
    if [ "${IS_APPLE_AUTH:-false}" = "true" ]; then
        log "✅ Apple Auth is enabled"
        
        # Check if sign_in_with_apple is commented out
        if grep -q "# sign_in_with_apple:" pubspec.yaml; then
            log "🔄 Uncommenting sign_in_with_apple dependency..."
            sed -i.bak 's/# sign_in_with_apple:/sign_in_with_apple:/' pubspec.yaml
            sed -i.bak 's/# Uncomment when IS_APPLE_AUTH=true//' pubspec.yaml
        fi
        
        # Verify the dependency is now active
        if grep -q "sign_in_with_apple:" pubspec.yaml && ! grep -q "# sign_in_with_apple:" pubspec.yaml; then
            log "✅ sign_in_with_apple dependency activated"
        else
            log "❌ Failed to activate sign_in_with_apple dependency"
            exit 1
        fi
    else
        log "⚠️ Apple Auth is disabled"
        
        # Comment out sign_in_with_apple if it's not already commented
        if grep -q "sign_in_with_apple:" pubspec.yaml && ! grep -q "# sign_in_with_apple:" pubspec.yaml; then
            log "🔄 Commenting out sign_in_with_apple dependency..."
            sed -i.bak 's/^  sign_in_with_apple:/  # sign_in_with_apple:  # Uncomment when IS_APPLE_AUTH=true/' pubspec.yaml
        fi
    fi

    # Update dependencies
    log "📦 Updating dependencies..."
    flutter pub get

    # Update OAuth service imports
    if [ -f "lib/scripts/utils/update_oauth_imports.sh" ]; then
        chmod +x lib/scripts/utils/update_oauth_imports.sh
        source lib/scripts/utils/update_oauth_imports.sh
        update_oauth_imports
    fi

    log "✅ OAuth configuration completed"
}

# Main execution
main() {
    log "🚀 Starting OAuth configuration..."
    
    # Validate environment
    if [ -z "${IS_GOOGLE_AUTH:-}" ] && [ -z "${IS_APPLE_AUTH:-}" ]; then
        log "⚠️ No OAuth variables detected, using defaults"
        export IS_GOOGLE_AUTH=false
        export IS_APPLE_AUTH=false
    fi
    
    # Configure OAuth dependencies
    configure_oauth_dependencies
    
    log "🎉 OAuth configuration completed successfully"
}

# Run main function
main "$@" 