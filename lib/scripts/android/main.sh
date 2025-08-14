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
    local gradle_wrapper_jar="$android_dir/gradle/wrapper/gradle-wrapper.jar"
    
    # Check if android directory exists
    if [[ ! -d "$android_dir" ]]; then
        log_error "Android directory not found at $android_dir"
        log_error "Current working directory: $project_root"
        log_error "Directory contents:"
        ls -la "$project_root" || true
        return 1
    fi
    
    # Check for required Android configuration files
    local local_props="$android_dir/local.properties"
    local gradle_props="$android_dir/gradle.properties"
    
    if [[ ! -f "$local_props" ]]; then
        log_warning "local.properties not found - will be created during setup"
    fi
    
    if [[ ! -f "$gradle_props" ]]; then
        log_warning "gradle.properties not found - will be created during setup"
    fi
    
    # Check if gradlew exists, if not try to generate it
    if [[ ! -f "$gradlew" ]]; then
        log_warning "Gradle wrapper not found at $gradlew"
        log_info "Attempting to generate Gradle wrapper..."
        
        # Check if gradle wrapper jar exists
        if [[ -f "$gradle_wrapper_jar" ]]; then
            log_info "Gradle wrapper JAR found, generating gradlew script..."
            
            # Generate gradlew script
            cat > "$gradlew" << 'EOF'
#!/bin/sh
#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
  CYGWIN* )
    cygwin=false
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=false
    ;;
  NONSTOP* )
    nonstop=false
    ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "$cygwin" = "false" -a "$darwin" = "false" -a "$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if $darwin; then
    GRADLE_OPTS="$GRADLE_OPTS \"-Xdock:name=$APP_NAME\" \"-Xdock:icon=$APP_HOME/media/gradle.icns\""
fi

# For Cygwin or MSYS, switch paths to Windows format before running java
if [ "$cygwin" = "true" -o "$msys" = "true" ] ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
    JAVACMD=`cygpath --unix "$JAVACMD"`

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=`find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null`
    SEP=""
    for dir in $ROOTDIRSRAW ; do
        ROOTDIRS="$ROOTDIRS$SEP$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "$@" ; do
        CHECK=`echo "$arg"|egrep -c "$OURCYGPATTERN" -`
        CHECK2=`echo "$arg"|egrep -c "^-"`                                 ### Determine if an option

        if [ $CHECK -ne 0 ] && [ $CHECK2 -eq 0 ] ; then                    ### Added a condition
            eval `echo args$i`=`cygpath --path --ignore --mixed "$arg"`
        else
            eval `echo args$i`="\"$arg\""
        fi
        i=`expr $i + 1`
    done
    case $i in
        0) set -- ;;
        1) set -- "$args0" ;;
        2) set -- "$args0" "$args1" ;;
        3) set -- "$args0" "$args1" "$args2" ;;
        4) set -- "$args0" "$args1" "$args2" "$args3" ;;
        5) set -- "$args0" "$args1" "$args2" "$args3" "$args4" ;;
        6) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" ;;
        7) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" ;;
        8) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" ;;
        9) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" "$args8" ;;
    esac
fi

# Escape application args
save () {
    for i do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
    echo " "
}
APP_ARGS=`save "$@"`

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS "\"-Dorg.gradle.appname=$APP_BASE_NAME\"" -classpath "\"$CLASSPATH\"" org.gradle.wrapper.GradleWrapperMain "$APP_ARGS"

