#!/bin/bash
# 🔐 iOS Permissions Script
# Dynamically configures iOS permissions in Info.plist based on environment variables

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

# Function to safely get environment variable with fallback
get_env_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        printf "%s" "$value"
    else
        printf "%s" "$fallback"
    fi
}

# Function to add or update Info.plist key
update_info_plist() {
    local key="$1"
    local value="$2"
    local plist_path="ios/Runner/Info.plist"
    
    if /usr/libexec/PlistBuddy -c "Print :$key" "$plist_path" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Set :$key '$value'" "$plist_path"
        log_success "Updated $key in Info.plist"
    else
        /usr/libexec/PlistBuddy -c "Add :$key string '$value'" "$plist_path"
        log_success "Added $key to Info.plist"
    fi
}

log_info "Starting iOS permissions configuration..."

# Get permission flags from environment
IS_CAMERA=$(get_env_var "IS_CAMERA" "false")
IS_LOCATION=$(get_env_var "IS_LOCATION" "false")
IS_MIC=$(get_env_var "IS_MIC" "false")
IS_NOTIFICATION=$(get_env_var "IS_NOTIFICATION" "false")
IS_CONTACT=$(get_env_var "IS_CONTACT" "false")
IS_BIOMETRIC=$(get_env_var "IS_BIOMETRIC" "false")
IS_CALENDAR=$(get_env_var "IS_CALENDAR" "false")
IS_STORAGE=$(get_env_var "IS_STORAGE" "false")
IS_CHATBOT=$(get_env_var "IS_CHATBOT" "false")

# Get app name for permission descriptions
APP_NAME=$(get_env_var "APP_NAME" "QuikApp")

log_info "Permission flags:"
log_info "  Camera: $IS_CAMERA"
log_info "  Location: $IS_LOCATION"
log_info "  Microphone: $IS_MIC"
log_info "  Notifications: $IS_NOTIFICATION"
log_info "  Contacts: $IS_CONTACT"
log_info "  Biometric: $IS_BIOMETRIC"
log_info "  Calendar: $IS_CALENDAR"
log_info "  Storage: $IS_STORAGE"
log_info "  Chat Bot: $IS_CHATBOT"

# Always add network security settings for Flutter apps
log_info "Adding network security settings..."
update_info_plist "NSAppTransportSecurity" "NSAppTransportSecurity"
update_info_plist "NSAppTransportSecurity:NSAllowsArbitraryLoads" "true"

# Camera Permission
if [[ "$IS_CAMERA" == "true" ]]; then
    log_info "Adding camera permission..."
    update_info_plist "NSCameraUsageDescription" "$APP_NAME needs access to your camera to take photos and videos."
fi

# Location Permissions
if [[ "$IS_LOCATION" == "true" ]]; then
    log_info "Adding location permissions..."
    update_info_plist "NSLocationWhenInUseUsageDescription" "$APP_NAME needs access to your location to provide location-based services."
    update_info_plist "NSLocationAlwaysAndWhenInUseUsageDescription" "$APP_NAME needs access to your location to provide location-based services."
    update_info_plist "NSLocationAlwaysUsageDescription" "$APP_NAME needs access to your location to provide location-based services."
fi

# Microphone Permission
if [[ "$IS_MIC" == "true" ]]; then
    log_info "Adding microphone permission..."
    update_info_plist "NSMicrophoneUsageDescription" "$APP_NAME needs access to your microphone for voice recording and communication."
fi

# Speech Recognition Permission (for Chat Bot)
if [[ "$IS_CHATBOT" == "true" ]]; then
    log_info "Adding speech recognition permission for chat bot..."
    update_info_plist "NSSpeechRecognitionUsageDescription" "$APP_NAME needs access to speech recognition to convert your voice to text for the chat bot feature."
fi

# Contacts Permission
if [[ "$IS_CONTACT" == "true" ]]; then
    log_info "Adding contacts permission..."
    update_info_plist "NSContactsUsageDescription" "$APP_NAME needs access to your contacts to help you connect with friends and family."
fi

# Face ID Permission
if [[ "$IS_BIOMETRIC" == "true" ]]; then
    log_info "Adding Face ID permission..."
    update_info_plist "NSFaceIDUsageDescription" "$APP_NAME uses Face ID to securely authenticate you and protect your personal information."
fi

# Calendar Permission
if [[ "$IS_CALENDAR" == "true" ]]; then
    log_info "Adding calendar permission..."
    update_info_plist "NSCalendarsUsageDescription" "$APP_NAME needs access to your calendar to help you manage your schedule and events."
fi

# Photo Library Permissions
if [[ "$IS_STORAGE" == "true" ]]; then
    log_info "Adding photo library permissions..."
    update_info_plist "NSPhotoLibraryUsageDescription" "$APP_NAME needs access to your photo library to save and share images."
    update_info_plist "NSPhotoLibraryAddUsageDescription" "$APP_NAME needs access to your photo library to save images and videos."
fi

# Notification Permission (always add for push notifications)
if [[ "$IS_NOTIFICATION" == "true" ]]; then
    log_info "Adding notification permission..."
    # Note: iOS automatically requests notification permission, no Info.plist key needed
    log_info "Notification permission will be requested at runtime"
fi

# Add required background modes if needed
if [[ "$IS_LOCATION" == "true" ]]; then
    log_info "Adding background location mode..."
    # Add background modes array if it doesn't exist
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "ios/Runner/Info.plist"
    fi
    
    # Add location background mode
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string location" "ios/Runner/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :UIBackgroundModes:0 location" "ios/Runner/Info.plist"
fi

# Add audio background mode for microphone/chat bot
if [[ "$IS_MIC" == "true" ]] || [[ "$IS_CHATBOT" == "true" ]]; then
    log_info "Adding audio background mode..."
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "ios/Runner/Info.plist"
    fi
    
    # Add audio background mode
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:1 string audio" "ios/Runner/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :UIBackgroundModes:1 audio" "ios/Runner/Info.plist"
fi

# Add required device capabilities
log_info "Adding required device capabilities..."

# Add device capabilities array if it doesn't exist
if ! /usr/libexec/PlistBuddy -c "Print :UIRequiredDeviceCapabilities" "ios/Runner/Info.plist" 2>/dev/null; then
    /usr/libexec/PlistBuddy -c "Add :UIRequiredDeviceCapabilities array" "ios/Runner/Info.plist"
fi

# Add required capabilities
capabilities=("armv7")

if [[ "$IS_BIOMETRIC" == "true" ]]; then
    capabilities+=("faceid")
fi

# Add capabilities to Info.plist
for i in "${!capabilities[@]}"; do
    capability="${capabilities[$i]}"
    /usr/libexec/PlistBuddy -c "Add :UIRequiredDeviceCapabilities:$i string $capability" "ios/Runner/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :UIRequiredDeviceCapabilities:$i $capability" "ios/Runner/Info.plist"
done

# Verify Info.plist is valid
log_info "Verifying Info.plist configuration..."
if /usr/libexec/PlistBuddy -c "Print" "ios/Runner/Info.plist" >/dev/null 2>&1; then
    log_success "Info.plist is valid"
else
    log_error "Info.plist is invalid"
    exit 1
fi

# Display final configuration
log_info "Final Info.plist configuration:"
/usr/libexec/PlistBuddy -c "Print" "ios/Runner/Info.plist" | grep -E "(UsageDescription|UIBackgroundModes|UIRequiredDeviceCapabilities)" || true

log_success "iOS permissions configuration completed successfully" 