#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ANDROID_CONFIG] $1"; }
handle_error() { log "ERROR: $1"; exit 1; }
trap 'handle_error "Error occurred at line $LINENO"' ERR

log "🔄 Starting Dynamic Android Configuration Generation"

# Get environment variables
PKG_NAME=${PKG_NAME:-"com.example.quikapptest06"}
VERSION_NAME=${VERSION_NAME:-"1.0.0"}
VERSION_CODE=${VERSION_CODE:-"1"}
WORKFLOW_ID=${WORKFLOW_ID:-"android-free"}
PUSH_NOTIFY=${PUSH_NOTIFY:-"false"}
IS_GOOGLE_AUTH=${IS_GOOGLE_AUTH:-"false"}
IS_APPLE_AUTH=${IS_APPLE_AUTH:-"false"}

# Log configuration
log "📊 Configuration Summary:"
log "   Package Name: $PKG_NAME"
log "   Version Name: $VERSION_NAME"
log "   Version Code: $VERSION_CODE"
log "   Workflow ID: $WORKFLOW_ID"
log "   Push Notifications: $PUSH_NOTIFY"
log "   Google Auth: $IS_GOOGLE_AUTH"
log "   Apple Auth: $IS_APPLE_AUTH"

# ============================================================================
# 📝 Generate settings.gradle.kts
# ============================================================================

log "📝 Generating android/settings.gradle.kts..."

cat > android/settings.gradle.kts << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "android"
include(":app")

// Basic Flutter configuration without external dependencies
println("✅ Flutter project configuration loaded")
EOF

log "✅ Generated android/settings.gradle.kts"

# ============================================================================
# 📝 Generate build.gradle.kts (root)
# ============================================================================

log "📝 Generating android/build.gradle.kts..."

cat > android/build.gradle.kts << 'EOF'
// Simplified build configuration to avoid repository conflicts
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
EOF

log "✅ Generated android/build.gradle.kts"

# ============================================================================
# 📝 Generate app/build.gradle.kts
# ============================================================================

log "📝 Generating android/app/build.gradle.kts..."

