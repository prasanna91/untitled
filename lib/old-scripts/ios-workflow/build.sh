#!/bin/bash

# iOS Workflow Build Script
# Handles the actual build process for ios-workflow with Target-Only Mode support

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🏗️ Starting iOS Workflow Build..."

# 🛡️ Target-Only Mode Validation
echo "🛡️ Target-Only Mode Build Configuration:"
echo "  - TARGET_ONLY_MODE: ${TARGET_ONLY_MODE:-false}"
echo "  - ENABLE_COLLISION_FIX: ${ENABLE_COLLISION_FIX:-false}"
echo "  - ENABLE_FRAMEWORK_BUNDLE_UPDATE: ${ENABLE_FRAMEWORK_BUNDLE_UPDATE:-false}"
echo "  - ENABLE_BUNDLE_ID_ECHO: ${ENABLE_BUNDLE_ID_ECHO:-true}"

# Validate target-only mode is enabled
if [ "${TARGET_ONLY_MODE:-false}" != "true" ]; then
    echo "❌ TARGET_ONLY_MODE must be enabled for this workflow"
    echo "   Please set TARGET_ONLY_MODE=true in the workflow configuration"
    exit 1
fi

echo "✅ Target-Only Mode validation passed"

chmod +x lib/scripts/ios/*.sh
chmod +x lib/scripts/utils/*.sh

# Enhanced build with retry logic
MAX_RETRIES=${MAX_RETRIES:-2}
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "🏗️ Build attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"

  # 🛡️ Target-Only Mode: Set environment variables for main.sh
  export TARGET_ONLY_MODE="true"
  export ENABLE_COLLISION_FIX="false"
  export ENABLE_FRAMEWORK_BUNDLE_UPDATE="false"
  export ENABLE_BUNDLE_ID_ECHO="true"

  if ./lib/scripts/ios/main.sh; then
    echo "✅ Build completed successfully!"
    
    # 🛡️ Target-Only Mode: Validate build results
    echo "🔍 Validating target-only mode build results..."
    
    # Check that only the main app bundle ID was updated
    if [ -f "ios/build/ios/iphoneos/Runner.app/Info.plist" ]; then
        MAIN_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "ios/build/ios/iphoneos/Runner.app/Info.plist" 2>/dev/null || echo "UNKNOWN")
        EXPECTED_BUNDLE_ID="${BUNDLE_ID:-com.example.app}"
        
        if [ "$MAIN_BUNDLE_ID" = "$EXPECTED_BUNDLE_ID" ]; then
            echo "✅ Main app bundle ID correctly updated: $MAIN_BUNDLE_ID"
        else
            echo "⚠️ Main app bundle ID mismatch: expected $EXPECTED_BUNDLE_ID, got $MAIN_BUNDLE_ID"
        fi
    fi
    
    # Echo bundle identifiers for all frameworks (should remain unchanged)
    if [ "${ENABLE_BUNDLE_ID_ECHO:-true}" = "true" ]; then
        echo "🔍 Echoing bundle identifiers for validation..."
        find ios/build -name "*.framework" -type d 2>/dev/null | while read -r framework; do
            if [ -f "$framework/Info.plist" ]; then
                framework_bundle_id=$(plutil -extract CFBundleIdentifier raw "$framework/Info.plist" 2>/dev/null || echo "UNKNOWN")
                framework_name=$(basename "$framework" .framework)
                echo "   - $framework_name.framework: $framework_bundle_id"
            fi
        done
    fi
    
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "⚠️ Build failed, retrying in 10 seconds..."
      sleep 10
      flutter clean
    else
      echo "❌ Build failed after $MAX_RETRIES attempts"
      exit 1
    fi
  fi
done

echo "✅ iOS Workflow Build completed successfully" 