exec "$JAVACMD" "$@"
EOF
            
            # Make gradlew executable
            chmod +x "$gradlew"
            log_success "Gradle wrapper script generated successfully"
        else
            log_warning "Gradle wrapper JAR not found at $gradle_wrapper_jar"
            log_info "Attempting to use Flutter's built-in Gradle wrapper..."
            
            # Try Flutter's built-in Gradle wrapper first
            if try_flutter_gradle_wrapper; then
                log_success "Successfully set up Gradle wrapper from Flutter"
                return 0
            fi
            
            log_info "Flutter wrapper not available, attempting to download Gradle wrapper..."
            
            # Try to download gradle wrapper
            local gradle_wrapper_dir="$android_dir/gradle/wrapper"
            mkdir -p "$gradle_wrapper_dir"
            
            # Try multiple Gradle versions and sources for better reliability
            local gradle_versions=("8.0" "7.6.3" "7.6.2" "7.6.1")
            local download_success=false
            
            for gradle_version in "${gradle_versions[@]}"; do
                log_info "Trying Gradle version $gradle_version..."
                
                # Try Maven Central first
                local wrapper_url="https://repo1.maven.org/maven2/org/gradle/gradle-wrapper/$gradle_version/gradle-wrapper-$gradle_version.jar"
                
                if curl -L -o "$gradle_wrapper_jar" "$wrapper_url" --connect-timeout 30 --max-time 120; then
                    log_info "Downloaded gradle-wrapper.jar from Maven Central"
                    
                    # Validate the JAR file
                    if java -cp "$gradle_wrapper_jar" org.gradle.wrapper.GradleWrapperMain --version >/dev/null 2>&1; then
                        log_success "Gradle wrapper JAR validated successfully (version $gradle_version)"
                        download_success=true
                        break
                    else
                        log_warning "Downloaded JAR appears corrupted, trying next version..."
                        rm -f "$gradle_wrapper_jar"
                    fi
                else
                    log_warning "Failed to download from Maven Central, trying next version..."
                fi
            done
            
            if [[ "$download_success" == "true" ]]; then
                # Create gradle-wrapper.properties with the successful version
                cat > "$gradle_wrapper_dir/gradle-wrapper.properties" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-$gradle_version-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
                
                # Now generate the gradlew script
                log_info "Generating gradlew script with downloaded wrapper..."
                cat > "$gradlew" << 'EOF'
#!/bin/sh
#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
  CYGWIN* )
    cygwin=false
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=false
    ;;
  NONSTOP* )
    nonstop=false
    ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "$cygwin" = "false" -a "$darwin" = "false" -a "$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if $darwin; then
    GRADLE_OPTS="$GRADLE_OPTS \"-Xdock:name=$APP_NAME\" \"-Xdock:icon=$APP_HOME/media/gradle.icns\""
fi

# For Cygwin or MSYS, switch paths to Windows format before running java
if [ "$cygwin" = "true" -o "$msys" = "true" ] ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
    JAVACMD=`cygpath --unix "$JAVACMD"`

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=`find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null`
    SEP=""
    for dir in $ROOTDIRSRAW ; do
        ROOTDIRS="$ROOTDIRS$SEP$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "$@" ; do
        CHECK=`echo "$arg"|egrep -c "$OURCYGPATTERN" -`
        CHECK2=`echo "$arg"|egrep -c "^-"`                                 ### Determine if an option

        if [ $CHECK -ne 0 ] && [ $CHECK2 -eq 0 ] ; then                    ### Added a condition
            eval `echo args$i`=`cygpath --path --ignore --mixed "$arg"`
        else
            eval `echo args$i`="\"$arg\""
        fi
        i=`expr $i + 1`
    done
    case $i in
        0) set -- ;;
        1) set -- "$args0" ;;
        2) set -- "$args0" "$args1" ;;
        3) set -- "$args0" "$args1" "$args2" ;;
        4) set -- "$args0" "$args1" "$args2" "$args3" ;;
        5) set -- "$args0" "$args1" "$args2" "$args3" "$args4" ;;
        6) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" ;;
        7) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" ;;
        8) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" ;;
        9) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" "$args8" ;;
    esac
fi

# Escape application args
save () {
    for i do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
    echo " "
}
APP_ARGS=`save "$@"`

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS "\"-Dorg.gradle.appname=$APP_BASE_NAME\"" -classpath "\"$CLASSPATH\"" org.gradle.wrapper.GradleWrapperMain "$APP_ARGS"

