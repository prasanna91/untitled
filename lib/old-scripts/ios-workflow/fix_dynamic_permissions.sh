#!/usr/bin/env bash

# Fix Dynamic iOS Permissions with Environment Variable Descriptions
# Uses environment variables for dynamic permission descriptions

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🔐 Fixing Dynamic iOS Permissions with Environment Variables..."

# Check if Info.plist exists
if [[ ! -f "ios/Runner/Info.plist" ]]; then
    log_error "Info.plist not found at ios/Runner/Info.plist"
    exit 1
fi

# Backup the original Info.plist
cp ios/Runner/Info.plist ios/Runner/Info.plist.backup
log_info "📋 Backed up original Info.plist"

# Function to add permission if not exists with dynamic description
add_permission_if_missing() {
    local key="$1"
    local description="$2"
    local condition="${3:-true}"
    
    # Check if condition is met
    if [[ "$condition" != "true" ]]; then
        log_info "⏭️ Skipping $key (condition not met)"
        return 0
    fi
    
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

# Function to get dynamic description based on app features
get_dynamic_description() {
    local permission_type="$1"
    local app_name="${APP_NAME:-QuikApp}"
    local org_name="${ORG_NAME:-QuikApp}"
    
    case "$permission_type" in
        "speech_recognition")
            if [[ "${IS_CHATBOT:-false}" == "true" ]]; then
                echo "$app_name uses speech recognition to enable voice commands and chatbot interactions for better user experience."
            else
                echo "$app_name uses speech recognition to convert your voice to text for better accessibility and user experience."
            fi
            ;;
        "microphone")
            if [[ "${IS_CHATBOT:-false}" == "true" ]]; then
                echo "$app_name needs microphone access for voice commands and chatbot interactions."
            else
                echo "$app_name needs microphone access for speech recognition and voice recording features."
            fi
            ;;
        "camera")
            echo "$app_name requires camera access to take photos and videos for enhanced functionality."
            ;;
        "location")
            echo "$app_name needs your location to provide location-based services and personalized features."
            ;;
        "contacts")
            echo "$app_name requires access to your contacts for communication features and social interactions."
            ;;
        "calendar")
            echo "$app_name uses your calendar to sync and manage events for better organization."
            ;;
        "biometric")
            echo "$app_name uses Face ID/Touch ID for secure login and authentication to protect your data."
            ;;
        "storage")
            echo "$app_name requires access to your photo library to save images and videos for sharing."
            ;;
        "notification")
            echo "$app_name sends you important notifications and updates to keep you informed."
            ;;
        *)
            echo "$app_name requires this permission for enhanced functionality."
            ;;
    esac
}

# Main permission setup
log_info "🔍 Setting up dynamic iOS permissions..."

# Speech Recognition (Required for speech_to_text package)
SPEECH_DESC=$(get_dynamic_description "speech_recognition")
add_permission_if_missing "NSSpeechRecognitionUsageDescription" "$SPEECH_DESC" "true"

# Microphone (Required for speech recognition)
MIC_DESC=$(get_dynamic_description "microphone")
add_permission_if_missing "NSMicrophoneUsageDescription" "$MIC_DESC" "true"

# Camera (if IS_CAMERA is true)
if [[ "${IS_CAMERA:-false}" == "true" ]]; then
    CAMERA_DESC=$(get_dynamic_description "camera")
    add_permission_if_missing "NSCameraUsageDescription" "$CAMERA_DESC" "true"
fi

# Location (if IS_LOCATION is true)
if [[ "${IS_LOCATION:-false}" == "true" ]]; then
    LOCATION_DESC=$(get_dynamic_description "location")
    add_permission_if_missing "NSLocationWhenInUseUsageDescription" "$LOCATION_DESC" "true"
    add_permission_if_missing "NSLocationAlwaysAndWhenInUseUsageDescription" "$LOCATION_DESC" "true"
    add_permission_if_missing "NSLocationAlwaysUsageDescription" "$LOCATION_DESC" "true"
