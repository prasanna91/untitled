#!/bin/bash

# iOS Workflow Validation Script
# Validates the iOS workflow configuration and ensures target-only mode compliance

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🔍 iOS Workflow Validation Script"
echo "=================================="

# Function to check if a script exists and is executable
check_script() {
    local script_path="$1"
    local description="$2"
    
    if [ -f "$script_path" ]; then
        if [ -x "$script_path" ]; then
            echo "✅ $description: $script_path (executable)"
            return 0
        else
            echo "⚠️ $description: $script_path (not executable)"
            chmod +x "$script_path"
            echo "   ✅ Made executable"
            return 0
        fi
    else
        echo "❌ $description: $script_path (not found)"
        return 1
    fi
}

# Function to validate environment variables
validate_env_vars() {
    echo ""
    echo "🔍 Environment Variables Validation:"
    echo "-----------------------------------"
    
    local required_vars=("BUNDLE_ID" "APP_NAME" "VERSION_NAME" "VERSION_CODE" "PROFILE_TYPE")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
            echo "❌ $var: not set"
        else
            echo "✅ $var: ${!var}"
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo ""
        echo "❌ Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    echo ""
    echo "✅ All required environment variables are set"
    return 0
}

# Function to validate target-only mode configuration
validate_target_only_mode() {
    echo ""
    echo "🛡️ Target-Only Mode Validation:"
    echo "-------------------------------"
    
    local target_only_mode="${TARGET_ONLY_MODE:-false}"
    local enable_collision_fix="${ENABLE_COLLISION_FIX:-false}"
    local enable_framework_bundle_update="${ENABLE_FRAMEWORK_BUNDLE_UPDATE:-false}"
    local enable_bundle_id_echo="${ENABLE_BUNDLE_ID_ECHO:-true}"
    
    echo "  - TARGET_ONLY_MODE: $target_only_mode"
    echo "  - ENABLE_COLLISION_FIX: $enable_collision_fix"
    echo "  - ENABLE_FRAMEWORK_BUNDLE_UPDATE: $enable_framework_bundle_update"
    echo "  - ENABLE_BUNDLE_ID_ECHO: $enable_bundle_id_echo"
    
    if [ "$target_only_mode" = "true" ]; then
        echo "✅ Target-Only Mode is enabled"
        
        if [ "$enable_collision_fix" = "false" ]; then
            echo "✅ Collision fix is disabled (correct for target-only mode)"
        else
            echo "⚠️ Collision fix is enabled (should be disabled in target-only mode)"
        fi
        
        if [ "$enable_framework_bundle_update" = "false" ]; then
            echo "✅ Framework bundle update is disabled (correct for target-only mode)"
        else
            echo "⚠️ Framework bundle update is enabled (should be disabled in target-only mode)"
        fi
        
        if [ "$enable_bundle_id_echo" = "true" ]; then
            echo "✅ Bundle ID echo is enabled (correct for target-only mode)"
        else
            echo "⚠️ Bundle ID echo is disabled (should be enabled in target-only mode)"
        fi
    else
        echo "⚠️ Target-Only Mode is disabled"
    fi
    
    return 0
}

# Function to validate required scripts
validate_scripts() {
    echo ""
    echo "🔧 Script Validation:"
    echo "-------------------"
    
    local script_errors=0
    
    # Check iOS workflow scripts
    check_script "lib/scripts/ios-workflow/pre-build.sh" "Pre-build script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios-workflow/build.sh" "Build script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios-workflow/post-build.sh" "Post-build script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios-workflow/bundle-executable-fix.sh" "Bundle executable fix script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios-workflow/app-store-connect-fix.sh" "App Store Connect fix script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios-workflow/app-store-validation.sh" "App Store validation script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios-workflow/testflight-upload.sh" "TestFlight upload script" || script_errors=$((script_errors + 1))
    
    # Check core iOS scripts
    check_script "lib/scripts/ios/main.sh" "Main iOS script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios/update_bundle_id_target_only.sh" "Target-only bundle ID update script" || script_errors=$((script_errors + 1))
    check_script "lib/scripts/ios/utils.sh" "iOS utilities script" || script_errors=$((script_errors + 1))
    
    # Check utility scripts
    check_script "lib/scripts/utils/gen_env_config.sh" "Environment config generator" || script_errors=$((script_errors + 1))
    
    if [ $script_errors -eq 0 ]; then
        echo ""
        echo "✅ All required scripts are present and executable"
        return 0
    else
        echo ""
        echo "❌ Found $script_errors script errors"
        return 1
    fi
}

