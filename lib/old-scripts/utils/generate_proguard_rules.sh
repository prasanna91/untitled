#!/bin/bash
# 🔧 Generate Dynamic ProGuard Rules
# Creates ProGuard rules with correct package names from environment

set -eo pipefail

# Logging function
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

log "🔧 Generating dynamic ProGuard rules..."

# Get package name from environment
package_name="${PKG_NAME:-co.pixaware.pixaware}"
if [ -z "$package_name" ]; then
    log "⚠️ PKG_NAME not set, using default: co.pixaware.pixaware"
    package_name="co.pixaware.pixaware"
fi

log "📦 Using package name: $package_name"

# Extract package parts for ProGuard rules
IFS='.' read -ra package_parts <<< "$package_name"
package_base="${package_parts[0]}.${package_parts[1]}"

log "🔍 Package base: $package_base"

# ProGuard rules template
generate_proguard_rules() {
    cat > "android/app/proguard-rules.pro" << EOF
# ProGuard rules to prevent APK crashes
# Generated dynamically for package: $package_name

# Keep all Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Flutter embedding and engine classes (ESSENTIAL for AAB)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Keep environment configuration
-keep class $package_name.config.** { *; }
-keep class $package_name.config.EnvConfig { *; }

# Keep JSON models and serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep OAuth and authentication
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep Google Play Core classes (ESSENTIAL for AAB builds)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }

# Keep specific Google Play Core classes that are commonly missing
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.Task { *; }
-keep class com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class com.google.android.play.core.tasks.OnFailureListener { *; }

# Keep notification classes
-keep class androidx.core.app.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# Keep custom icons and assets
-keep class $package_name.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable\$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R\$* {
    public static <fields>;
}

# Keep manifest components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View
-keep public class * extends android.app.Fragment

# Keep WebView
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep custom fonts
-keep class androidx.core.content.res.FontResourcesParserCompat { *; }

# Keep bottom menu items
-keep class $package_name.chat.** { *; }

# Keep chat and assistant services
-keep class $package_name.chat.** { *; }
-keep class $package_name.services.** { *; }

# Keep utility classes
-keep class $package_name.utils.** { *; }

# Keep module classes
-keep class $package_name.module.** { *; }

# Keep main activity
-keep class $package_name.MainActivity { *; }
-keep class $package_name.MyApp { *; }

# Keep any other custom classes
-keep class $package_name.** { *; }

# Keep Firebase messaging service
-keep class $package_name.FirebaseMessagingService { *; }

# Keep notification handlers
-keep class $package_name.notification.** { *; }

# Keep OAuth related classes
-keep class $package_name.oauth.** { *; }

# Keep connectivity and network classes
-keep class $package_name.connectivity.** { *; }

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

# AAB-specific optimizations to prevent missing classes
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Keep all split-related classes for AAB
-keep class * implements android.content.pm.split.SplitCompatApplication { *; }
-keep class * extends android.content.pm.split.SplitCompatApplication { *; }
EOF
}

# Main execution
main() {
    log "🚀 Starting dynamic ProGuard rules generation..."
    
    # Check if android/app directory exists
    if [ ! -d "android/app" ]; then
        log "❌ android/app directory not found"
        exit 1
    fi
    
    # Backup existing ProGuard rules if they exist
    if [ -f "android/app/proguard-rules.pro" ]; then
        log "📋 Backing up existing ProGuard rules..."
        cp "android/app/proguard-rules.pro" "android/app/proguard-rules.pro.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Generate new ProGuard rules
    log "🔧 Generating ProGuard rules for package: $package_name"
    generate_proguard_rules
    
    # Validate generated rules
    if [ -f "android/app/proguard-rules.pro" ]; then
        log "✅ ProGuard rules generated successfully"
        log "📋 File size: $(wc -c < "android/app/proguard-rules.pro") bytes"
        log "📋 File lines: $(wc -l < "android/app/proguard-rules.pro")"
        
        # Show key rules
        log "🔑 Key ProGuard rules generated:"
        grep -E "^-keep class|^-keepclassmembers" "android/app/proguard-rules.pro" | head -10
        
        # Verify package name is correct
        if grep -q "$package_name" "android/app/proguard-rules.pro"; then
            log "✅ Package name $package_name correctly applied to ProGuard rules"
        else
            log "❌ Package name not found in generated ProGuard rules"
            exit 1
        fi
    else
        log "❌ Failed to generate ProGuard rules"
        exit 1
    fi
    
    log "🎉 Dynamic ProGuard rules generation completed successfully!"
}

# Run main function
main "$@"
