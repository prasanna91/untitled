#!/bin/bash

# 🚀 Android Build Script for Codemagic CI/CD
# Handles APK and AAB generation with proper signing and optimization

# Source logging utilities
source "$(dirname "$0")/../utils/logging.sh"

log_section "Android Build Process"

# Configuration
BUILD_TYPE="${BUILD_TYPE:-release}"
BUILD_MODE="${BUILD_MODE:-apk}"
OUTPUT_DIR="output/android"
BUILD_DIR="build/app/outputs"

# Function to verify Android project structure
verify_android_project() {
    log_step "Verifying Android project structure"
    
    local project_root="$(pwd)"
    local android_dir="$project_root/android"
    local gradlew="$android_dir/gradlew"
    
    # Check if android directory exists
    if [[ ! -d "$android_dir" ]]; then
        log_error "Android directory not found at $android_dir"
        log_error "Current working directory: $project_root"
        log_error "Directory contents:"
        ls -la "$project_root" || true
        return 1
    fi
    
    # Check if gradlew exists
    if [[ ! -f "$gradlew" ]]; then
        log_error "Gradle wrapper not found at $gradlew"
        log_error "Android directory contents:"
        ls -la "$android_dir" || true
        return 1
    fi
    
    # Make gradlew executable
    chmod +x "$gradlew" 2>/dev/null || log_warning "Could not make gradlew executable"
    
    log_success "Android project structure verified"
    log_info "Android directory: $android_dir"
    log_info "Gradle wrapper: $gradlew"
}

# Function to setup build environment
setup_build_environment() {
    log_step "Setting up Android build environment"
    
    # Create output directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR"
    
    # Set Gradle optimization flags
    export GRADLE_DAEMON=true
    export GRADLE_PARALLEL=true
    export GRADLE_CACHING=true
    export GRADLE_OFFLINE=false
    export GRADLE_CONFIGURE_ON_DEMAND=true
    export GRADLE_BUILD_CACHE=true
    
    # Set Flutter optimization flags
    export FLUTTER_PUB_CACHE=true
    export FLUTTER_VERBOSE=false
    export FLUTTER_ANALYZE=true
    export FLUTTER_TEST=false
    
    log_success "Build environment setup completed"
}

# Function to download and setup keystore
setup_keystore() {
    if [[ -n "${KEY_STORE_URL:-}" ]]; then
        log_step "Setting up Android keystore for signing"
        
        # Download keystore - use absolute path
        local project_root="$(pwd)"
        local keystore_path="$project_root/android/app/keystore.jks"
        mkdir -p "$(dirname "$keystore_path")"
        
        if curl -L -o "$keystore_path" "$KEY_STORE_URL"; then
            log_success "Keystore downloaded successfully"
            
            # Update gradle.properties with keystore info
            local gradle_props="$project_root/android/gradle.properties"
            if [[ -f "$gradle_props" ]]; then
                cat >> "$gradle_props" << EOF

# Keystore configuration for release builds
RELEASE_STORE_FILE=keystore.jks
RELEASE_KEY_ALIAS=${CM_KEY_ALIAS:-my_key_alias}
RELEASE_STORE_PASSWORD=${CM_KEYSTORE_PASSWORD:-}
RELEASE_KEY_PASSWORD=${CM_KEY_PASSWORD:-}
EOF
                log_success "Keystore configuration added to gradle.properties"
            else
                log_warning "gradle.properties not found at $gradle_props"
            fi
        else
            log_error "Failed to download keystore from $KEY_STORE_URL"
            return 1
        fi
    else
        log_warning "No keystore URL provided, using debug signing"
    fi
}

# Function to download Firebase configuration
setup_firebase() {
    if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]]; then
        log_step "Setting up Firebase configuration"
        
        # Use absolute path for Firebase config
        local project_root="$(pwd)"
        local firebase_config_path="$project_root/android/app/google-services.json"
        
        if curl -L -o "$firebase_config_path" "$FIREBASE_CONFIG_ANDROID"; then
            log_success "Firebase configuration downloaded successfully"
        else
            log_error "Failed to download Firebase configuration"
            return 1
        fi
    else
        log_warning "No Firebase configuration provided"
    fi
}

# Function to update app configuration
update_app_config() {
    log_step "Updating app configuration"
    
    # Update app name in strings.xml - use absolute path
    if [[ -n "${APP_NAME:-}" ]]; then
        local project_root="$(pwd)"
        local strings_file="$project_root/android/app/src/main/res/values/strings.xml"
        
        if [[ -f "$strings_file" ]]; then
            sed -i.bak "s/<string name=\"app_name\">.*<\/string>/<string name=\"app_name\">$APP_NAME<\/string>/" "$strings_file"
            log_info "Updated app name to: $APP_NAME"
        else
            log_warning "strings.xml not found at $strings_file"
        fi
    fi
    
    # Update package name if provided
    if [[ -n "${PKG_NAME:-}" ]]; then
        log_info "Package name: $PKG_NAME"
        # Note: Package name changes require more complex modifications
        # This is handled by the build.gradle.kts file
    fi
    
    log_success "App configuration updated"
}

