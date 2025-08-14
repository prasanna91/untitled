#!/usr/bin/env bash

# Fix Speech Recognition Permissions for iOS
# Adds missing NSSpeechRecognitionUsageDescription to Info.plist

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🔊 Fixing Speech Recognition Permissions..."

# Check if Info.plist exists
if [[ ! -f "ios/Runner/Info.plist" ]]; then
    log_error "Info.plist not found at ios/Runner/Info.plist"
    exit 1
fi

# Backup the original Info.plist
cp ios/Runner/Info.plist ios/Runner/Info.plist.backup
log_info "📋 Backed up original Info.plist"

# Check if NSSpeechRecognitionUsageDescription already exists
if grep -q "NSSpeechRecognitionUsageDescription" ios/Runner/Info.plist; then
    log_warning "NSSpeechRecognitionUsageDescription already exists in Info.plist"
    log_info "Current speech recognition permission:"
    grep -A 1 "NSSpeechRecognitionUsageDescription" ios/Runner/Info.plist || echo "No description found"
else
    log_info "Adding NSSpeechRecognitionUsageDescription to Info.plist..."
    
    # Add the speech recognition permission before the closing </dict> tag
    sed -i '' '/<\/dict>/i\
	<key>NSSpeechRecognitionUsageDescription</key>\
	<string>This app uses speech recognition to convert your voice to text for better accessibility and user experience.</string>\
' ios/Runner/Info.plist
    
    log_success "✅ Added NSSpeechRecognitionUsageDescription to Info.plist"
fi

# Verify the permission was added correctly
if grep -q "NSSpeechRecognitionUsageDescription" ios/Runner/Info.plist; then
    log_success "✅ Speech recognition permission verified in Info.plist"
    log_info "Speech recognition permission details:"
    grep -A 1 "NSSpeechRecognitionUsageDescription" ios/Runner/Info.plist
else
    log_error "❌ Failed to add speech recognition permission"
    exit 1
fi

# Also check for other speech-related permissions that might be needed
log_info "🔍 Checking for other speech-related permissions..."

# Check for NSMicrophoneUsageDescription (required for speech recognition)
if ! grep -q "NSMicrophoneUsageDescription" ios/Runner/Info.plist; then
    log_warning "⚠️ NSMicrophoneUsageDescription not found - adding it..."
    sed -i '' '/<\/dict>/i\
	<key>NSMicrophoneUsageDescription</key>\
	<string>This app needs microphone access for speech recognition and voice recording features.</string>\
' ios/Runner/Info.plist
    log_success "✅ Added NSMicrophoneUsageDescription"
fi

# Check for NSSpeechRecognitionUsageDescription in entitlements if needed
if [[ -f "ios/Runner/Runner.entitlements" ]]; then
    log_info "🔍 Checking Runner.entitlements for speech recognition..."
    if ! grep -q "com.apple.developer.speech.recognition" ios/Runner/Runner.entitlements; then
        log_info "Adding speech recognition entitlement..."
        sed -i '' '/<\/dict>/i\
	<key>com.apple.developer.speech.recognition</key>\
	<true/>\
' ios/Runner/Runner.entitlements
        log_success "✅ Added speech recognition entitlement"
    else
        log_success "✅ Speech recognition entitlement already exists"
    fi
fi

# Validate the Info.plist file
log_info "🔍 Validating Info.plist syntax..."
if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
    log_success "✅ Info.plist syntax is valid"
else
    log_error "❌ Info.plist syntax is invalid"
    plutil -lint ios/Runner/Info.plist
    exit 1
fi

# Show summary of all speech-related permissions
log_info "📋 Speech-related permissions summary:"
echo "=========================================="
grep -E "(NSSpeechRecognitionUsageDescription|NSMicrophoneUsageDescription)" ios/Runner/Info.plist || echo "No speech-related permissions found"

log_success "🎉 Speech recognition permissions fix completed successfully" 