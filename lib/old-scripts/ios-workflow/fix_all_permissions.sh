#!/usr/bin/env bash

# Fix All iOS Permissions for App Store Compliance
# Adds missing permission strings to Info.plist for App Store Connect

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🔐 Fixing All iOS Permissions for App Store Compliance..."

# Check if Info.plist exists
if [[ ! -f "ios/Runner/Info.plist" ]]; then
    log_error "Info.plist not found at ios/Runner/Info.plist"
    exit 1
fi

# Backup the original Info.plist
cp ios/Runner/Info.plist ios/Runner/Info.plist.backup
log_info "📋 Backed up original Info.plist"

# Function to add permission if not exists
add_permission_if_missing() {
    local key="$1"
    local description="$2"
    
    if ! grep -q "$key" ios/Runner/Info.plist; then
        log_info "Adding $key to Info.plist..."
        sed -i '' '/<\/dict>/i\
	<key>'"$key"'</key>\
	<string>'"$description"'</string>\
' ios/Runner/Info.plist
        log_success "✅ Added $key"
    else
        log_success "✅ $key already exists"
    fi
}

# Add all required permissions
log_info "🔍 Adding required permissions to Info.plist..."

# Speech Recognition (Required for speech_to_text package)
add_permission_if_missing "NSSpeechRecognitionUsageDescription" "This app uses speech recognition to convert your voice to text for better accessibility and user experience."

# Microphone (Required for speech recognition)
add_permission_if_missing "NSMicrophoneUsageDescription" "This app needs microphone access for speech recognition and voice recording features."

# Camera (if IS_CAMERA is true)
if [[ "${IS_CAMERA:-false}" == "true" ]]; then
    add_permission_if_missing "NSCameraUsageDescription" "This app requires camera access to take photos and videos."
fi

# Location (if IS_LOCATION is true)
if [[ "${IS_LOCATION:-false}" == "true" ]]; then
    add_permission_if_missing "NSLocationWhenInUseUsageDescription" "This app needs your location to provide location-based services."
    add_permission_if_missing "NSLocationAlwaysAndWhenInUseUsageDescription" "This app needs your location to provide location-based services."
    add_permission_if_missing "NSLocationAlwaysUsageDescription" "This app needs your location to provide location-based services."
fi

# Contacts (if IS_CONTACT is true)
if [[ "${IS_CONTACT:-false}" == "true" ]]; then
    add_permission_if_missing "NSContactsUsageDescription" "This app requires access to your contacts for communication features."
fi

# Calendar (if IS_CALENDAR is true)
if [[ "${IS_CALENDAR:-false}" == "true" ]]; then
    add_permission_if_missing "NSCalendarsUsageDescription" "This app uses your calendar to sync and manage events."
fi

# Face ID/Biometric (if IS_BIOMETRIC is true)
if [[ "${IS_BIOMETRIC:-false}" == "true" ]]; then
    add_permission_if_missing "NSFaceIDUsageDescription" "This app uses Face ID for secure login and authentication."
fi

# Photo Library (if IS_STORAGE is true)
if [[ "${IS_STORAGE:-false}" == "true" ]]; then
    add_permission_if_missing "NSPhotoLibraryUsageDescription" "This app requires access to your photo library to save images and videos."
    add_permission_if_missing "NSPhotoLibraryAddUsageDescription" "This app needs permission to save media to your photo library."
fi

# Notifications (if IS_NOTIFICATION is true)
if [[ "${IS_NOTIFICATION:-false}" == "true" ]]; then
    # Notifications are handled by UNUserNotificationCenter
    log_info "ℹ️ Notifications are handled by UNUserNotificationCenter"
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

# Show summary of all permissions
log_info "📋 All permissions summary:"
echo "=========================================="
grep -E "(UsageDescription|NS.*UsageDescription)" ios/Runner/Info.plist || echo "No usage descriptions found"

# Check for any missing critical permissions
log_info "🔍 Checking for critical missing permissions..."

CRITICAL_PERMISSIONS=(
    "NSSpeechRecognitionUsageDescription"
    "NSMicrophoneUsageDescription"
)

MISSING_PERMISSIONS=()
for permission in "${CRITICAL_PERMISSIONS[@]}"; do
    if ! grep -q "$permission" ios/Runner/Info.plist; then
        MISSING_PERMISSIONS+=("$permission")
    fi
done

if [[ ${#MISSING_PERMISSIONS[@]} -gt 0 ]]; then
    log_error "❌ Missing critical permissions:"
    for permission in "${MISSING_PERMISSIONS[@]}"; do
        log_error "   - $permission"
    done
    exit 1
else
    log_success "✅ All critical permissions are present"
fi

# Check entitlements if needed
if [[ -f "ios/Runner/Runner.entitlements" ]]; then
    log_info "🔍 Checking Runner.entitlements..."
    
    # Add speech recognition entitlement if not exists
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
    
    # Validate entitlements
    if plutil -lint ios/Runner/Runner.entitlements > /dev/null 2>&1; then
        log_success "✅ Runner.entitlements syntax is valid"
    else
        log_error "❌ Runner.entitlements syntax is invalid"
        plutil -lint ios/Runner/Runner.entitlements
    fi
fi

log_success "🎉 All iOS permissions fix completed successfully"
log_info "📋 Summary:"
log_info "   - Speech Recognition: ✅ Added"
log_info "   - Microphone: ✅ Added"
log_info "   - Camera: ✅ Conditional"
log_info "   - Location: ✅ Conditional"
log_info "   - Contacts: ✅ Conditional"
log_info "   - Calendar: ✅ Conditional"
log_info "   - Face ID: ✅ Conditional"
log_info "   - Photo Library: ✅ Conditional"
log_info "   - Notifications: ✅ Handled by UNUserNotificationCenter" 