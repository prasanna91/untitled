#!/bin/bash
# Corrected Flutter Build Commands
# These commands use only valid Flutter flags

# Debug build command
flutter_build_debug() {
    flutter build ios --no-codesign --debug --verbose \
        --build-name="${VERSION_NAME:-1.0.0}" \
        --build-number="${VERSION_CODE:-1}" \
        2>&1 | tee flutter_build_debug.log
}

# Release build command
flutter_build_release() {
    flutter build ios --no-codesign --release --verbose \
        --build-name="${VERSION_NAME:-1.0.0}" \
        --build-number="${VERSION_CODE:-1}" \
        2>&1 | tee flutter_build_release.log
}

# Profile build command
flutter_build_profile() {
    flutter build ios --no-codesign --profile --verbose \
        --build-name="${VERSION_NAME:-1.0.0}" \
        --build-number="${VERSION_CODE:-1}" \
        2>&1 | tee flutter_build_profile.log
}

# Export the functions
export -f flutter_build_debug
export -f flutter_build_release
export -f flutter_build_profile
