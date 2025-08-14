#!/bin/bash

# 🚀 TestFlight Upload Script
# Uploads IPA to TestFlight using App Store Connect API

set -euo pipefail

# Enhanced logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

log_info "🚀 Starting TestFlight upload process..."

# Check required environment variables
REQUIRED_VARS=(
    "APP_STORE_CONNECT_KEY_IDENTIFIER"
    "APP_STORE_CONNECT_ISSUER_ID"
    "APP_STORE_CONNECT_API_KEY_URL"
    "BUNDLE_ID"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        log_error "Required environment variable $var is not set"
        exit 1
    fi
done

# Find IPA file
IPA_PATH=""
for path in "build/ios/output/*.ipa" "output/ios/*.ipa" "*.ipa"; do
    IPA_FOUND=$(find . -path "$path" -name "*.ipa" | head -n 1)
    if [ -n "$IPA_FOUND" ]; then
        IPA_PATH="$IPA_FOUND"
        break
    fi
done

if [ -z "$IPA_PATH" ]; then
    log_error "❌ IPA file not found. Please build the app first."
    exit 1
fi

log_success "✅ Found IPA: $IPA_PATH"

# Download App Store Connect API key
log_info "📥 Downloading App Store Connect API key..."
API_KEY_DIR="$HOME/private_keys"
API_KEY_PATH="$API_KEY_DIR/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"

mkdir -p "$API_KEY_DIR"

if [ -n "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    curl -fSL "$APP_STORE_CONNECT_API_KEY_URL" -o "$API_KEY_PATH"
    chmod 600 "$API_KEY_PATH"
    log_success "✅ API key downloaded to $API_KEY_PATH"
else
    log_error "❌ APP_STORE_CONNECT_API_KEY_URL is required"
    exit 1
fi

# Validate the API key
log_info "🔍 Validating API key..."
if [ ! -f "$API_KEY_PATH" ]; then
    log_error "❌ API key file not found at $API_KEY_PATH"
    exit 1
fi

# Upload to TestFlight using xcrun altool
log_info "📤 Uploading to TestFlight..."

# First, validate the IPA
log_info "🔍 Validating IPA before upload..."
xcrun altool --validate-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
    --verbose

if [ $? -eq 0 ]; then
    log_success "✅ IPA validation successful"
else
    log_error "❌ IPA validation failed"
    exit 1
fi

# Upload to TestFlight
log_info "📤 Uploading to TestFlight..."
xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
    --verbose

if [ $? -eq 0 ]; then
    log_success "✅ App uploaded to TestFlight successfully!"
else
    log_error "❌ TestFlight upload failed"
    exit 1
fi

# Create upload summary
log_info "📋 Creating upload summary..."
mkdir -p output/ios
cat > output/ios/TESTFLIGHT_UPLOAD_SUMMARY.txt << EOF
TestFlight Upload Summary
=========================

Upload Information:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: $BUNDLE_ID
- Version: ${VERSION_NAME:-Unknown}
- Build Number: ${VERSION_CODE:-Unknown}
- Team ID: ${APPLE_TEAM_ID:-Unknown}

Upload Details:
- IPA File: $IPA_PATH
- API Key ID: $APP_STORE_CONNECT_KEY_IDENTIFIER
- Issuer ID: $APP_STORE_CONNECT_ISSUER_ID
- Upload Date: $(date)

Status: ✅ SUCCESS
Message: App uploaded to TestFlight successfully

Next Steps:
1. Check App Store Connect for processing status
2. Wait for Apple's review process
3. Distribute to testers once approved

Notes:
- Processing time: Usually 5-15 minutes
- Review time: Usually 1-2 hours
- TestFlight distribution: Available after approval
EOF

log_success "✅ Upload summary created: output/ios/TESTFLIGHT_UPLOAD_SUMMARY.txt"

# Clean up API key for security
rm -f "$API_KEY_PATH"

log_success "🎉 TestFlight upload completed successfully!"
log_info "📱 App is now being processed for TestFlight distribution"
log_info "📋 Check App Store Connect for processing status" 