#!/bin/bash
set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [OAUTH_IMPORTS] $1" >&2; }

# Update OAuth service imports based on environment variables
update_oauth_imports() {
    log "🔐 Updating OAuth service imports..."

    local oauth_service_file="lib/services/oauth_service.dart"
    
    if [ ! -f "$oauth_service_file" ]; then
        log "❌ OAuth service file not found: $oauth_service_file"
        return 1
    fi

    # Backup original file
    cp "$oauth_service_file" "${oauth_service_file}.backup"
    log "📋 Backed up original OAuth service file"

    # Check if Apple Auth is enabled
    if [ "${IS_APPLE_AUTH:-false}" = "true" ]; then
        log "✅ Apple Auth is enabled - uncommenting sign_in_with_apple import"
        
        # Uncomment the Apple Sign-In import
        sed -i.bak 's|// import '\''package:sign_in_with_apple/sign_in_with_apple.dart'\'';|import '\''package:sign_in_with_apple/sign_in_with_apple.dart'\'';|' "$oauth_service_file"
        
        # Update the Apple Sign-In method to use the actual implementation
        sed -i.bak '/Placeholder for Apple Sign-In implementation/,/debugPrint("⚠️ Apple Sign-In package not available");/d' "$oauth_service_file"
        
        # Add the actual Apple Sign-In implementation
        cat >> "$oauth_service_file" << 'EOF'
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint("✅ Apple Sign-In successful for: ${credential.email}");

      return {
        'provider': 'apple',
        'id': credential.userIdentifier,
        'email': credential.email,
        'displayName':
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim(),
        'accessToken': credential.authorizationCode,
        'identityToken': credential.identityToken,
      };
EOF
    else
        log "⚠️ Apple Auth is disabled - keeping sign_in_with_apple import commented"
        
        # Ensure the import is commented out
        sed -i.bak 's|import '\''package:sign_in_with_apple/sign_in_with_apple.dart'\'';|// import '\''package:sign_in_with_apple/sign_in_with_apple.dart'\'';|' "$oauth_service_file"
    fi

    # Check if Google Auth is enabled
    if [ "${IS_GOOGLE_AUTH:-false}" = "true" ]; then
        log "✅ Google Auth is enabled"
    else
        log "⚠️ Google Auth is disabled"
    fi

    log "✅ OAuth service imports updated successfully"
}

# Main execution
main() {
    log "🚀 Starting OAuth imports update..."
    
    # Validate environment
    if [ -z "${IS_GOOGLE_AUTH:-}" ] && [ -z "${IS_APPLE_AUTH:-}" ]; then
        log "⚠️ No OAuth variables detected, using defaults"
        export IS_GOOGLE_AUTH=false
        export IS_APPLE_AUTH=false
    fi
    
    # Update OAuth imports
    update_oauth_imports
    
    log "🎉 OAuth imports update completed successfully"
}

# Run main function
main "$@" 