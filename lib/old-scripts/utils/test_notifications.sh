#!/bin/bash
# 🔔 Test Push Notifications
# Tests notification functionality after fixes

set -eo pipefail

# Logging function
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

log "🧪 Testing push notification functionality..."

# Test Android manifest
test_android_manifest() {
    log "🤖 Testing Android manifest..."
    
    local manifest_file="android/app/src/main/AndroidManifest.xml"
    
    if [ ! -f "$manifest_file" ]; then
        log "❌ AndroidManifest.xml not found"
        return 1
    fi
    
    # Check for required permissions
    local required_permissions=(
        "android.permission.POST_NOTIFICATIONS"
        "android.permission.VIBRATE"
        "android.permission.WAKE_LOCK"
        "android.permission.RECEIVE_BOOT_COMPLETED"
        "android.permission.INTERNET"
        "android.permission.ACCESS_NETWORK_STATE"
    )
    
    for permission in "${required_permissions[@]}"; do
        if grep -q "$permission" "$manifest_file"; then
            log "✅ $permission found"
        else
            log "❌ $permission missing"
            return 1
        fi
    done
    
    # Check for Firebase messaging service
    if grep -q "com.google.firebase.messaging.FirebaseMessagingService" "$manifest_file"; then
        log "✅ Firebase messaging service found"
    else
        log "❌ Firebase messaging service missing"
        return 1
    fi
    
    # Check for default notification icon
    if grep -q "com.google.firebase.messaging.default_notification_icon" "$manifest_file"; then
        log "✅ Default notification icon found"
    else
        log "❌ Default notification icon missing"
        return 1
    fi
    
    log "✅ Android manifest test passed"
}

# Test iOS Info.plist
test_ios_plist() {
    log "🍎 Testing iOS Info.plist..."
    
    local plist_file="ios/Runner/Info.plist"
    
    if [ ! -f "$plist_file" ]; then
        log "❌ Info.plist not found"
        return 1
    fi
    
    # Check for notification permissions
    if grep -q "NSUserNotificationUsageDescription" "$plist_file"; then
        log "✅ Notification usage description found"
    else
        log "❌ Notification usage description missing"
        return 1
    fi
    
    # Check for background modes
    if grep -q "UIBackgroundModes" "$plist_file"; then
        log "✅ Background modes found"
    else
        log "❌ Background modes missing"
        return 1
    fi
    
    # Check for notification categories
    if grep -q "UNNotificationCategory" "$plist_file"; then
        log "✅ Notification categories found"
    else
        log "❌ Notification categories missing"
        return 1
    fi
    
    log "✅ iOS Info.plist test passed"
}

# Test Firebase configuration
test_firebase_config() {
    log "🔥 Testing Firebase configuration..."
    
    # Check Firebase service
    local firebase_service="lib/services/firebase_service.dart"
    
    if [ -f "$firebase_service" ]; then
        if grep -q "loadFirebaseOptionsFromJson" "$firebase_service"; then
            log "✅ Firebase service configuration found"
        else
            log "❌ Firebase service configuration missing"
            return 1
        fi
    else
        log "❌ Firebase service file not found"
        return 1
    fi
    
    # Check notification service
    local notification_service="lib/services/notification_service.dart"
    
    if [ -f "$notification_service" ]; then
        if grep -q "initLocalNotifications" "$notification_service"; then
            log "✅ Notification service configuration found"
        else
            log "❌ Notification service configuration missing"
            return 1
        fi
    else
        log "❌ Notification service file not found"
        return 1
    fi
    
    log "✅ Firebase configuration test passed"
}

# Test notification initialization
test_notification_initialization() {
    log "🔧 Testing notification initialization..."
    
    local main_file="lib/main.dart"
    
    if [ ! -f "$main_file" ]; then
        log "❌ main.dart not found"
        return 1
    fi
    
    # Check for local notifications initialization
    if grep -q "initLocalNotifications" "$main_file"; then
        log "✅ Local notifications initialization found"
    else
        log "❌ Local notifications initialization missing"
        return 1
    fi
    
    # Check for Firebase messaging initialization
    if grep -q "initializeFirebaseMessaging" "$main_file"; then
        log "✅ Firebase messaging initialization found"
    else
        log "❌ Firebase messaging initialization missing"
        return 1
    fi
    
    log "✅ Notification initialization test passed"
}

# Main execution
main() {
    log "🚀 Starting notification functionality tests..."
    
    local all_tests_passed=true
    
    # Test Android manifest
    if ! test_android_manifest; then
        all_tests_passed=false
        log "❌ Android manifest test failed"
    fi
    
    # Test iOS Info.plist
    if ! test_ios_plist; then
        all_tests_passed=false
        log "❌ iOS Info.plist test failed"
    fi
    
    # Test Firebase configuration
    if ! test_firebase_config; then
        all_tests_passed=false
        log "❌ Firebase configuration test failed"
    fi
    
    # Test notification initialization
    if ! test_notification_initialization; then
        all_tests_passed=false
        log "❌ Notification initialization test failed"
    fi
    
    if [ "$all_tests_passed" = true ]; then
        log "🎉 All notification tests passed! Push notifications should work correctly."
    else
        log "❌ Some notification tests failed. Please run fix_notifications.sh first."
        exit 1
    fi
}

# Run main function
main "$@"