exec "$JAVACMD" "$@"
EOF
                
                # Make gradlew executable
                chmod +x "$gradlew"
                log_success "Gradle wrapper downloaded and script generated successfully"
            else
                log_error "Failed to download valid gradle-wrapper.jar from all sources"
                log_warning "Attempting to use system Gradle as fallback..."
                
                # Check if system Gradle is available
                if check_system_gradle; then
                    log_info "System Gradle available, continuing without wrapper"
                    return 0  # Allow the build to continue with system Gradle
                else
                    log_error "No Gradle available - neither wrapper nor system installation"
                    log_error "Cannot proceed with Android build"
                    log_error "Android directory contents:"
                    ls -la "$android_dir" || true
                    return 1
                fi
            fi
        fi
    fi
    
    # Make gradlew executable if it exists
    if [[ -f "$gradlew" ]]; then
        chmod +x "$gradlew" 2>/dev/null || log_warning "Could not make gradlew executable"
        
        # Test if the gradlew script actually works
        log_info "Testing Gradle wrapper functionality..."
        if cd "$android_dir" && ./gradlew --version >/dev/null 2>&1; then
            log_success "Gradle wrapper test passed"
            cd - > /dev/null
        else
            log_warning "Gradle wrapper test failed, trying to regenerate..."
            cd - > /dev/null
            rm -f "$gradlew"
            # Try to regenerate the wrapper
            if try_flutter_gradle_wrapper; then
                log_success "Successfully regenerated Gradle wrapper from Flutter"
            else
                log_error "Failed to regenerate working Gradle wrapper"
                return 1
            fi
        fi
        
        log_success "Android project structure verified with Gradle wrapper"
        log_info "Android directory: $android_dir"
        log_info "Gradle wrapper: $gradlew"
    else
        # Check if system Gradle is available as fallback
        if check_system_gradle; then
            log_success "Android project structure verified with system Gradle"
            log_info "Android directory: $android_dir"
            log_info "Using system Gradle: $(gradle --version | head -1)"
        else
            log_error "No Gradle available - neither wrapper nor system installation"
            return 1
        fi
    fi
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

# Function to check if system Gradle is available
check_system_gradle() {
    if command -v gradle >/dev/null 2>&1; then
        log_info "System Gradle found: $(gradle --version | head -1)"
        return 0
    else
        log_warning "System Gradle not found in PATH"
        return 1
    fi
}