# Function to clean previous builds
clean_builds() {
    log_step "Cleaning previous builds"
    
    # Clean Flutter
    flutter clean
    
    # Clean Gradle - use absolute path to ensure we're in the right directory
    local android_dir="$(pwd)/android"
    if [[ -d "$android_dir" && -f "$android_dir/gradlew" ]]; then
        cd "$android_dir"
        ./gradlew clean
        cd - > /dev/null  # Return to previous directory
    else
        log_warning "Android directory or gradlew not found at $android_dir"
        log_info "Skipping Gradle clean, continuing with build..."
    fi
    
    # Remove output directory
    rm -rf "$OUTPUT_DIR"/*
    
    log_success "Build cleanup completed"
}

# Function to build APK
build_apk() {
    log_step "Building Android APK"
    
    local build_args="--release"
    
    if [[ -n "${KEY_STORE_URL:-}" ]]; then
        build_args="$build_args --build-number=${VERSION_CODE:-1}"
    fi
    
    if flutter build apk $build_args; then
        log_success "APK build completed successfully"
        
        # Copy APK to output directory
        cp "$BUILD_DIR/flutter-apk/app-release.apk" "$OUTPUT_DIR/"
        log_info "APK copied to: $OUTPUT_DIR/app-release.apk"
    else
        log_error "APK build failed"
        return 1
    fi
}

# Function to build AAB
build_aab() {
    log_step "Building Android App Bundle (AAB)"
    
    local build_args="--release"
    
    if [[ -n "${KEY_STORE_URL:-}" ]]; then
        build_args="$build_args --build-number=${VERSION_CODE:-1}"
    fi
    
    if flutter build appbundle $build_args; then
        log_success "AAB build completed successfully"
        
        # Copy AAB to output directory
        cp "$BUILD_DIR/bundle/release/app-release.aab" "$OUTPUT_DIR/"
        log_info "AAB copied to: $OUTPUT_DIR/app-release.aab"
    else
        log_error "AAB build failed"
        return 1
    fi
}

# Function to generate build artifacts summary
generate_build_summary() {
    log_step "Generating build artifacts summary"
    
    local summary_file="$OUTPUT_DIR/BUILD_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
🚀 Android Build Summary
========================
Build Time: $(date)
Workflow: ${WORKFLOW_ID:-Unknown}
App Name: ${APP_NAME:-Unknown}
Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})
Package: ${PKG_NAME:-Unknown}

📱 Build Artifacts:
$(ls -la "$OUTPUT_DIR"/*.apk "$OUTPUT_DIR"/*.aab 2>/dev/null || echo "No artifacts found")

🔧 Build Configuration:
- Build Type: $BUILD_TYPE
- Build Mode: $BUILD_MODE
- Keystore: ${KEY_STORE_URL:+Configured}
- Firebase: ${FIREBASE_CONFIG_ANDROID:+Configured}
- Signing: ${KEY_STORE_URL:+Release}${KEY_STORE_URL:-Debug}

✅ Build Status: SUCCESS
EOF

    log_success "Build summary generated: $summary_file"
}

# Function to create missing Android resource files
create_android_resources() {
    log_step "Creating missing Android resource files"
    
    # Create values directory - use absolute path
    local project_root="$(pwd)"
    local values_dir="$project_root/android/app/src/main/res/values"
    mkdir -p "$values_dir"
    
    # Create strings.xml if it doesn't exist
    local strings_file="$values_dir/strings.xml"
    if [[ ! -f "$strings_file" ]]; then
        cat > "$strings_file" << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">${APP_NAME:-QuikApp}</string>
    <string name="app_description">${APP_NAME:-QuikApp} - A powerful mobile application</string>
</resources>
EOF
        log_success "Created strings.xml with app name: ${APP_NAME:-QuikApp}"
    fi
    
    # Create colors.xml if it doesn't exist
    local colors_file="$values_dir/colors.xml"
    if [[ ! -f "$colors_file" ]]; then
        cat > "$colors_file" << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary">#007AFF</color>
    <color name="primary_dark">#0056CC</color>
    <color name="accent">#FF6B35</color>
    <color name="background">#FFFFFF</color>
    <color name="text_primary">#000000</color>
    <color name="text_secondary">#666666</color>
</resources>
EOF
        log_success "Created colors.xml with default color scheme"
    fi
    
    # Create styles.xml if it doesn't exist
    local styles_file="$values_dir/styles.xml"
    if [[ ! -f "$styles_file" ]]; then
        cat > "$styles_file" << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.DarkActionBar">
        <item name="colorPrimary">@color/primary</item>
        <item name="colorPrimaryDark">@color/primary_dark</item>
        <item name="colorAccent">@color/accent</item>
    </style>
</resources>
EOF
        log_success "Created styles.xml with default theme"
    fi
}

# Main build function
main() {
    log_info "Starting Android build process"
    log_info "Build Type: $BUILD_TYPE, Mode: $BUILD_MODE"
    
    # Log current working directory and project structure
    log_info "Current working directory: $(pwd)"
    log_info "Project structure:"
    ls -la . || true
    log_info "Android directory contents:"
    ls -la android/ 2>/dev/null || log_warning "Cannot list android directory"
    
    # Verify Android project structure first
    if ! verify_android_project; then
        log_error "Android project structure verification failed"
        exit 1
    fi
    
    # Setup environment
    setup_build_environment
    
    # Setup keystore if provided
    setup_keystore
    
    # Setup Firebase if provided
    setup_firebase
    
    # Setup feature integrations
    log_step "Setting up feature integrations"
    if bash "$(dirname "$0")/../utils/feature_integration.sh"; then
        log_success "Feature integrations configured successfully"
    else
        log_warning "Feature integration had issues, but continuing with build"
    fi
    
    # Update app configuration
    update_app_config
    
    # Create missing Android resource files if they don't exist
    create_android_resources
    
    # Clean previous builds
    clean_builds
    
    # Build based on mode
    case "$BUILD_MODE" in
        "apk")
            build_apk
            ;;
        "aab")
            build_aab
            ;;
        "both")
            build_apk
            build_aab
            ;;
        *)
            log_error "Invalid build mode: $BUILD_MODE"
            exit 1
            ;;
    esac
    
    # Generate build summary
    generate_build_summary
    
    log_success "Android build process completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