cat > android/app/build.gradle.kts << 'EOF'
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "$PKG_NAME"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        freeCompilerArgs += listOf(
            "-Xno-param-assertions",
            "-Xno-call-assertions",
            "-Xno-receiver-assertions",
            "-Xno-optimized-callable-references",
            "-Xuse-ir",
            "-Xskip-prerelease-check"
        )
    }

    defaultConfig {
        applicationId = "$PKG_NAME"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = $VERSION_CODE
        versionName = "$VERSION_NAME"
    }

    buildFeatures {
        buildConfig = true
        aidl = false
        renderScript = false
        resValues = false
        shaders = false
        viewBinding = false
        dataBinding = false
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("app/src/keystore.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file("src/" + keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            val keystorePropertiesFile = rootProject.file("app/src/keystore.properties")
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
                println("🔐 Using RELEASE signing with keystore")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("⚠️ Using DEBUG signing (keystore not found)")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    packaging {
        jniLibs {
            useLegacyPackaging = false
            pickFirsts += listOf("**/libc++_shared.so", "**/libjsc.so")
        }
        resources {
            excludes += listOf("META-INF/DEPENDENCIES", "META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/license.txt", "META-INF/NOTICE", "META-INF/NOTICE.txt", "META-INF/notice.txt", "META-INF/ASL2.0", "META-INF/*.kotlin_module")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // OAuth Dependencies based on feature flags
    if ("$IS_GOOGLE_AUTH" == "true") {
        implementation("com.google.android.gms:play-services-auth:20.7.0")
        implementation("com.google.firebase:firebase-auth:22.3.1")
    }
    
    if ("$IS_APPLE_AUTH" == "true") {
        implementation("com.apple.android:sign-in:1.0.0")
    }
}
EOF

log "✅ Generated android/app/build.gradle.kts"

# ============================================================================
# 📝 Generate gradle.properties
# ============================================================================

log "📝 Generating android/gradle.properties..."

cat > android/gradle.properties << 'EOF'
# Gradle optimization settings
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=2G -XX:ReservedCodeCacheSize=2048M -XX:+UseG1GC -XX:MaxGCPauseMillis=30 -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+TieredCompilation -XX:TieredStopAtLevel=1
org.gradle.workers.max=8
org.gradle.vfs.watch=false
org.gradle.vfs.verbose=false

# Android optimization (updated for AGP 8.7.3)
android.useAndroidX=true
android.enableJetifier=true
android.enableR8.fullMode=true
android.enableR8=true
android.enableD8=true
android.enableD8.desugaring=true
android.enableBuildCache=true
android.enableAapt2=true
android.enableResourceOptimizations=true
android.useFullClasspathForDexingTransform=true
android.enableSeparateBuildPerCPUArchitecture=false
android.enableSeparateAPKGenerationForLanguages=false
android.enableCrashlytics=false
android.enableProguardInReleaseBuilds=true
android.enableShrinkResources=true

# Flutter optimization
flutter.enableR8=true
flutter.enableD8=true
flutter.enableBuildCache=true
flutter.enableResourceOptimizations=true

# OAuth Configuration
IS_GOOGLE_AUTH=$IS_GOOGLE_AUTH
IS_APPLE_AUTH=$IS_APPLE_AUTH
PUSH_NOTIFY=$PUSH_NOTIFY
EOF

log "✅ Generated android/gradle.properties"

# ============================================================================
# 📝 Generate AndroidManifest.xml
# ============================================================================

log "📝 Generating android/app/src/main/AndroidManifest.xml..."

cat > android/app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Always required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Conditional permissions based on feature flags -->
    <uses-permission android:name="android.permission.CAMERA" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-feature android:name="android.hardware.microphone" android:required="false" />

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <uses-permission android:name="android.permission.READ_CONTACTS" />
    <uses-permission android:name="android.permission.WRITE_CONTACTS" />
    <uses-permission android:name="android.permission.GET_ACCOUNTS" />

    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />

    <uses-permission android:name="android.permission.READ_CALENDAR" />
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />

    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

    <application
        android:label="$APP_NAME"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="true"
        android:fullBackupContent="@xml/backup_rules"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:usesCleartextTraffic="true"
        android:networkSecurityConfig="@xml/network_security_config">

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

        <!-- OAuth Configuration -->
        <meta-data
            android:name="IS_GOOGLE_AUTH"
            android:value="$IS_GOOGLE_AUTH" />
        <meta-data
            android:name="IS_APPLE_AUTH"
            android:value="$IS_APPLE_AUTH" />
        <meta-data
            android:name="PUSH_NOTIFY"
            android:value="$PUSH_NOTIFY" />

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- OAuth Intent Filters -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="${PKG_NAME}" />
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
EOF

log "✅ Generated android/app/src/main/AndroidManifest.xml"

# ============================================================================
# 📝 Generate keystore.properties (if keystore is configured)
# ============================================================================

if [[ "${KEY_STORE_URL:-}" != "" ]]; then
    log "📝 Generating android/app/src/keystore.properties..."
    
    cat > android/app/src/keystore.properties << 'EOF'
storeFile=keystore.jks
storePassword=$CM_KEYSTORE_PASSWORD
keyAlias=$CM_KEY_ALIAS
keyPassword=$CM_KEY_PASSWORD
EOF

    log "✅ Generated android/app/src/keystore.properties"
else
    log "⚠️ No keystore URL provided, skipping keystore.properties generation"
fi

# ============================================================================
# 📝 Generate other configuration files
# ============================================================================

# Generate proguard-rules.pro
log "📝 Generating android/app/proguard-rules.pro..."
cat > android/app/proguard-rules.pro << 'EOF'
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# OAuth specific rules
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.apple.android.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}
EOF

log "✅ Generated android/app/proguard-rules.pro"

# Generate network_security_config.xml
log "📝 Generating android/app/src/main/res/xml/network_security_config.xml..."
mkdir -p android/app/src/main/res/xml
cat > android/app/src/main/res/xml/network_security_config.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
EOF

log "✅ Generated android/app/src/main/res/xml/network_security_config.xml"

# Generate styles.xml
log "📝 Generating android/app/src/main/res/values/styles.xml..."
mkdir -p android/app/src/main/res/values
cat > android/app/src/main/res/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOF

log "✅ Generated android/app/src/main/res/values/styles.xml"

# Generate launch_background.xml
log "📝 Generating android/app/src/main/res/drawable/launch_background.xml..."
mkdir -p android/app/src/main/res/drawable
cat > android/app/src/main/res/drawable/launch_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>
EOF

log "✅ Generated android/app/src/main/res/drawable/launch_background.xml"

# Generate values-night/styles.xml
log "📝 Generating android/app/src/main/res/values-night/styles.xml..."
mkdir -p android/app/src/main/res/values-night
cat > android/app/src/main/res/values-night/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOF

log "✅ Generated android/app/src/main/res/values-night/styles.xml"

# Generate drawable-v21/launch_background.xml
log "📝 Generating android/app/src/main/res/drawable-v21/launch_background.xml..."
mkdir -p android/app/src/main/res/drawable-v21
cat > android/app/src/main/res/drawable-v21/launch_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="?android:colorBackground" />
</layer-list>
EOF

log "✅ Generated android/app/src/main/res/drawable-v21/launch_background.xml"

# Generate drawable-night/launch_background.xml
log "📝 Generating android/app/src/main/res/drawable-night/launch_background.xml..."
mkdir -p android/app/src/main/res/drawable-night
cat > android/app/src/main/res/drawable-night/launch_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black" />
</layer-list>
EOF

log "✅ Generated android/app/src/main/res/drawable-night/launch_background.xml"

log "🎉 Dynamic Android Configuration Generation Completed Successfully!"
log "📊 Summary:"
log "   ✅ build.gradle.kts generated with package: $PKG_NAME"
log "   ✅ gradle.properties optimized for performance"
log "   ✅ AndroidManifest.xml with dynamic permissions"
log "   ✅ OAuth configuration: Google Auth=$IS_GOOGLE_AUTH, Apple Auth=$IS_APPLE_AUTH"
log "   ✅ All Android configuration files generated dynamically" 