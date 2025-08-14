#!/bin/bash
# 🔧 Fix Google Play Core Missing Classes
# Specifically addresses the R8 missing classes issue for AAB builds
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

fix_google_play_core_classes() {
    log "🔧 Fixing Google Play Core missing classes issue..."
    
    local proguard_file="android/app/proguard-rules.pro"
    
    if [ ! -f "$proguard_file" ]; then
        log "❌ ProGuard rules file not found: $proguard_file"
        log "🔧 Regenerating ProGuard rules..."
        if [ -f "lib/scripts/utils/generate_proguard_rules.sh" ]; then
            chmod +x lib/scripts/utils/generate_proguard_rules.sh
            lib/scripts/utils/generate_proguard_rules.sh
        else
            log "❌ ProGuard rules generation script not found"
            return 1
        fi
    fi
    
    # Backup current ProGuard rules
    cp "$proguard_file" "${proguard_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up existing ProGuard rules"
    
    # Add comprehensive Google Play Core rules
    log "🔧 Adding comprehensive Google Play Core ProGuard rules..."
    
    cat >> "$proguard_file" << 'EOF'

# ============================================================================
# GOOGLE PLAY CORE COMPREHENSIVE RULES (FIX FOR R8 MISSING CLASSES)
# ============================================================================
# These rules specifically address the missing classes detected in the build

# Keep ALL Google Play Core classes and their subclasses
-keep class com.google.android.play.core.** { *; }

# Keep specific Google Play Core modules
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }

# Keep specific classes that were missing in the build error
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

# Keep all Flutter embedding classes that use Google Play Core
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }

# Keep all Android support classes that might be needed
-keep class androidx.** { *; }
-keep class android.support.** { *; }
-keep class android.** { *; }

# Keep all Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep all custom app classes
-keep class co.pixaware.pixaware.** { *; }

# Keep all serialization and annotation classes
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

# Keep all Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep all Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
}

# Keep all annotation attributes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Keep all public classes that extend Exception
-keep public class * extends java.lang.Exception

# Keep all classes in the app package
-keep class co.pixaware.pixaware.** { *; }

# ============================================================================
# END GOOGLE PLAY CORE COMPREHENSIVE RULES
# ============================================================================
EOF

    log "✅ Added comprehensive Google Play Core ProGuard rules"
    
    # Verify the rules were added
    if grep -q "GOOGLE PLAY CORE COMPREHENSIVE RULES" "$proguard_file"; then
        log "✅ Google Play Core rules successfully added to ProGuard configuration"
        log "📋 Total ProGuard rules file size: $(wc -l < "$proguard_file") lines"
    else
        log "❌ Failed to add Google Play Core rules"
        return 1
    fi
}

main() {
    log "🚀 Starting Google Play Core missing classes fix..."
    fix_google_play_core_classes
    log "🎉 Google Play Core missing classes fix completed successfully!"
}

main "$@"
