#!/bin/bash

# iOS Workflow Post-Build Script
# Handles post-build processes including IPA creation, validation, and TestFlight upload

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🛡️ Post-build improved IPA creation and validation..."

# Make new scripts executable
chmod +x lib/scripts/ios/improved_ipa_export.sh 2>/dev/null || true
chmod +x lib/scripts/ios/app_store_ready_check.sh 2>/dev/null || true

# Check for existing IPA files
IPA_FILES=$(find output/ios -name "*.ipa" -type f 2>/dev/null || true)

if [ -z "$IPA_FILES" ]; then
  echo "⚠️ No IPA files found, attempting improved IPA creation..."
  
  # Use improved IPA export with fallbacks
  if [ -f "lib/scripts/ios/improved_ipa_export.sh" ]; then
    echo "🚀 Using improved IPA export with fallback methods..."
    if ./lib/scripts/ios/improved_ipa_export.sh --create-with-fallbacks "output/ios" "Runner.ipa"; then
      echo "✅ Improved IPA creation successful"
    else
      echo "❌ Improved IPA creation failed, trying legacy methods..."
      
      # Fallback to legacy methods
      ARCHIVE_FILES=$(find . -name "*.xcarchive" -type d 2>/dev/null || true)
      if [ -n "$ARCHIVE_FILES" ]; then
        ARCHIVE_PATH=$(echo "$ARCHIVE_FILES" | head -1)
        echo "📦 Using archive: $ARCHIVE_PATH"
        
        # Try archive structure fix
        if [ -f "lib/scripts/ios/archive_structure_fix.sh" ]; then
          chmod +x "lib/scripts/ios/archive_structure_fix.sh"
          if ./lib/scripts/ios/archive_structure_fix.sh "$ARCHIVE_PATH" "output/ios" "Runner.ipa"; then
            echo "✅ Legacy archive structure fix successful"
          else
            echo "❌ Legacy archive structure fix failed"
          fi
        fi
      fi
    fi
  else
    echo "⚠️ Improved IPA export script not found, using legacy methods..."
    
    # Legacy fallback
    ARCHIVE_FILES=$(find . -name "*.xcarchive" -type d 2>/dev/null || true)
    if [ -n "$ARCHIVE_FILES" ]; then
      ARCHIVE_PATH=$(echo "$ARCHIVE_FILES" | head -1)
      echo "📦 Using archive: $ARCHIVE_PATH"
      
      if [ -f "lib/scripts/ios/archive_structure_fix.sh" ]; then
        chmod +x "lib/scripts/ios/archive_structure_fix.sh"
        ./lib/scripts/ios/archive_structure_fix.sh "$ARCHIVE_PATH" "output/ios" "Runner.ipa" || true
      fi
    fi
  fi
else
  echo "✅ IPA files found, performing comprehensive validation..."
  
  # Validate each IPA file
  echo "$IPA_FILES" | while read -r ipa_file; do
    echo "🔍 Validating IPA: $ipa_file"
    
    # Check file size
    IPA_SIZE=$(stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file" 2>/dev/null || echo "0")
    echo "📋 IPA file size: $IPA_SIZE bytes"
    
    if [ "$IPA_SIZE" -lt 1000000 ]; then
      echo "❌ IPA file is too small ($IPA_SIZE bytes) - corrupted"
      echo "🛡️ Attempting to recreate IPA using improved export..."
      
      if [ -f "lib/scripts/ios/improved_ipa_export.sh" ]; then
        if ./lib/scripts/ios/improved_ipa_export.sh --create-with-fallbacks "output/ios" "Runner.ipa"; then
          echo "✅ IPA recreated successfully with improved export"
        else
          echo "❌ Failed to recreate IPA with improved export"
        fi
      fi
    else
      # Perform comprehensive App Store validation
      if [ -f "lib/scripts/ios/app_store_ready_check.sh" ]; then
        echo "🔍 Performing App Store ready check..."
        if ./lib/scripts/ios/app_store_ready_check.sh --validate "$ipa_file" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
          echo "✅ App Store validation passed: $ipa_file"
        else
          echo "⚠️ App Store validation failed, attempting to fix..."
          if ./lib/scripts/ios/app_store_ready_check.sh --fix "$ipa_file" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
            echo "✅ App Store issues fixed: $ipa_file"
          else
            echo "❌ Failed to fix App Store issues: $ipa_file"
          fi
        fi
      else
        echo "⚠️ App Store ready check script not found"
      fi
    fi
  done
fi

echo "✅ Post-build IPA creation and validation completed" 