# Function to try to use Flutter's built-in Gradle wrapper
try_flutter_gradle_wrapper() {
    log_info "Attempting to use Flutter's built-in Gradle wrapper..."
    
    # Check if Flutter has a built-in Gradle wrapper
    local flutter_gradle_dir="$HOME/.pub-cache/bin/cache/flutter"
    if [[ -d "$flutter_gradle_dir" ]]; then
        # Look for Gradle wrapper in Flutter cache
        local flutter_gradlew=$(find "$flutter_gradle_dir" -name "gradlew" -type f 2>/dev/null | head -1)
        if [[ -n "$flutter_gradlew" ]]; then
            log_info "Found Flutter Gradle wrapper at: $flutter_gradlew"
            # Copy it to our Android directory
            cp "$flutter_gradlew" "$android_dir/gradlew"
            chmod +x "$android_dir/gradlew"
            
            # Also look for gradle-wrapper.jar
            local flutter_wrapper_jar=$(find "$flutter_gradle_dir" -name "gradle-wrapper.jar" -type f 2>/dev/null | head -1)
            if [[ -n "$flutter_wrapper_jar" ]]; then
                log_info "Found Flutter gradle-wrapper.jar at: $flutter_wrapper_jar"
                mkdir -p "$android_dir/gradle/wrapper"
                cp "$flutter_wrapper_jar" "$android_dir/gradle/wrapper/gradle-wrapper.jar"
                
                # Create gradle-wrapper.properties
                cat > "$android_dir/gradle/wrapper/gradle-wrapper.properties" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.3-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
                
                log_success "Successfully copied Flutter's Gradle wrapper"
                return 0
            fi
        fi
    fi
    
    log_warning "Flutter's built-in Gradle wrapper not found"
    return 1
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
    elif check_system_gradle; then
        log_info "Using system Gradle for cleanup..."
        cd "$android_dir"
        gradle clean
        cd - > /dev/null  # Return to previous directory
    else
        log_warning "Neither gradlew nor system Gradle available"
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

# Function to create missing Android configuration files
create_android_config() {
    log_step "Creating missing Android configuration files"
    
    local project_root="$(pwd)"
    local android_dir="$project_root/android"
    
    # Create local.properties if it doesn't exist
    local local_props="$android_dir/local.properties"
    if [[ ! -f "$local_props" ]]; then
        log_info "Creating local.properties file..."
        
        # Try to detect Android SDK location
        local sdk_path=""
        
        # Check common Android SDK locations
        if [[ -n "$ANDROID_HOME" ]]; then
            sdk_path="$ANDROID_HOME"
            log_info "Using ANDROID_HOME: $sdk_path"
        elif [[ -n "$ANDROID_SDK_ROOT" ]]; then
            sdk_path="$ANDROID_SDK_ROOT"
            log_info "Using ANDROID_SDK_ROOT: $sdk_path"
        elif [[ -d "$HOME/Library/Android/sdk" ]]; then
            sdk_path="$HOME/Library/Android/sdk"
            log_info "Using macOS default SDK path: $sdk_path"
        elif [[ -d "$HOME/Android/Sdk" ]]; then
            sdk_path="$HOME/Android/Sdk"
            log_info "Using Linux default SDK path: $sdk_path"
        elif [[ -d "$LOCALAPPDATA/Android/Sdk" ]]; then
            sdk_path="$LOCALAPPDATA/Android/Sdk"
            log_info "Using Windows default SDK path: $sdk_path"
        else
            # Try to find SDK in common locations
            local possible_paths=(
                "/usr/local/android-sdk"
                "/opt/android-sdk"
                "/usr/lib/android-sdk"
                "/opt/android-sdk-linux"
            )
            
            for path in "${possible_paths[@]}"; do
                if [[ -d "$path" ]]; then
                    sdk_path="$path"
                    log_info "Found SDK in common location: $sdk_path"
                    break
                fi
            done
        fi
        
        # Create local.properties with detected or default SDK path
        if [[ -n "$sdk_path" ]]; then
            cat > "$local_props" << EOF
## This file must *NOT* be checked into Version Control Systems,
## as it contains information specific to your local configuration.
#
# Location of the SDK. This is only used by Gradle.
# For customization when using a Version Control System, please read the
# header note.
sdk.dir=$sdk_path
EOF
            log_success "Created local.properties with SDK path: $sdk_path"
        else
            # Create with a placeholder that can be updated later
            cat > "$local_props" << EOF
## This file must *NOT* be checked into Version Control Systems,
## as it contains information specific to your local configuration.
#
# Location of the SDK. This is only used by Gradle.
# For customization when using a Version Control System, please read the
# header note.
# sdk.dir=/path/to/your/android/sdk
# 
# Common locations:
# macOS: $HOME/Library/Android/sdk
# Linux: $HOME/Android/Sdk
# Windows: %LOCALAPPDATA%\\Android\\Sdk
EOF
            log_warning "Created local.properties with placeholder SDK path"
            log_info "You may need to update sdk.dir in $local_props"
        fi
    else
        log_info "local.properties already exists"
    fi
    
    # Create gradle.properties if it doesn't exist
    local gradle_props="$android_dir/gradle.properties"
    if [[ ! -f "$gradle_props" ]]; then
        log_info "Creating gradle.properties file..."
        cat > "$gradle_props" << EOF
# Project-wide Gradle settings.
#
# IDE (e.g. Android Studio) users:
# Gradle settings configured through the IDE *will override*
# any settings specified in this file.
#
# For more details on how to configure your build environment visit
# http://www.gradle.org/docs/current/userguide/build_environment.html

# Specifies the JVM arguments used for the daemon process.
# The setting is particularly useful for tweaking memory settings.
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8

# When configured, Gradle will run in incubating parallel mode.
# This option should only be used with decoupled projects. More details, visit
# http://www.gradle.org/docs/current/userguide/multi_project_builds.html#sec:decoupled_projects
org.gradle.parallel=true

# AndroidX package structure to make it clearer which packages are bundled with the
# Android operating system, and which are packaged with your app's APK
# https://developer.android.com/topic/libraries/support-library/androidx-rn
android.useAndroidX=true

# Automatically convert third-party libraries to use AndroidX
android.enableJetifier=true

# Enables namespacing of each library's R class so that its R class includes only the
# resources declared in the library itself and none from the library's dependencies,
# thereby reducing the size of the R class for that library
android.nonTransitiveRClass=true
EOF
        log_success "Created gradle.properties with default settings"
    else
        log_info "gradle.properties already exists"
    fi
}

# Function to verify Android SDK accessibility
verify_android_sdk() {
    log_step "Verifying Android SDK accessibility"
    
    local project_root="$(pwd)"
    local android_dir="$project_root/android"
    local local_props="$android_dir/local.properties"
    
    if [[ -f "$local_props" ]]; then
        # Extract SDK path from local.properties
        local sdk_path=$(grep "^sdk.dir=" "$local_props" | cut -d'=' -f2 | tr -d '\r')
        
        if [[ -n "$sdk_path" && "$sdk_path" != "#"* ]]; then
            log_info "Android SDK path from local.properties: $sdk_path"
            
            # Check if SDK directory exists and contains required components
            if [[ -d "$sdk_path" ]]; then
                local sdk_platforms="$sdk_path/platforms"
                local sdk_build_tools="$sdk_path/build-tools"
                
                if [[ -d "$sdk_platforms" ]]; then
                    log_success "Android SDK platforms directory found"
                else
                    log_warning "Android SDK platforms directory not found at $sdk_platforms"
                fi
                
                if [[ -d "$sdk_build_tools" ]]; then
                    log_success "Android SDK build-tools directory found"
                else
                    log_warning "Android SDK build-tools directory not found at $sdk_build_tools"
                fi
                
                # Check for at least one platform version
                local platform_count=$(find "$sdk_platforms" -maxdepth 1 -type d -name "android-*" 2>/dev/null | wc -l)
                if [[ $platform_count -gt 0 ]]; then
                    log_success "Found $platform_count Android platform(s)"
                else
                    log_warning "No Android platforms found in SDK"
                fi
                
                # Check for at least one build-tools version
                local build_tools_count=$(find "$sdk_build_tools" -maxdepth 1 -type d -name "*.*.*" 2>/dev/null | wc -l)
                if [[ $build_tools_count -gt 0 ]]; then
                    log_success "Found $build_tools_count build-tools version(s)"
                else
                    log_warning "No build-tools versions found in SDK"
                fi
                
            else
                log_error "Android SDK directory not found at: $sdk_path"
                log_error "Please check your local.properties file and ensure the SDK path is correct"
                return 1
            fi
        else
            log_warning "No valid SDK path found in local.properties"
        fi
    else
        log_warning "local.properties not found - cannot verify SDK path"
    fi
    
    # Check environment variables as fallback
    if [[ -n "$ANDROID_HOME" ]]; then
        log_info "ANDROID_HOME environment variable set: $ANDROID_HOME"
    fi
    
    if [[ -n "$ANDROID_SDK_ROOT" ]]; then
        log_info "ANDROID_SDK_ROOT environment variable set: $ANDROID_SDK_ROOT"
    fi
    
    log_success "Android SDK verification completed"
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
    
    # Create missing Android configuration files
    create_android_config
    
    # Verify Android SDK accessibility
    verify_android_sdk
    
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
