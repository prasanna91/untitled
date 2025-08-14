#!/bin/bash

# iOS Workflow TestFlight Upload Script
# Handles TestFlight upload using App Store Connect API credentials

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

if [ "${IS_TESTFLIGHT:-false}" = "true" ]; then
  echo "🚀 Uploading IPA to TestFlight using App Store Connect API credentials..."
  
  # Required variables
  API_KEY_ID="${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
  API_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-}"
  API_KEY_URL="${APP_STORE_CONNECT_API_KEY_PATH:-}"

  if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ] || [ -z "$API_KEY_URL" ]; then
    echo "❌ Missing App Store Connect API credentials."
    echo "   APP_STORE_CONNECT_KEY_IDENTIFIER: $API_KEY_ID"
    echo "   APP_STORE_CONNECT_ISSUER_ID: $API_ISSUER_ID"
    echo "   APP_STORE_CONNECT_API_KEY_PATH: $API_KEY_URL"
    exit 1
  fi

  # Create private keys directory
  echo "📁 Setting up API key directory..."
  PRIVATE_KEYS_DIR="$HOME/.appstoreconnect/private_keys"
  mkdir -p "$PRIVATE_KEYS_DIR"
  echo "✅ Created directory: $PRIVATE_KEYS_DIR"

  # Download API key file
  echo "📥 Downloading API key file..."
  API_KEY_FILENAME="AuthKey_${API_KEY_ID}.p8"
  API_KEY_PATH="$PRIVATE_KEYS_DIR/$API_KEY_FILENAME"
  
  if curl -L -o "$API_KEY_PATH" "$API_KEY_URL" 2>/dev/null; then
    echo "✅ Downloaded API key to: $API_KEY_PATH"
    chmod 600 "$API_KEY_PATH"
    echo "✅ Set proper permissions on API key file"
  else
    echo "❌ Failed to download API key from: $API_KEY_URL"
    echo "🔍 Checking if API key URL is accessible..."
    curl -I "$API_KEY_URL" 2>/dev/null || echo "⚠️ API key URL not accessible"
    exit 1
  fi

  # Find the largest valid IPA in output/ios/ (not just the latest)
  IPA_PATH=""
  IPA_SIZE=0
  for ipa in output/ios/*.ipa; do
    if [ -f "$ipa" ]; then
      size=$(stat -f%z "$ipa" 2>/dev/null || stat -c%s "$ipa" 2>/dev/null || echo "0")
      if [ "$size" -gt "$IPA_SIZE" ]; then
        IPA_PATH="$ipa"
        IPA_SIZE="$size"
      fi
    fi
  done

  if [ -z "$IPA_PATH" ]; then
    echo "❌ No IPA file found in output/ios/"
    exit 1
  fi

  echo "📦 IPA to upload: $IPA_PATH"
  echo "📋 IPA file size: $IPA_SIZE bytes"

  # Validate IPA file size (require at least 1MB for valid IPA)
  if [ "$IPA_SIZE" -lt 1000000 ]; then
    echo "❌ IPA file is too small ($IPA_SIZE bytes) - likely corrupted"
    echo "🔧 This indicates the IPA export process failed"
    echo "🛡️ Attempting to recreate IPA using improved export..."
    
    # Use improved IPA export with fallbacks
    if [ -f "lib/scripts/ios/improved_ipa_export.sh" ]; then
      chmod +x "lib/scripts/ios/improved_ipa_export.sh"
      
      if ./lib/scripts/ios/improved_ipa_export.sh --create-with-fallbacks "output/ios" "Runner.ipa"; then
        echo "✅ IPA recreated successfully with improved export"
      else
        echo "❌ Improved IPA export failed, trying legacy methods..."
        
        # Fallback to archive structure fix
        if [ -f "lib/scripts/ios/archive_structure_fix.sh" ]; then
          chmod +x "lib/scripts/ios/archive_structure_fix.sh"
          
          # Find archive
          ARCHIVE_FILES=$(find . -name "*.xcarchive" -type d 2>/dev/null || true)
          if [ -n "$ARCHIVE_FILES" ]; then
            ARCHIVE_PATH=$(echo "$ARCHIVE_FILES" | head -1)
            echo "📦 Using archive: $ARCHIVE_PATH"
            
            if ./lib/scripts/ios/archive_structure_fix.sh "$ARCHIVE_PATH" "output/ios" "Runner.ipa"; then
              echo "✅ IPA recreated successfully with archive structure fix"
            else
              echo "❌ Archive structure fix failed"
              echo "🚨 Cannot upload corrupted IPA to TestFlight"
              exit 1
            fi
          else
            echo "⚠️ No archive found for IPA recreation"
            echo "🚨 Cannot upload corrupted IPA to TestFlight"
            exit 1
          fi
        else
          echo "⚠️ Archive structure fix script not found"
          echo "🚨 Cannot upload corrupted IPA to TestFlight"
          exit 1
        fi
      fi
    else
      echo "⚠️ Improved IPA export script not found, trying legacy methods..."
      
      # Fallback to archive structure fix
      if [ -f "lib/scripts/ios/archive_structure_fix.sh" ]; then
        chmod +x "lib/scripts/ios/archive_structure_fix.sh"
        
        # Find archive
        ARCHIVE_FILES=$(find . -name "*.xcarchive" -type d 2>/dev/null || true)
        if [ -n "$ARCHIVE_FILES" ]; then
          ARCHIVE_PATH=$(echo "$ARCHIVE_FILES" | head -1)
          echo "📦 Using archive: $ARCHIVE_PATH"
          
          if ./lib/scripts/ios/archive_structure_fix.sh "$ARCHIVE_PATH" "output/ios" "Runner.ipa"; then
            echo "✅ IPA recreated successfully with archive structure fix"
          else
            echo "❌ Archive structure fix failed"
            echo "🚨 Cannot upload corrupted IPA to TestFlight"
            exit 1
          fi
        else
          echo "⚠️ No archive found for IPA recreation"
          echo "🚨 Cannot upload corrupted IPA to TestFlight"
          exit 1
        fi
      else
        echo "⚠️ Archive structure fix script not found"
        echo "🚨 Cannot upload corrupted IPA to TestFlight"
        exit 1
      fi
    fi
    
    # Update IPA path and size
    IPA_PATH="output/ios/Runner.ipa"
    IPA_SIZE=$(stat -f%z "$IPA_PATH" 2>/dev/null || stat -c%s "$IPA_PATH" 2>/dev/null || echo "0")
    echo "📦 New IPA to upload: $IPA_PATH"
    echo "📋 New IPA file size: $IPA_SIZE bytes"
    
    # Validate new IPA size (require at least 1MB)
    if [ "$IPA_SIZE" -lt 1000000 ]; then
      echo "❌ Recreated IPA is still too small ($IPA_SIZE bytes)"
      echo "🔍 This indicates the app bundle itself is corrupted"
      echo "🛡️ Attempting to rebuild the entire app..."
      
      # Try to rebuild the app from source
      echo "🔄 Rebuilding iOS app from source..."
      flutter clean
      flutter pub get
      
      # Try to build again
      if flutter build ios --release --no-codesign; then
        echo "✅ App rebuilt successfully"
        
        # Try to create IPA again
        if [ -f "lib/scripts/ios/improved_ipa_export.sh" ]; then
          if ./lib/scripts/ios/improved_ipa_export.sh --create-with-fallbacks "output/ios" "Runner.ipa"; then
            echo "✅ IPA created successfully after rebuild"
            
            # Check final IPA size
            IPA_PATH="output/ios/Runner.ipa"
            IPA_SIZE=$(stat -f%z "$IPA_PATH" 2>/dev/null || stat -c%s "$IPA_PATH" 2>/dev/null || echo "0")
            echo "📦 Final IPA to upload: $IPA_PATH"
            echo "📋 Final IPA file size: $IPA_SIZE bytes"
            
            if [ "$IPA_SIZE" -lt 1000000 ]; then
              echo "❌ Rebuilt IPA is still too small ($IPA_SIZE bytes)"
              echo "🚨 Cannot upload corrupted IPA to TestFlight"
              exit 1
            fi
          else
            echo "❌ Failed to create IPA after rebuild"
            echo "🚨 Cannot upload corrupted IPA to TestFlight"
            exit 1
          fi
        else
          echo "❌ Improved IPA export script not found after rebuild"
          echo "🚨 Cannot upload corrupted IPA to TestFlight"
          exit 1
        fi
      else
        echo "❌ Failed to rebuild app"
        echo "🚨 Cannot upload corrupted IPA to TestFlight"
        exit 1
      fi
    fi
  fi
  
  # Validate IPA structure before upload
  echo "🔍 Validating IPA structure before upload..."
  if [ -f "lib/scripts/ios/app_store_ready_check.sh" ]; then
    chmod +x "lib/scripts/ios/app_store_ready_check.sh"
    
    if ./lib/scripts/ios/app_store_ready_check.sh --validate "$IPA_PATH" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
      echo "✅ IPA structure validation passed"
    else
      echo "❌ IPA structure validation failed"
      echo "🛡️ Attempting to fix IPA structure before upload..."
      
      if ./lib/scripts/ios/app_store_ready_check.sh --fix "$IPA_PATH" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
        echo "✅ IPA structure fixed before upload"
      else
        echo "❌ Failed to fix IPA structure before upload"
        echo "🚨 Cannot upload corrupted IPA to TestFlight"
        exit 1
      fi
    fi
  else
    echo "⚠️ App Store ready check script not found, skipping validation"
  fi

  # Verify API key file exists and is readable
  if [ ! -f "$API_KEY_PATH" ]; then
    echo "❌ API key file not found at: $API_KEY_PATH"
    exit 1
  fi

  if [ ! -r "$API_KEY_PATH" ]; then
    echo "❌ API key file not readable: $API_KEY_PATH"
    exit 1
  fi

  echo "🔑 Using App Store Connect API key: $API_KEY_ID"
  echo "📋 API key file: $API_KEY_PATH"
  echo "🔄 Uploading IPA to TestFlight..."

  # Upload using xcrun altool with API key
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID" \
    --verbose || {
      echo "❌ TestFlight upload failed. Check credentials and logs above.";
      echo "🔍 Debugging information:";
      echo "   API Key ID: $API_KEY_ID";
      echo "   API Issuer ID: $API_ISSUER_ID";
      echo "   API Key Path: $API_KEY_PATH";
      echo "   API Key File Size: $(ls -lh "$API_KEY_PATH" 2>/dev/null | awk '{print $5}' || echo 'unknown')";
      echo "   IPA File Size: $(ls -lh "$IPA_PATH" 2>/dev/null | awk '{print $5}' || echo 'unknown')";
      exit 1;
    }
  echo "✅ IPA uploaded to TestFlight successfully!"
else
  echo "⚠️ IS_TESTFLIGHT is not true. Skipping TestFlight upload step."
fi 