# Function to validate Flutter and Xcode setup
validate_build_environment() {
    echo ""
    echo "🏗️ Build Environment Validation:"
    echo "-------------------------------"
    
    # Check Flutter
    if command -v flutter >/dev/null 2>&1; then
        echo "✅ Flutter is available"
        flutter --version | head -1
    else
        echo "❌ Flutter is not available"
        return 1
    fi
    
    # Check Xcode
    if command -v xcodebuild >/dev/null 2>&1; then
        echo "✅ Xcode is available"
        xcodebuild -version | head -1
    else
        echo "❌ Xcode is not available"
        return 1
    fi
    
    # Check CocoaPods
    if command -v pod >/dev/null 2>&1; then
        echo "✅ CocoaPods is available"
        pod --version
    else
        echo "❌ CocoaPods is not available"
        return 1
    fi
    
    # Check Java
    if command -v java >/dev/null 2>&1; then
        echo "✅ Java is available"
        java -version 2>&1 | head -1
    else
        echo "❌ Java is not available"
        return 1
    fi
    
    return 0
}

# Function to validate project structure
validate_project_structure() {
    echo ""
    echo "📁 Project Structure Validation:"
    echo "-------------------------------"
    
    local structure_errors=0
    
    # Check essential directories
    if [ -d "ios" ]; then
        echo "✅ iOS directory exists"
    else
        echo "❌ iOS directory not found"
        structure_errors=$((structure_errors + 1))
    fi
    
    if [ -d "lib" ]; then
        echo "✅ lib directory exists"
    else
        echo "❌ lib directory not found"
        structure_errors=$((structure_errors + 1))
    fi
    
    if [ -d "assets" ]; then
        echo "✅ assets directory exists"
    else
        echo "❌ assets directory not found"
        structure_errors=$((structure_errors + 1))
    fi
    
    # Check essential files
    if [ -f "pubspec.yaml" ]; then
        echo "✅ pubspec.yaml exists"
    else
        echo "❌ pubspec.yaml not found"
        structure_errors=$((structure_errors + 1))
    fi
    
    if [ -f "ios/Runner/Info.plist" ]; then
        echo "✅ iOS Info.plist exists"
    else
        echo "❌ iOS Info.plist not found"
        structure_errors=$((structure_errors + 1))
    fi
    
    if [ $structure_errors -eq 0 ]; then
        echo ""
        echo "✅ Project structure is valid"
        return 0
    else
        echo ""
        echo "❌ Found $structure_errors structure errors"
        return 1
    fi
}

# Main validation function
main() {
    echo "🚀 Starting iOS Workflow Validation..."
    echo ""
    
    local validation_errors=0
    
    # Run all validations
    validate_env_vars || validation_errors=$((validation_errors + 1))
    validate_target_only_mode || validation_errors=$((validation_errors + 1))
    validate_scripts || validation_errors=$((validation_errors + 1))
    validate_build_environment || validation_errors=$((validation_errors + 1))
    validate_project_structure || validation_errors=$((validation_errors + 1))
    
    echo ""
    echo "=================================="
    echo "🔍 Validation Summary:"
    echo "=================================="
    
    if [ $validation_errors -eq 0 ]; then
        echo "✅ All validations passed!"
        echo "🚀 iOS workflow is ready to run"
        return 0
    else
        echo "❌ Found $validation_errors validation errors"
        echo "🔧 Please fix the issues above before running the workflow"
        return 1
    fi
}

# Run main validation
main "$@" 