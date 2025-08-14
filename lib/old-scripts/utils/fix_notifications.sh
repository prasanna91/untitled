#!/bin/bash
# 🔔 Fix Push Notifications for Android & iOS
# Dynamically injects notification permissions and configurations

set -eo pipefail

# Logging function
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

# Cross-platform sed function
cross_platform_sed() {
    local search="$1"
    local replace="$2"
    local file="$3"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$search|$replace|g" "$file"
    else
        sed -i "s|$search|$replace|g" "$file"
    fi
}

log "🔔 Starting push notification fixes..."

# Fix Android Manifest
fix_android_notifications() {
    log "🤖 Fixing Android notification permissions..."
    
    local manifest_file="android/app/src/main/AndroidManifest.xml"
    
    if [ ! -f "$manifest_file" ]; then
        log "❌ AndroidManifest.xml not found"
        return 1
    fi
    
    # Backup original manifest
    cp "$manifest_file" "${manifest_file}.backup"
    
    # Add notification permissions before </manifest>
    if ! grep -q "android.permission.POST_NOTIFICATIONS" "$manifest_file"; then
        log "➕ Adding POST_NOTIFICATIONS permission..."
        cross_platform_sed '</manifest>' '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <uses-permission android:name="android.permission.VIBRATE" />\n    <uses-permission android:name="android.permission.WAKE_LOCK" />\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n    <uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\n</manifest>' "$manifest_file"
    fi
    
    # Add Firebase messaging service
    if ! grep -q "com.google.firebase.messaging" "$manifest_file"; then
        log "➕ Adding Firebase messaging service..."
        cross_platform_sed '        <meta-data' '        <service\n            android:name="com.google.firebase.messaging.FirebaseMessagingService"\n            android:exported="false">\n            <intent-filter>\n                <action android:name="com.google.firebase.MESSAGING_EVENT" />\n            </intent-filter>\n        </service>\n        <meta-data' "$manifest_file"
    fi
    
    # Add default notification icon
    if ! grep -q "com.google.firebase.messaging.default_notification_icon" "$manifest_file"; then
        log "➕ Adding default notification icon..."
        cross_platform_sed '        <meta-data' '        <meta-data\n            android:name="com.google.firebase.messaging.default_notification_icon"\n            android:resource="@mipmap/ic_launcher" />\n        <meta-data' "$manifest_file"
    fi
    
    log "✅ Android notification permissions fixed"
}

# Fix iOS Info.plist
fix_ios_notifications() {
    log "🍎 Fixing iOS notification permissions..."
    
    local plist_file="ios/Runner/Info.plist"
    
    if [ ! -f "$plist_file" ]; then
        log "❌ Info.plist not found"
        return 1
    fi
    
    # Backup original plist
    cp "$plist_file" "${plist_file}.backup"
    
    # Add notification permissions
    if ! grep -q "NSUserNotificationUsageDescription" "$plist_file"; then
        log "➕ Adding notification usage description..."
        cross_platform_sed '    <key>UIApplicationSupportsIndirectInputEvents</key>' '    <key>NSUserNotificationUsageDescription</key>\n    <string>This app uses notifications to keep you updated with important information.</string>\n    <key>UIApplicationSupportsIndirectInputEvents</key>' "$plist_file"
    fi
    
    # Add background modes for notifications
    if ! grep -q "UIBackgroundModes" "$plist_file"; then
        log "➕ Adding background modes for notifications..."
        cross_platform_sed '    <key>UIApplicationSupportsIndirectInputEvents</key>' '    <key>UIBackgroundModes</key>\n    <array>\n        <string>remote-notification</string>\n        <string>background-processing</string>\n    </array>\n    <key>UIApplicationSupportsIndirectInputEvents</key>' "$plist_file"
    fi
    
    # Add notification categories
    if ! grep -q "UNNotificationCategory" "$plist_file"; then
        log "➕ Adding notification categories..."
        cross_platform_sed '    <key>UIApplicationSupportsIndirectInputEvents</key>' '    <key>UNNotificationCategory</key>\n    <array>\n        <dict>\n            <key>identifier</key>\n            <string>message</string>\n            <key>actions</key>\n            <array>\n                <dict>\n                    <key>identifier</key>\n                    <string>reply</string>\n                    <key>title</key>\n                    <string>Reply</string>\n                    <key>options</key>\n                    <array>\n                        <string>foreground</string>\n                    </array>\n                </dict>\n            </array>\n        </dict>\n    </array>\n    <key>UIApplicationSupportsIndirectInputEvents</key>' "$plist_file"
    fi
    
    log "✅ iOS notification permissions fixed"
}

# Fix Firebase configuration
fix_firebase_config() {
    log "🔥 Fixing Firebase configuration..."
    
    # Ensure Firebase service is properly configured
    local firebase_service="lib/services/firebase_service.dart"
    
    if [ -f "$firebase_service" ]; then
        # Check if Firebase options are properly loaded
        if ! grep -q "loadFirebaseOptionsFromJson" "$firebase_service"; then
            log "❌ Firebase service not properly configured"
            return 1
        fi
        log "✅ Firebase service configuration verified"
    else
        log "❌ Firebase service file not found"
        return 1
    fi
    
    # Ensure notification service is properly configured
    local notification_service="lib/services/notification_service.dart"
    
    if [ -f "$notification_service" ]; then
        # Check if notification initialization is properly configured
        if ! grep -q "initLocalNotifications" "$notification_service"; then
            log "❌ Notification service not properly configured"
            return 1
        fi
        log "✅ Notification service configuration verified"
    else
        log "❌ Notification service file not found"
        return 1
    fi
}

# Fix notification initialization in main.dart
fix_notification_initialization() {
    log "🔧 Fixing notification initialization in main.dart..."
    
    local main_file="lib/main.dart"
    
    if [ ! -f "$main_file" ]; then
        log "❌ main.dart not found"
        return 1
    fi
    
    # Ensure local notifications are initialized
    if ! grep -q "initLocalNotifications" "$main_file"; then
        log "❌ Local notifications not initialized in main.dart"
        return 1
    fi
    
    # Ensure Firebase messaging is properly initialized
    if ! grep -q "initializeFirebaseMessaging" "$main_file"; then
        log "❌ Firebase messaging not initialized in main.dart"
        return 1
    fi
    
    log "✅ Notification initialization verified in main.dart"
}

# Main execution
main() {
    log "🚀 Starting comprehensive notification fixes..."
    
    # Fix Android notifications
    if [[ "$OSTYPE" == "android"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
        fix_android_notifications
    fi
    
    # Fix iOS notifications
    if [[ "$OSTYPE" == "darwin"* ]]; then
        fix_ios_notifications
    fi
    
    # Fix Firebase configuration
    fix_firebase_config
    
    # Fix notification initialization
    fix_notification_initialization
    
    log "✅ All notification fixes completed successfully!"
}

# Run main function
main "$@"
