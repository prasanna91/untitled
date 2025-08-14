#!/bin/bash

# 🔧 App Store Connect Fix Script for iOS Workflow
# Applies fixes for ITMS-90685 and ITMS-90183 to the built IPA

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🛡️ App Store Connect Fix Script for iOS Workflow..."

# Make the fix script executable
chmod +x lib/scripts/ios/fix_app_store_connect_issues.sh 2>/dev/null || true

# Find the largest valid IPA in output/ios/
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
    echo "📁 Checking build directories:"
    ls -la output/ios/ 2>/dev/null || echo "   output/ios/ not found"
    ls -la build/ios/ 2>/dev/null || echo "   build/ios/ not found"
    ls -la ios/build/ 2>/dev/null || echo "   ios/build/ not found"
    exit 1
fi

echo "📦 Found IPA: $IPA_PATH"
echo "📋 IPA file size: $IPA_SIZE bytes"

# Validate IPA file size (require at least 1MB for valid IPA)
if [ "$IPA_SIZE" -lt 1000000 ]; then
    echo "❌ IPA file is too small ($IPA_SIZE bytes) - likely corrupted"
    exit 1
fi

# Create temporary directory for extraction
TEMP_DIR="/tmp/ipa_fix_$(date +%s)"
mkdir -p "$TEMP_DIR"
echo "📁 Created temporary directory: $TEMP_DIR"

# Extract IPA
echo "📦 Extracting IPA..."
cd "$TEMP_DIR"
unzip -q "$IPA_PATH" || {
    echo "❌ Failed to extract IPA"
    exit 1
}

# Find the app bundle
APP_BUNDLE=""
if [ -d "Payload/Runner.app" ]; then
    APP_BUNDLE="Payload/Runner.app"
elif [ -d "Payload" ]; then
    # Find the first .app directory
    APP_BUNDLE=$(find Payload -name "*.app" -type d | head -1)
fi

if [ -z "$APP_BUNDLE" ]; then
    echo "❌ No app bundle found in extracted IPA"
    exit 1
fi

echo "📱 Found app bundle: $APP_BUNDLE"

# Get the main bundle ID
MAIN_BUNDLE_ID="${BUNDLE_ID:-com.garbcode.garbcodeapp}"
echo "🎯 Main Bundle ID: $MAIN_BUNDLE_ID"

# Apply App Store Connect fixes
echo "🔧 Applying App Store Connect fixes..."
if [ -f "lib/scripts/ios/fix_app_store_connect_issues.sh" ]; then
    if ./lib/scripts/ios/fix_app_store_connect_issues.sh "$MAIN_BUNDLE_ID" "$APP_BUNDLE"; then
        echo "✅ App Store Connect fixes applied successfully"
    else
        echo "❌ Failed to apply App Store Connect fixes"
        exit 1
    fi
else
    echo "❌ App Store Connect fix script not found"
    exit 1
fi

# Recreate IPA with fixes
echo "📦 Recreating IPA with fixes..."
cd "$TEMP_DIR"
zip -qr "$IPA_PATH" . || {
    echo "❌ Failed to recreate IPA"
    exit 1
}

# Verify the new IPA
NEW_IPA_SIZE=$(stat -f%z "$IPA_PATH" 2>/dev/null || stat -c%s "$IPA_PATH" 2>/dev/null || echo "0")
echo "📋 New IPA file size: $NEW_IPA_SIZE bytes"

if [ "$NEW_IPA_SIZE" -lt 1000000 ]; then
    echo "❌ Recreated IPA is too small ($NEW_IPA_SIZE bytes)"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"
echo "🧹 Cleaned up temporary directory"

echo "✅ App Store Connect fix completed successfully!"
echo "📦 Fixed IPA: $IPA_PATH"
echo "📋 IPA file size: $NEW_IPA_SIZE bytes"
echo "🚀 Ready for App Store Connect upload" 