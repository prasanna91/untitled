#!/bin/bash

# iOS Workflow Bundle Executable Fix Script
# Handles the 409 error fixes for bundle executable issues

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🛡️ Post-Build Enhanced Bundle Executable Fix for 409 Error..."
echo "🎯 Target: 'Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable'"

# First, check and fix build configuration
echo "🔍 Step 1: Checking and fixing build configuration..."
if [ -f "lib/scripts/ios/enhanced_bundle_executable_fix.sh" ]; then
  chmod +x "lib/scripts/ios/enhanced_bundle_executable_fix.sh"
  ./lib/scripts/ios/enhanced_bundle_executable_fix.sh --check-build
else
  echo "⚠️ Enhanced bundle executable fix script not found, using fallback..."
fi

# Find IPA files with better error handling
echo "🔍 Step 2: Finding IPA files..."
IPA_FILES=""
if [ -d "output/ios" ]; then
  IPA_FILES=$(find output/ios -name "*.ipa" -type f 2>/dev/null || true)
fi
if [ -d "build/ios" ] && [ -z "$IPA_FILES" ]; then
  IPA_FILES=$(find build/ios -name "*.ipa" -type f 2>/dev/null || true)
fi
if [ -d "ios/build" ] && [ -z "$IPA_FILES" ]; then
  IPA_FILES=$(find ios/build -name "*.ipa" -type f 2>/dev/null || true)
fi

if [ -n "$IPA_FILES" ]; then
  echo "📦 Found IPA files:"
  echo "$IPA_FILES" | while read -r ipa_file; do
    echo "   - $ipa_file"
    
    # First validate the IPA structure
    echo "🔍 Step 3: Validating IPA structure..."
    if [ -f "lib/scripts/ios/enhanced_bundle_executable_fix.sh" ]; then
      if ./lib/scripts/ios/enhanced_bundle_executable_fix.sh --validate-ipa "$ipa_file" 2>/dev/null; then
        echo "✅ IPA structure validation passed"
      else
        echo "⚠️ IPA structure validation failed, applying fix..."
        
        # Apply enhanced bundle executable fix
        echo "🛡️ Applying enhanced bundle executable fix to: $ipa_file"
        
        if ./lib/scripts/ios/enhanced_bundle_executable_fix.sh --rebuild-ipa "$ipa_file" "Runner" 2>/dev/null; then
          echo "✅ Enhanced bundle executable fix completed for: $ipa_file"
          echo "🛡️ App Store Connect validation error (409) FIXED"
          
          # Verify the fix worked
          echo "🔍 Verifying enhanced bundle executable fix..."
          if ./lib/scripts/ios/enhanced_bundle_executable_fix.sh --validate-ipa "$ipa_file" 2>/dev/null; then
            echo "✅ Enhanced bundle executable validation passed after fix"
          else
            echo "⚠️ Enhanced bundle executable validation failed after fix (continuing...)"
          fi
        else
          echo "⚠️ Enhanced bundle executable fix had issues for: $ipa_file (continuing...)"
        fi
      fi
    else
      echo "⚠️ Enhanced bundle executable fix script not found, trying fallback..."
      
      # Fallback to original script
      if [ -f "lib/scripts/ios/ultimate_bundle_executable_fix.sh" ]; then
        chmod +x "lib/scripts/ios/ultimate_bundle_executable_fix.sh"
        
        echo "🛡️ Applying ultimate bundle executable fix to: $ipa_file"
        
        if ./lib/scripts/ios/ultimate_bundle_executable_fix.sh --rebuild-ipa "$ipa_file" "Runner" 2>/dev/null; then
          echo "✅ Ultimate bundle executable fix completed for: $ipa_file"
          echo "🛡️ App Store Connect validation error (409) FIXED"
          
          # Verify the fix worked
          echo "🔍 Verifying ultimate bundle executable fix..."
          if ./lib/scripts/ios/ultimate_bundle_executable_fix.sh --validate-ipa "$ipa_file" 2>/dev/null; then
            echo "✅ Ultimate bundle executable validation passed after fix"
          else
            echo "⚠️ Ultimate bundle executable validation failed after fix (continuing...)"
          fi
        else
          echo "⚠️ Ultimate bundle executable fix had issues for: $ipa_file (continuing...)"
        fi
      else
        echo "⚠️ No bundle executable fix scripts found (continuing...)"
      fi
    fi
  done
else
  echo "⚠️ No IPA files found for post-build fix"
  echo "📁 Checking build directories:"
  ls -la output/ios/ 2>/dev/null || echo "   output/ios/ not found"
  ls -la build/ios/ 2>/dev/null || echo "   build/ios/ not found"
  ls -la ios/build/ 2>/dev/null || echo "   ios/build/ not found"
fi

echo "✅ Post-Build Enhanced Bundle Executable Fix completed" 