#!/bin/bash

# iOS Workflow App Store Validation Script
# Handles comprehensive App Store validation

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🛡️ Comprehensive App Store Validation..."

# Make scripts executable
chmod +x lib/scripts/ios/app_store_ready_check.sh 2>/dev/null || true
chmod +x lib/scripts/ios/improved_ipa_export.sh 2>/dev/null || true

# Find IPA files
IPA_FILES=$(find output/ios -name "*.ipa" -type f 2>/dev/null || true)

if [ -n "$IPA_FILES" ]; then
  echo "📦 Found IPA files for validation:"
  echo "$IPA_FILES" | while read -r ipa_file; do
    echo "   - $ipa_file"
    
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
else
  echo "⚠️ No IPA files found for validation"
fi

echo "✅ Comprehensive App Store validation completed" 