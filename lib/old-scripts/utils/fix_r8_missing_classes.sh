#!/bin/bash
# 🔧 Fix R8 Missing Classes Issues
# Automatically handles missing classes detected by R8 during AAB builds
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

fix_r8_missing_classes() {
    log "🔧 Fixing R8 missing classes issues..."
    
    local missing_rules_file="build/app/outputs/mapping/release/missing_rules.txt"
    local proguard_file="android/app/proguard-rules.pro"
    
    # Check if missing rules file exists
    if [ -f "$missing_rules_file" ]; then
        log "📋 Found missing rules file: $missing_rules_file"
        
        # Backup current ProGuard rules
        if [ -f "$proguard_file" ]; then
            cp "$proguard_file" "${proguard_file}.backup.$(date +%Y%m%d_%H%M%S)"
            log "📋 Backed up existing ProGuard rules"
        fi
        
        # Append missing rules to ProGuard file
        log "🔧 Appending missing rules to ProGuard configuration..."
        echo "" >> "$proguard_file"
        echo "# R8 Missing Classes Rules (Auto-generated)" >> "$proguard_file"
        echo "# Generated on: $(date)" >> "$proguard_file"
        cat "$missing_rules_file" >> "$proguard_file"
        
        log "✅ Added $(wc -l < "$missing_rules_file") missing rules to ProGuard configuration"
        
        # Clean up missing rules file
        rm "$missing_rules_file"
        log "🧹 Cleaned up missing rules file"
    else
        log "ℹ️ No missing rules file found, R8 build should succeed"
    fi
}

add_comprehensive_proguard_rules() {
    log "🔧 Adding comprehensive ProGuard rules to prevent missing classes..."
    
    local proguard_file="android/app/proguard-rules.pro"
    
    # Add comprehensive rules if they don't exist
    if ! grep -q "R8 Missing Classes Prevention" "$proguard_file"; then
        cat >> "$proguard_file" << 'EOF'

# R8 Missing Classes Prevention (Comprehensive)
# These rules prevent the most common missing classes issues

# Keep all Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }

# Keep specific Google Play Core classes that were missing in the build
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallException { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManager { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManagerFactory { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest$Builder { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallSessionState { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }
-keep class com.google.android.play.core.tasks.OnFailureListener { *; }
-keep class com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class com.google.android.play.core.tasks.Task { *; }

# Keep all Flutter embedding classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.engine.renderer.** { *; }
-keep class io.flutter.embedding.engine.platform.** { *; }

# Keep all Android support classes
-keep class androidx.** { *; }
-keep class android.support.** { *; }
-keep class android.** { *; }

# Keep all Google services
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep all custom app classes
-keep class co.pixaware.pixaware.** { *; }

# Keep all serialization classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep all Serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.InputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all R classes
-keep class **.R$* {
    public static <fields>;
}

# Keep all manifest components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View
-keep public class * extends android.app.Fragment

# Keep all WebView interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep all custom fonts
-keep class androidx.core.content.res.FontResourcesParserCompat { *; }

# Keep all notification classes
-keep class androidx.core.app.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# Keep all OAuth classes
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep all connectivity classes
-keep class co.pixaware.pixaware.connectivity.** { *; }

# Keep all utility classes
-keep class co.pixaware.pixaware.utils.** { *; }

# Keep all module classes
-keep class co.pixaware.pixaware.module.** { *; }

# Keep all service classes
-keep class co.pixaware.pixaware.services.** { *; }

# Keep all chat classes
-keep class co.pixaware.pixaware.chat.** { *; }

# Keep all notification handlers
-keep class co.pixaware.pixaware.notification.** { *; }

# Keep all OAuth related classes
-keep class co.pixaware.pixaware.oauth.** { *; }

# Keep main activity and app classes
-keep class co.pixaware.pixaware.MainActivity { *; }
-keep class co.pixaware.pixaware.MyApp { *; }
-keep class co.pixaware.pixaware.FirebaseMessagingService { *; }

# Keep all configuration classes
-keep class co.pixaware.pixaware.config.** { *; }
-keep class co.pixaware.pixaware.config.EnvConfig { *; }

# Keep all custom icons and assets
-keep class co.pixaware.pixaware.** { *; }

# Keep all bottom menu items
-keep class co.pixaware.pixaware.chat.** { *; }

# Keep all chat and assistant services
-keep class co.pixaware.pixaware.chat.** { *; }
-keep class co.pixaware.pixaware.services.** { *; }

# Keep all utility classes
-keep class co.pixaware.pixaware.utils.** { *; }

# Keep all module classes
-keep class co.pixaware.pixaware.module.** { *; }

# Keep all main activity
-keep class co.pixaware.pixaware.MainActivity { *; }
-keep class co.pixaware.pixaware.MyApp { *; }

# Keep all other custom classes
-keep class co.pixaware.pixaware.** { *; }

# Keep all Firebase messaging service
-keep class co.pixaware.pixaware.FirebaseMessagingService { *; }

# Keep all notification handlers
-keep class co.pixaware.pixaware.notification.** { *; }

# Keep all OAuth related classes
-keep class co.pixaware.pixaware.oauth.** { *; }

# Keep all connectivity and network classes
-keep class co.pixaware.pixaware.connectivity.** { *; }

# Keep specific missing classes that R8 needs for AAB builds
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }

# Additional rules to prevent R8 missing classes errors
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }

# Keep all Flutter embedding classes to prevent missing references
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.engine.renderer.** { *; }
-keep class io.flutter.embedding.engine.platform.** { *; }

# Keep all Android support and androidx classes
-keep class androidx.** { *; }
-keep class android.support.** { *; }
-keep class android.** { *; }
EOF
        
        log "✅ Added comprehensive ProGuard rules to prevent missing classes"
    else
        log "ℹ️ Comprehensive ProGuard rules already exist"
    fi
}

main() {
    log "🚀 Starting R8 missing classes fix..."
    
    # Check if we're in the right directory
    if [ ! -d "android/app" ]; then
        log "❌ android/app directory not found"
        exit 1
    fi
    
    # Fix missing classes
    fix_r8_missing_classes
    
    # Add comprehensive rules
    add_comprehensive_proguard_rules
    
    log "✅ R8 missing classes fix completed successfully!"
}

main "$@"