fi

# Contacts (if IS_CONTACT is true)
if [[ "${IS_CONTACT:-false}" == "true" ]]; then
    CONTACTS_DESC=$(get_dynamic_description "contacts")
    add_permission_if_missing "NSContactsUsageDescription" "$CONTACTS_DESC" "true"
fi

# Calendar (if IS_CALENDAR is true)
if [[ "${IS_CALENDAR:-false}" == "true" ]]; then
    CALENDAR_DESC=$(get_dynamic_description "calendar")
    add_permission_if_missing "NSCalendarsUsageDescription" "$CALENDAR_DESC" "true"
fi

# Face ID/Biometric (if IS_BIOMETRIC is true)
if [[ "${IS_BIOMETRIC:-false}" == "true" ]]; then
    BIOMETRIC_DESC=$(get_dynamic_description "biometric")
    add_permission_if_missing "NSFaceIDUsageDescription" "$BIOMETRIC_DESC" "true"
fi

# Photo Library (if IS_STORAGE is true)
if [[ "${IS_STORAGE:-false}" == "true" ]]; then
    STORAGE_DESC=$(get_dynamic_description "storage")
    add_permission_if_missing "NSPhotoLibraryUsageDescription" "$STORAGE_DESC" "true"
    add_permission_if_missing "NSPhotoLibraryAddUsageDescription" "$STORAGE_DESC" "true"
fi

# Notifications (if IS_NOTIFICATION is true)
if [[ "${IS_NOTIFICATION:-false}" == "true" ]]; then
    NOTIFICATION_DESC=$(get_dynamic_description "notification")
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
log_info "📋 Dynamic permissions summary:"
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

# Show dynamic configuration summary
log_info "📋 Dynamic Configuration Summary:"
echo "=========================================="
echo "✅ App Name: ${APP_NAME:-QuikApp}"
echo "✅ Organization: ${ORG_NAME:-QuikApp}"
echo "✅ Chat Bot Enabled: ${IS_CHATBOT:-false}"
echo "✅ Camera Enabled: ${IS_CAMERA:-false}"
echo "✅ Location Enabled: ${IS_LOCATION:-false}"
echo "✅ Contacts Enabled: ${IS_CONTACT:-false}"
echo "✅ Calendar Enabled: ${IS_CALENDAR:-false}"
echo "✅ Biometric Enabled: ${IS_BIOMETRIC:-false}"
echo "✅ Storage Enabled: ${IS_STORAGE:-false}"
echo "✅ Notifications Enabled: ${IS_NOTIFICATION:-false}"
echo "=========================================="

# Show permission descriptions
log_info "📝 Permission Descriptions:"
echo "=========================================="
if [[ "${IS_CHATBOT:-false}" == "true" ]]; then
    echo "🎤 Speech Recognition: $SPEECH_DESC"
    echo "🎤 Microphone: $MIC_DESC"
else
    echo "🎤 Speech Recognition: $SPEECH_DESC"
    echo "🎤 Microphone: $MIC_DESC"
fi

if [[ "${IS_CAMERA:-false}" == "true" ]]; then
    echo "📷 Camera: $CAMERA_DESC"
fi

if [[ "${IS_LOCATION:-false}" == "true" ]]; then
    echo "📍 Location: $LOCATION_DESC"
fi

if [[ "${IS_CONTACT:-false}" == "true" ]]; then
    echo "👥 Contacts: $CONTACTS_DESC"
fi

if [[ "${IS_CALENDAR:-false}" == "true" ]]; then
    echo "📅 Calendar: $CALENDAR_DESC"
fi

if [[ "${IS_BIOMETRIC:-false}" == "true" ]]; then
    echo "🔐 Biometric: $BIOMETRIC_DESC"
fi

if [[ "${IS_STORAGE:-false}" == "true" ]]; then
    echo "💾 Storage: $STORAGE_DESC"
fi

echo "=========================================="

log_success "🎉 Dynamic iOS permissions fix completed successfully" 