#!/bin/bash
# 🔥 Enhanced Environment Configuration Generator
# Generates lib/config/env_config.dart from environment variables

# Crash prevention: Set safe defaults and error handling
set -eo pipefail  # Removed -u to allow unbound variables

# Global error handling
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Error handler function
error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command="$4"
    local func_stack="$5"
    
    echo "❌ Script crashed at line $line_no" >&2
    echo "❌ Exit code: $exit_code" >&2
    echo "❌ Last command: $last_command" >&2
    echo "❌ Function stack: $func_stack" >&2
    
    # Attempt to clean up
    if [[ -f "lib/config/env_config.dart.tmp" ]]; then
        rm -f "lib/config/env_config.dart.tmp"
    fi
    
    exit $exit_code
}

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENV_GEN] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

# Validation functions removed - frontend handles validation

# Safe string escaping function
escape_string() {
    local value="$1"
    # Handle null/undefined values
    if [[ -z "$value" || "$value" == "null" || "$value" == "undefined" ]]; then
        echo ""
        return
    fi
    # Escape backslashes first
    value="${value//\\/\\\\}"
    # Escape quotes
    value="${value//\"/\\\"}"
    # Escape newlines
    value="${value//$'\n'/\\n}"
    # Escape carriage returns
    value="${value//$'\r'/\\r}"
    # Escape tabs
    value="${value//$'\t'/\\t}"
    echo "$value"
}

# Specialized function for escaping JSON strings for Dart
escape_json_for_dart() {
    local json_value="$1"
    
    # Handle null/undefined values
    if [[ -z "$json_value" || "$json_value" == "null" || "$json_value" == "undefined" ]]; then
        echo "[]"
        return
    fi
    
    # If it's already an empty string, return empty array
    if [[ "$json_value" == "" ]]; then
        echo "[]"
        return
    fi
    
    # Handle different data formats that might come from frontend API
    local processed_json="$json_value"
    
    # Simple format detection using basic string operations
    # Case 1: If it starts with [ and ends with ], it's already an array
    if [[ "${processed_json:0:1}" == "[" && "${processed_json: -1}" == "]" ]]; then
        log_info "🔍 Detected JSON array format"
    # Case 2: If it starts with { and ends with }, wrap it in array
    elif [[ "${processed_json:0:1}" == "{" && "${processed_json: -1}" == "}" ]]; then
        log_info "🔍 Detected JSON object format, wrapping in array"
        processed_json="[$processed_json]"
    # Case 3: If it's wrapped in quotes, remove them
    elif [[ "${processed_json:0:1}" == "\"" && "${processed_json: -1}" == "\"" ]]; then
        log_info "🔍 Detected quoted string, removing outer quotes"
        processed_json="${processed_json:1:-1}"
    fi
    
    # Validate the processed JSON
    if ! echo "$processed_json" | python3 -m json.tool >/dev/null 2>&1; then
        log_warning "⚠️ Processed JSON is still not valid, setting to empty array"
        echo "[]"
        return
    fi
    
    # For JSON strings that will be assigned to a Dart string literal,
    # we need to escape the quotes and backslashes properly
    # This is the same escaping that Dart requires for string literals
    
    # First, escape backslashes (must be done first)
    local escaped_value="${processed_json//\\/\\\\}"
    
    # Then escape double quotes
    escaped_value="${escaped_value//\"/\\\"}"
    
    # The result will be a properly escaped string for Dart
    # Example: {"key":"value"} becomes {\"key\":\"value\"}
    # When assigned to Dart: "{\"key\":\"value\"}"
    
    log_info "✅ JSON successfully processed and escaped for Dart"
    echo "$escaped_value"
}

# Safe boolean conversion function
to_bool() {
    local value="$1"
    
    # Handle null/undefined values
    if [[ -z "$value" || "$value" == "null" || "$value" == "undefined" ]]; then
        echo "false"
        return
    fi
    
    # Convert to lowercase and check for true/false
    local lower_value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower_value" == "true" || "$lower_value" == "1" || "$lower_value" == "yes" ]]; then
        echo "true"
    elif [[ "$lower_value" == "false" || "$lower_value" == "0" || "$lower_value" == "no" ]]; then
        echo "false"
    else
        echo "false"
    fi
}

# Safe number conversion function
to_number() {
    local value="$1"
    
    # Handle null/undefined values
    if [[ -z "$value" || "$value" == "null" || "$value" == "undefined" ]]; then
        echo "0"
        return
    fi
    
    if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$value"
    else
        echo "0"
    fi
}

# Safe environment variable getter
get_env_var() {
    local var_name="$1"
    
    # Check if variable exists and is not empty
    if [[ -n "${!var_name:-}" ]]; then
        echo "${!var_name}"
    else
        echo ""
    fi
}

# Cross-platform sed replacement function with proper escaping
cross_platform_sed() {
    local search="$1"
    local replace="$2"
    local file="$3"
    
    # For BOTTOMMENU_ITEMS, use a different approach to preserve the JSON structure
    if [[ "$search" == "BOTTOMMENU_ITEMS_PLACEHOLDER" ]]; then
        # Use a simple string replacement that doesn't interpret escaped characters
        # We'll use a temporary file approach with cat
        local temp_content=$(cat "$file")
        echo "${temp_content//$search/$replace}" > "$file"
    else
        # Use sed for other replacements
        # Detect OS and use appropriate sed syntax
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|$search|$replace|g" "$file"
        elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
            # Windows with Git Bash or Cygwin
            sed -i "s|$search|$replace|g" "$file"
        else
            # Linux and other Unix-like systems
            sed -i "s|$search|$replace|g" "$file"
        fi
    fi
}

# Main execution function
generate_env_config() {
    # Memory and resource management
    log_info "🔧 Setting resource limits for stability..."
    
    # Set memory limits to prevent crashes
    if command -v ulimit >/dev/null 2>&1; then
        # Limit memory usage to prevent crashes
        ulimit -v 1048576 2>/dev/null || true  # 1GB virtual memory limit
        ulimit -m 1048576 2>/dev/null || true  # 1GB memory limit
    fi
    
    # Set timeout for long-running operations
    TIMEOUT_SECONDS=300  # 5 minutes timeout
    
    log_info "Starting enhanced environment configuration generation..."

    # Skip network and environment validation - frontend handles this
    log_info "Skipping network and environment validation (handled by frontend)"

    # Generate environment config with enhanced error handling
log_info "Generating Dart environment configuration (lib/config/env_config.dart)..."

    # Generate environment configuration (proceeding regardless of variable values)
    log_info "Generating environment configuration..."

    # Create the directory if it doesn't exist
    mkdir -p lib/config
    
    # Backup existing file if it exists
    if [ -f "lib/config/env_config.dart" ]; then
        cp lib/config/env_config.dart lib/config/env_config.dart.backup.$(date +%Y%m%d_%H%M%S)
log_info "Backed up existing env_config.dart"
    fi

    # Get all environment variables safely
    local project_id=$(get_env_var "PROJECT_ID")
    local app_id=$(get_env_var "APP_ID")
    local version_name=$(get_env_var "VERSION_NAME")
    local version_code=$(get_env_var "VERSION_CODE")
    local app_name=$(get_env_var "APP_NAME")
    local org_name=$(get_env_var "ORG_NAME")
    local web_url=$(get_env_var "WEB_URL")
    local user_name=$(get_env_var "USER_NAME")
    local email_id=$(get_env_var "EMAIL_ID")
    local workflow_id=$(get_env_var "WORKFLOW_ID")
    local pkg_name=$(get_env_var "PKG_NAME")
    
    # Check if BOTTOMMENU_ITEMS was passed as command line argument
    local cmd_line_bottommenu_items=""
    if [[ -n "${1:-}" ]]; then
        log_info "BOTTOMMENU_ITEMS passed as command line argument: $1"
        cmd_line_bottommenu_items="$1"
    fi
    
    # Provide default values for local development if variables are not set
    project_id="${project_id:-"local-dev-project"}"
    app_id="${app_id:-"1000"}"
    version_name="${version_name:-"1.0.0"}"
    version_code="${version_code:-"1"}"
    app_name="${app_name:-"QuikApp"}"
    org_name="${org_name:-"QuikApp"}"
    web_url="${web_url:-"https://quikapp.co"}"
    user_name="${user_name:-"developer"}"
    email_id="${email_id:-"dev@quikapp.co"}"
    workflow_id="${workflow_id:-"local-dev"}"
    pkg_name="${pkg_name:-"com.quikapp.app"}"
    
    # Log the values being used
    log_info "Using project_id: $project_id"
    log_info "Using pkg_name: $pkg_name"
    log_info "Using workflow_id: $workflow_id"
    
    # Note: PKG_NAME validation removed for local development compatibility
    # In Codemagic, these variables will be properly set by the API
    
    local bundle_id=$(get_env_var "BUNDLE_ID")
    local logo_url=$(get_env_var "LOGO_URL")
    local splash_url=$(get_env_var "SPLASH_URL")
    local splash_bg=$(get_env_var "SPLASH_BG_URL")
    local splash_bg_color=$(get_env_var "SPLASH_BG_COLOR")
    local splash_tagline=$(get_env_var "SPLASH_TAGLINE")
    local splash_tagline_color=$(get_env_var "SPLASH_TAGLINE_COLOR")
    local splash_tagline_font=$(get_env_var "SPLASH_TAGLINE_FONT")
    local splash_tagline_size=$(get_env_var "SPLASH_TAGLINE_SIZE")
    local splash_animation=$(get_env_var "SPLASH_ANIMATION")
    local splash_duration=$(get_env_var "SPLASH_DURATION")
    local bottommenu_items=$(get_env_var "BOTTOMMENU_ITEMS")
    
    # Use command line argument if provided, otherwise use environment variable
    if [[ -n "$cmd_line_bottommenu_items" ]]; then
        bottommenu_items="$cmd_line_bottommenu_items"
        log_info "Using BOTTOMMENU_ITEMS from command line argument"
    else
        log_info "Using BOTTOMMENU_ITEMS from environment variable"
    fi
    
    # Debug: Show what we got for BOTTOMMENU_ITEMS
    log_info "BOTTOMMENU_ITEMS value: '$bottommenu_items'"
    
    # Provide default values for local development
    bundle_id="${bundle_id:-"com.quikapp.app"}"
    logo_url="${logo_url:-""}"
    splash_url="${splash_url:-""}"
    splash_bg="${splash_bg:-""}"
    splash_bg_color="${splash_bg_color:-"#FFFFFF"}"
    splash_tagline="${splash_tagline:-"QuikApp"}"
    splash_tagline_color="${splash_tagline_color:-"#000000"}"
    splash_tagline_font="${splash_tagline_font:-"Roboto"}"
    splash_tagline_size="${splash_tagline_size:-"20"}"
    splash_animation="${splash_animation:-"fade"}"
    splash_duration="${splash_duration:-"3"}"
    
    # Only set default if we don't have a value
    if [[ -z "$bottommenu_items" ]]; then
        bottommenu_items="[]"
    fi
    
    # Ensure bottommenu_items is valid JSON and doesn't contain newlines
    if [[ -n "$bottommenu_items" && "$bottommenu_items" != "[]" ]]; then
        # Remove any newlines from the JSON string
        bottommenu_items=$(echo "$bottommenu_items" | tr -d '\n\r')
        
        # Debug: Show the JSON before preprocessing
        log_info "🔍 Original JSON: '$bottommenu_items'"
        
        # Preprocess JSON: Convert single quotes to double quotes for valid JSON
        log_info "🔧 Preprocessing JSON: Converting single quotes to double quotes..."
        bottommenu_items=$(echo "$bottommenu_items" | sed "s/'/\"/g")
        
        # Debug: Show the JSON after preprocessing
        log_info "🔍 Preprocessed JSON: '$bottommenu_items'"
        
        # Validate the preprocessed JSON
        if ! echo "$bottommenu_items" | python3 -m json.tool >/dev/null 2>&1; then
            log_warning "⚠️ BOTTOMMENU_ITEMS is still not valid JSON after preprocessing, setting to empty array"
            bottommenu_items="[]"
        else
            log_info "✅ BOTTOMMENU_ITEMS is now valid JSON after preprocessing"
            
            # Debug: Show the JSON after validation
            log_info "🔍 JSON validation passed, length: ${#bottommenu_items}"
            
            # Debug: Show a preview of the JSON structure
            log_info "🔍 JSON preview: $(echo "$bottommenu_items" | cut -c1-50)..."
        fi
    else
        log_info "ℹ️ BOTTOMMENU_ITEMS is empty or already empty array, using default"
    fi
    local bottommenu_bg_color=$(get_env_var "BOTTOMMENU_BG_COLOR")
    local bottommenu_icon_color=$(get_env_var "BOTTOMMENU_ICON_COLOR")
    local bottommenu_text_color=$(get_env_var "BOTTOMMENU_TEXT_COLOR")
    local bottommenu_font=$(get_env_var "BOTTOMMENU_FONT")
    local bottommenu_font_size=$(get_env_var "BOTTOMMENU_FONT_SIZE")
    local bottommenu_active_tab_color=$(get_env_var "BOTTOMMENU_ACTIVE_TAB_COLOR")
    local bottommenu_icon_position=$(get_env_var "BOTTOMMENU_ICON_POSITION")
    local bottommenu_visible_on=$(get_env_var "BOTTOMMENU_VISIBLE_ON")
    local firebase_config_android=$(get_env_var "FIREBASE_CONFIG_ANDROID")
    local firebase_config_ios=$(get_env_var "FIREBASE_CONFIG_IOS")
    
    # Ensure Firebase configs are valid URLs or empty strings
    if [[ -n "$firebase_config_android" && ! "$firebase_config_android" =~ ^https?:// ]]; then
        log_warning "⚠️ FIREBASE_CONFIG_ANDROID is not a valid URL, setting to empty"
        firebase_config_android=""
    fi
    if [[ -n "$firebase_config_ios" && ! "$firebase_config_ios" =~ ^https?:// ]]; then
        log_warning "⚠️ FIREBASE_CONFIG_IOS is not a valid URL, setting to empty"
        firebase_config_ios=""
    fi
    
    # Ensure all variables are properly initialized
    firebase_config_android="${firebase_config_android:-}"
    firebase_config_ios="${firebase_config_ios:-}"
    local key_store_url=$(get_env_var "KEY_STORE_URL")
    local cm_keystore_password=$(get_env_var "CM_KEYSTORE_PASSWORD")
    local cm_key_alias=$(get_env_var "CM_KEY_ALIAS")
    local cm_key_password=$(get_env_var "CM_KEY_PASSWORD")
    
    # iOS-specific variables (only include if workflow is iOS-related)
    local apple_team_id=""
    local apns_key_id=""
    local apns_auth_key_url=""
    local cert_type=""
    local cert_password=""
    local profile_url=""
    local cert_p12_url=""
    local cert_cer_url=""
    local cert_key_url=""
    local profile_type=""
    local app_store_connect_key_identifier=""
    local app_store_connect_issuer_id=""
    local app_store_connect_api_key_url=""
    local is_testflight=""
    local upload_to_app_store=""
    
    # Only include iOS variables if this is an iOS or combined workflow
    if [[ "$workflow_id" == *"ios"* || "$workflow_id" == "combined" ]]; then
        log_info "📱 iOS workflow detected, including iOS-specific variables"
        apple_team_id=$(get_env_var "APPLE_TEAM_ID")
        apns_key_id=$(get_env_var "APNS_KEY_ID")
        apns_auth_key_url=$(get_env_var "APNS_AUTH_KEY_URL")
        cert_type=$(get_env_var "CERT_TYPE")
        cert_password=$(get_env_var "CERT_PASSWORD")
        profile_url=$(get_env_var "PROFILE_URL")
        cert_p12_url=$(get_env_var "CERT_P12_URL")
        cert_cer_url=$(get_env_var "CERT_CER_URL")
        cert_key_url=$(get_env_var "CERT_KEY_URL")
        profile_type=$(get_env_var "PROFILE_TYPE")
        app_store_connect_key_identifier=$(get_env_var "APP_STORE_CONNECT_KEY_IDENTIFIER")
        app_store_connect_issuer_id=$(get_env_var "APP_STORE_CONNECT_ISSUER_ID")
        app_store_connect_api_key_url=$(get_env_var "APP_STORE_CONNECT_API_KEY_URL")
        is_testflight=$(get_env_var "IS_TESTFLIGHT")
        upload_to_app_store=$(get_env_var "UPLOAD_TO_APP_STORE")
    else
        log_info "🤖 Android-only workflow detected, skipping iOS-specific variables"
        # Set empty defaults for iOS variables to avoid undefined errors
        apple_team_id=""
        apns_key_id=""
        apns_auth_key_url=""
        cert_type=""
        cert_password=""
        profile_url=""
        cert_p12_url=""
        cert_cer_url=""
        cert_key_url=""
        profile_type=""
        app_store_connect_key_identifier=""
        app_store_connect_issuer_id=""
        app_store_connect_api_key_url=""
        is_testflight="false"
        upload_to_app_store="false"
    fi
    
    # Convert booleans safely
    local bool_push_notify=$(to_bool "$(get_env_var "PUSH_NOTIFY")")
    local bool_is_chatbot=$(to_bool "$(get_env_var "IS_CHATBOT")")
    local bool_is_domain_url=$(to_bool "$(get_env_var "IS_DOMAIN_URL")")
    local bool_is_splash=$(to_bool "$(get_env_var "IS_SPLASH")")
    local bool_is_pulldown=$(to_bool "$(get_env_var "IS_PULLDOWN")")
    local bool_is_bottommenu=$(to_bool "$(get_env_var "IS_BOTTOMMENU")")
    local bool_is_load_ind=$(to_bool "$(get_env_var "IS_LOAD_IND")")
    local bool_is_camera=$(to_bool "$(get_env_var "IS_CAMERA")")
    local bool_is_location=$(to_bool "$(get_env_var "IS_LOCATION")")
    local bool_is_mic=$(to_bool "$(get_env_var "IS_MIC")")
    local bool_is_notification=$(to_bool "$(get_env_var "IS_NOTIFICATION")")
    local bool_is_contact=$(to_bool "$(get_env_var "IS_CONTACT")")
    local bool_is_biometric=$(to_bool "$(get_env_var "IS_BIOMETRIC")")
    local bool_is_calendar=$(to_bool "$(get_env_var "IS_CALENDAR")")
    local bool_is_storage=$(to_bool "$(get_env_var "IS_STORAGE")")
    local bool_is_google_auth=$(to_bool "$(get_env_var "IS_GOOGLE_AUTH")")
    local bool_is_apple_auth=$(to_bool "$(get_env_var "IS_APPLE_AUTH")")
    local bool_splash_tagline_bold=$(to_bool "$(get_env_var "SPLASH_TAGLINE_BOLD")")
    local bool_splash_tagline_italic=$(to_bool "$(get_env_var "SPLASH_TAGLINE_ITALIC")")
    local bool_bottommenu_font_bold=$(to_bool "$(get_env_var "BOTTOMMENU_FONT_BOLD")")
    local bool_bottommenu_font_italic=$(to_bool "$(get_env_var "BOTTOMMENU_FONT_ITALIC")")
    local bool_enable_email_notifications=$(to_bool "$(get_env_var "ENABLE_EMAIL_NOTIFICATIONS")")

    # Convert numbers safely
    local num_version_code=$(to_number "$version_code")
    local num_splash_duration=$(to_number "$splash_duration")
    local num_bottommenu_font_size=$(to_number "$bottommenu_font_size")
    local num_email_smtp_port=$(to_number "$(get_env_var "EMAIL_SMTP_PORT")")
    local num_xcode_parallel_jobs=$(to_number "$(get_env_var "XCODE_PARALLEL_JOBS")")

    # Escape all string values
    local safe_project_id=$(escape_string "$project_id")
    local safe_app_id=$(escape_string "$app_id")
    local safe_version_name=$(escape_string "$version_name")
    local safe_app_name=$(escape_string "$app_name")
    local safe_org_name=$(escape_string "$org_name")
    local safe_web_url=$(escape_string "$web_url")
    local safe_user_name=$(escape_string "$user_name")
    local safe_email_id=$(escape_string "$email_id")
    local safe_workflow_id=$(escape_string "$workflow_id")
    local safe_pkg_name=$(escape_string "$pkg_name")
    local safe_bundle_id=$(escape_string "$bundle_id")
    local safe_logo_url=$(escape_string "$logo_url")
    local safe_splash_url=$(escape_string "$splash_url")
    local safe_splash_bg=$(escape_string "$splash_bg")
    local safe_splash_bg_color=$(escape_string "$splash_bg_color")
    local safe_splash_tagline=$(escape_string "$splash_tagline")
    local safe_splash_tagline_color=$(escape_string "$splash_tagline_color")
    local safe_splash_tagline_font=$(escape_string "$splash_tagline_font")
    local safe_splash_tagline_size=$(escape_string "$splash_tagline_size")
    local safe_splash_animation=$(escape_string "$splash_animation")
    local safe_bottommenu_items=$(escape_json_for_dart "$bottommenu_items")
    
    # Debug: Show the JSON escaping process
    if [[ -n "$bottommenu_items" && "$bottommenu_items" != "[]" ]]; then
        log_info "🔍 JSON escaping process:"
        log_info "   Original: '$bottommenu_items'"
        log_info "   Escaped: '$safe_bottommenu_items'"
        log_info "   Escaped length: ${#safe_bottommenu_items}"
    fi
    local safe_bottommenu_bg_color=$(escape_string "$bottommenu_bg_color")
    local safe_bottommenu_icon_color=$(escape_string "$bottommenu_icon_color")
    local safe_bottommenu_text_color=$(escape_string "$bottommenu_text_color")
    local safe_bottommenu_font=$(escape_string "$bottommenu_font")
    local safe_bottommenu_active_tab_color=$(escape_string "$bottommenu_active_tab_color")
    local safe_bottommenu_icon_position=$(escape_string "$bottommenu_icon_position")
    local safe_bottommenu_visible_on=$(escape_string "$bottommenu_visible_on")
    local safe_firebase_config_android=$(escape_string "$firebase_config_android")
    local safe_firebase_config_ios=$(escape_string "$firebase_config_ios")
    
    # Debug Firebase config values
    log_info "Firebase Android Config: '$firebase_config_android' -> '$safe_firebase_config_android'"
    log_info "Firebase iOS Config: '$firebase_config_ios' -> '$safe_firebase_config_ios'"
    
    # Ensure all variables are properly escaped and safe
    if [[ -z "$safe_firebase_config_android" ]]; then
        safe_firebase_config_android=""
    fi
    if [[ -z "$safe_firebase_config_ios" ]]; then
        safe_firebase_config_ios=""
    fi
    local safe_key_store_url=$(escape_string "$key_store_url")
    local safe_cm_keystore_password=$(escape_string "$cm_keystore_password")
    local safe_cm_key_alias=$(escape_string "$cm_key_alias")
    local safe_cm_key_password=$(escape_string "$cm_key_password")
    local safe_apple_team_id=$(escape_string "$apple_team_id")
    local safe_apns_key_id=$(escape_string "$apns_key_id")
    local safe_apns_auth_key_url=$(escape_string "$apns_auth_key_url")
    local safe_cert_type=$(escape_string "$cert_type")
    local safe_cert_password=$(escape_string "$cert_password")
    local safe_profile_url=$(escape_string "$profile_url")
    local safe_cert_p12_url=$(escape_string "$cert_p12_url")
    local safe_cert_cer_url=$(escape_string "$cert_cer_url")
    local safe_cert_key_url=$(escape_string "$cert_key_url")
    local safe_profile_type=$(escape_string "$profile_type")
    local safe_app_store_connect_key_identifier=$(escape_string "$app_store_connect_key_identifier")
    local safe_app_store_connect_issuer_id=$(escape_string "$app_store_connect_issuer_id")
    local safe_app_store_connect_api_key_url=$(escape_string "$app_store_connect_api_key_url")
    local safe_is_testflight=$(escape_string "$is_testflight")
    local safe_upload_to_app_store=$(escape_string "$upload_to_app_store")
    local safe_email_smtp_server=$(escape_string "$(get_env_var "EMAIL_SMTP_SERVER")")
    local safe_email_smtp_user=$(escape_string "$(get_env_var "EMAIL_SMTP_USER")")
    local safe_email_smtp_pass=$(escape_string "$(get_env_var "EMAIL_SMTP_PASS")")
    local safe_build_id=$(escape_string "$(get_env_var "BUILD_ID")")
    local safe_build_dir=$(escape_string "$(get_env_var "BUILD_DIR")")
    local safe_project_root=$(escape_string "$(get_env_var "PROJECT_ROOT")")
    local safe_output_dir=$(escape_string "$(get_env_var "OUTPUT_DIR")")
    local safe_gradle_opts=$(escape_string "$(get_env_var "GRADLE_OPTS")")
    local safe_flutter_build_args=$(escape_string "$(get_env_var "FLUTTER_BUILD_ARGS")")

    # Generate the Dart file to a temporary location first
    log_info "🔧 Generating Dart configuration file..."
    
    # Create temporary file with atomic write protection
    local temp_file="lib/config/env_config.dart.tmp.$$"
    local final_file="lib/config/env_config.dart"
    
    # Ensure we can write to the temp file
    if ! touch "$temp_file" 2>/dev/null; then
        log_error "❌ Cannot create temporary file, check permissions"
        return 1
    fi
    
    # Generate content to temporary file
    cat > "$temp_file" << 'EOF'
// GENERATED FILE: DO NOT EDIT
//
// This file is generated by lib/scripts/utils/gen_env_config.sh
// It contains all environment-specific variables for the app.

class EnvConfig {
  // App Metadata
  static const String projectId = "PROJECT_ID_PLACEHOLDER";
  static const String appId = "APP_ID_PLACEHOLDER";
  static const String versionName = "VERSION_NAME_PLACEHOLDER";
  static const int versionCode = VERSION_CODE_PLACEHOLDER;
  static const String appName = "APP_NAME_PLACEHOLDER";
  static const String orgName = "ORG_NAME_PLACEHOLDER";
  static const String webUrl = "WEB_URL_PLACEHOLDER";
  static const String userName = "USER_NAME_PLACEHOLDER";
  static const String emailId = "EMAIL_ID_PLACEHOLDER";
  static const String branch = "main";
  static const String workflowId = "WORKFLOW_ID_PLACEHOLDER";

  // Package Identifiers
  static const String pkgName = "PKG_NAME_PLACEHOLDER";
EOF

    # Add bundleId only for iOS/combined workflows
    if [[ "$workflow_id" == *"ios"* || "$workflow_id" == "combined" ]]; then
        cat >> "$temp_file" << 'EOF'
  static const String bundleId = "BUNDLE_ID_PLACEHOLDER";
EOF
    else
        cat >> "$temp_file" << 'EOF'
  static const String bundleId = ""; // Bundle ID not available for Android-only builds
EOF
    fi

    cat >> "$temp_file" << 'EOF'

  // Feature Flags (converted to bool)
  static const bool pushNotify = PUSH_NOTIFY_PLACEHOLDER;
  static const bool isChatbot = IS_CHATBOT_PLACEHOLDER;
  static const bool isDomainUrl = IS_DOMAIN_URL_PLACEHOLDER;
  static const bool isSplash = IS_SPLASH_PLACEHOLDER;
  static const bool isPulldown = IS_PULLDOWN_PLACEHOLDER;
  static const bool isBottommenu = IS_BOTTOMMENU_PLACEHOLDER;
  static const bool isLoadIndicator = IS_LOAD_IND_PLACEHOLDER;

  // Permissions (converted to bool)
  static const bool isCamera = IS_CAMERA_PLACEHOLDER;
  static const bool isLocation = IS_LOCATION_PLACEHOLDER;
  static const bool isMic = IS_MIC_PLACEHOLDER;
  static const bool isNotification = IS_NOTIFICATION_PLACEHOLDER;
  static const bool isContact = IS_CONTACT_PLACEHOLDER;
  static const bool isBiometric = IS_BIOMETRIC_PLACEHOLDER;
  static const bool isCalendar = IS_CALENDAR_PLACEHOLDER;
  static const bool isStorage = IS_STORAGE_PLACEHOLDER;

  // OAuth Authentication
  static const bool isGoogleAuth = IS_GOOGLE_AUTH_PLACEHOLDER;
  static const bool isAppleAuth = IS_APPLE_AUTH_PLACEHOLDER;

  // UI/Branding
  static const String logoUrl = "LOGO_URL_PLACEHOLDER";
  static const String splashUrl = "SPLASH_URL_PLACEHOLDER";
  static const String splashBg = "SPLASH_BG_PLACEHOLDER";
  static const String splashBgColor = "SPLASH_BG_COLOR_PLACEHOLDER";
  static const String splashTagline = "SPLASH_TAGLINE_PLACEHOLDER";
  static const String splashTaglineColor = "SPLASH_TAGLINE_COLOR_PLACEHOLDER";
  static const String splashTaglineFont = "SPLASH_TAGLINE_FONT_PLACEHOLDER";
  static const String splashTaglineSize = "SPLASH_TAGLINE_SIZE_PLACEHOLDER";
  static const bool splashTaglineBold = SPLASH_TAGLINE_BOLD_PLACEHOLDER;
  static const bool splashTaglineItalic = SPLASH_TAGLINE_ITALIC_PLACEHOLDER;
  static const String splashAnimation = "SPLASH_ANIMATION_PLACEHOLDER";
  static const int splashDuration = SPLASH_DURATION_PLACEHOLDER;

  // Bottom Menu Configuration
  static const String bottommenuItems = BOTTOMMENU_ITEMS_PLACEHOLDER;
  static const String bottommenuBgColor = "BOTTOMMENU_BG_COLOR_PLACEHOLDER";
  static const String bottommenuIconColor = "BOTTOMMENU_ICON_COLOR_PLACEHOLDER";
  static const String bottommenuTextColor = "BOTTOMMENU_TEXT_COLOR_PLACEHOLDER";
  static const String bottommenuFont = "BOTTOMMENU_FONT_PLACEHOLDER";
  static const double bottommenuFontSize = BOTTOMMENU_FONT_SIZE_PLACEHOLDER;
  static const bool bottommenuFontBold = BOTTOMMENU_FONT_BOLD_PLACEHOLDER;
  static const bool bottommenuFontItalic = BOTTOMMENU_FONT_ITALIC_PLACEHOLDER;
  static const String bottommenuActiveTabColor = "BOTTOMMENU_ACTIVE_TAB_COLOR_PLACEHOLDER";
  static const String bottommenuIconPosition = "BOTTOMMENU_ICON_POSITION_PLACEHOLDER";
  static const String bottommenuVisibleOn = "BOTTOMMENU_VISIBLE_ON_PLACEHOLDER";

  // Firebase Configuration
  static const String firebaseConfigAndroid = "FIREBASE_CONFIG_ANDROID_PLACEHOLDER";
  static const String firebaseConfigIos = "FIREBASE_CONFIG_IOS_PLACEHOLDER";

  // Android Signing
  static const String keyStoreUrl = "KEY_STORE_URL_PLACEHOLDER";
  static const String cmKeystorePassword = "CM_KEYSTORE_PASSWORD_PLACEHOLDER";
  static const String cmKeyAlias = "CM_KEY_ALIAS_PLACEHOLDER";
  static const String cmKeyPassword = "CM_KEY_PASSWORD_PLACEHOLDER";
EOF

    # Add iOS signing section only if this is an iOS or combined workflow
    if [[ "$workflow_id" == *"ios"* || "$workflow_id" == "combined" ]]; then
        cat >> "$temp_file" << 'EOF'

  // iOS Signing
  static const String appleTeamId = "APPLE_TEAM_ID_PLACEHOLDER";
  static const String apnsKeyId = "APNS_KEY_ID_PLACEHOLDER";
  static const String apnsAuthKeyUrl = "APNS_AUTH_KEY_URL_PLACEHOLDER";
  static const String certType = "CERT_TYPE_PLACEHOLDER";
  static const String certPassword = "CERT_PASSWORD_PLACEHOLDER";
  static const String profileUrl = "PROFILE_URL_PLACEHOLDER";
  static const String certP12Url = "CERT_P12_URL_PLACEHOLDER";
  static const String certCerUrl = "CERT_CER_URL_PLACEHOLDER";
  static const String certKeyUrl = "CERT_KEY_URL_PLACEHOLDER";
  static const String profileType = "PROFILE_TYPE_PLACEHOLDER";
  static const String appStoreConnectKeyIdentifier = "APP_STORE_CONNECT_KEY_IDENTIFIER_PLACEHOLDER";
  static const String appStoreConnectIssuerId = "APP_STORE_CONNECT_ISSUER_ID_PLACEHOLDER";
  static const String appStoreConnectApiKeyUrl = "APP_STORE_CONNECT_API_KEY_URL_PLACEHOLDER";
  static const bool isTestFlight = IS_TESTFLIGHT_PLACEHOLDER;
  static const bool uploadToAppStore = UPLOAD_TO_APP_STORE_PLACEHOLDER;
EOF
    fi

    # Continue with the rest of the file
    cat >> "$temp_file" << 'EOF'

  // Email Configuration
  static const bool enableEmailNotifications = ENABLE_EMAIL_NOTIFICATIONS_PLACEHOLDER;
  static const String emailSmtpServer = "EMAIL_SMTP_SERVER_PLACEHOLDER";
  static const int emailSmtpPort = EMAIL_SMTP_PORT_PLACEHOLDER;
  static const String emailSmtpUser = "EMAIL_SMTP_USER_PLACEHOLDER";
  static const String emailSmtpPass = "EMAIL_SMTP_PASS_PLACEHOLDER";

  // Build Environment
  static const String buildId = "BUILD_ID_PLACEHOLDER";
  static const String buildDir = "BUILD_DIR_PLACEHOLDER";
  static const String projectRoot = "PROJECT_ROOT_PLACEHOLDER";
  static const String outputDir = "OUTPUT_DIR_PLACEHOLDER";

  // Memory and Performance Settings
  static const String gradleOpts = "GRADLE_OPTS_PLACEHOLDER";
  static const int xcodeParallelJobs = XCODE_PARALLEL_JOBS_PLACEHOLDER;
  static const String flutterBuildArgs = "FLUTTER_BUILD_ARGS_PLACEHOLDER";

  // Utility Methods
  static bool get isAndroidBuild => workflowId.startsWith('android');
  static bool get isIosBuild => workflowId.contains('ios');
  static bool get isCombinedBuild => workflowId == 'combined';
  static bool get hasFirebase => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
  static bool get hasKeystore => keyStoreUrl.isNotEmpty;
EOF

    # Add iOS-specific utility methods only for iOS/combined workflows
    if [[ "$workflow_id" == *"ios"* || "$workflow_id" == "combined" ]]; then
        cat >> "$temp_file" << 'EOF'
  static bool get hasIosSigning => certPassword.isNotEmpty && profileUrl.isNotEmpty;
EOF
    else
        cat >> "$temp_file" << 'EOF'
  static bool get hasIosSigning => false; // iOS signing not available for Android-only builds
EOF
    fi

    cat >> "$temp_file" << 'EOF'
}
EOF

    # Replace placeholders with actual values
    log_info "🔄 Replacing placeholders with actual values..."
    
    # App Metadata
    cross_platform_sed "PROJECT_ID_PLACEHOLDER" "$safe_project_id" "$temp_file"
    cross_platform_sed "APP_ID_PLACEHOLDER" "$safe_app_id" "$temp_file"
    cross_platform_sed "VERSION_NAME_PLACEHOLDER" "$safe_version_name" "$temp_file"
    cross_platform_sed "VERSION_CODE_PLACEHOLDER" "$num_version_code" "$temp_file"
    cross_platform_sed "APP_NAME_PLACEHOLDER" "$safe_app_name" "$temp_file"
    cross_platform_sed "ORG_NAME_PLACEHOLDER" "$safe_org_name" "$temp_file"
    cross_platform_sed "WEB_URL_PLACEHOLDER" "$safe_web_url" "$temp_file"
    cross_platform_sed "USER_NAME_PLACEHOLDER" "$safe_user_name" "$temp_file"
    cross_platform_sed "EMAIL_ID_PLACEHOLDER" "$safe_email_id" "$temp_file"
    cross_platform_sed "WORKFLOW_ID_PLACEHOLDER" "$safe_workflow_id" "$temp_file"
    cross_platform_sed "PKG_NAME_PLACEHOLDER" "$safe_pkg_name" "$temp_file"
    
    # Bundle ID (only for iOS/combined workflows)
    if [[ "$workflow_id" == *"ios"* || "$workflow_id" == "combined" ]]; then
        cross_platform_sed "BUNDLE_ID_PLACEHOLDER" "$safe_bundle_id" "$temp_file"
    fi
    
    # Feature Flags
    cross_platform_sed "PUSH_NOTIFY_PLACEHOLDER" "$bool_push_notify" "$temp_file"
    cross_platform_sed "IS_CHATBOT_PLACEHOLDER" "$bool_is_chatbot" "$temp_file"
    cross_platform_sed "IS_DOMAIN_URL_PLACEHOLDER" "$bool_is_domain_url" "$temp_file"
    cross_platform_sed "IS_SPLASH_PLACEHOLDER" "$bool_is_splash" "$temp_file"
    cross_platform_sed "IS_PULLDOWN_PLACEHOLDER" "$bool_is_pulldown" "$temp_file"
    cross_platform_sed "IS_BOTTOMMENU_PLACEHOLDER" "$bool_is_bottommenu" "$temp_file"
    cross_platform_sed "IS_LOAD_IND_PLACEHOLDER" "$bool_is_load_ind" "$temp_file"
    
    # Permissions
    cross_platform_sed "IS_CAMERA_PLACEHOLDER" "$bool_is_camera" "$temp_file"
    cross_platform_sed "IS_LOCATION_PLACEHOLDER" "$bool_is_location" "$temp_file"
    cross_platform_sed "IS_MIC_PLACEHOLDER" "$bool_is_mic" "$temp_file"
    cross_platform_sed "IS_NOTIFICATION_PLACEHOLDER" "$bool_is_notification" "$temp_file"
    cross_platform_sed "IS_CONTACT_PLACEHOLDER" "$bool_is_contact" "$temp_file"
    cross_platform_sed "IS_BIOMETRIC_PLACEHOLDER" "$bool_is_biometric" "$temp_file"
    cross_platform_sed "IS_CALENDAR_PLACEHOLDER" "$bool_is_calendar" "$temp_file"
    cross_platform_sed "IS_STORAGE_PLACEHOLDER" "$bool_is_storage" "$temp_file"
    
    # OAuth
    cross_platform_sed "IS_GOOGLE_AUTH_PLACEHOLDER" "$bool_is_google_auth" "$temp_file"
    cross_platform_sed "IS_APPLE_AUTH_PLACEHOLDER" "$bool_is_apple_auth" "$temp_file"
    
    # UI/Branding
    cross_platform_sed "LOGO_URL_PLACEHOLDER" "$safe_logo_url" "$temp_file"
    cross_platform_sed "SPLASH_URL_PLACEHOLDER" "$safe_splash_url" "$temp_file"
    cross_platform_sed "SPLASH_BG_PLACEHOLDER" "$safe_splash_bg" "$temp_file"
    cross_platform_sed "SPLASH_BG_COLOR_PLACEHOLDER" "$safe_splash_bg_color" "$temp_file"
    cross_platform_sed "SPLASH_TAGLINE_PLACEHOLDER" "$safe_splash_tagline" "$temp_file"
    cross_platform_sed "SPLASH_TAGLINE_COLOR_PLACEHOLDER" "$safe_splash_tagline_color" "$temp_file"
    cross_platform_sed "SPLASH_TAGLINE_FONT_PLACEHOLDER" "$safe_splash_tagline_font" "$temp_file"
    cross_platform_sed "SPLASH_TAGLINE_SIZE_PLACEHOLDER" "$safe_splash_tagline_size" "$temp_file"
    cross_platform_sed "SPLASH_TAGLINE_BOLD_PLACEHOLDER" "$bool_splash_tagline_bold" "$temp_file"
    cross_platform_sed "SPLASH_TAGLINE_ITALIC_PLACEHOLDER" "$bool_splash_tagline_italic" "$temp_file"
    cross_platform_sed "SPLASH_ANIMATION_PLACEHOLDER" "$safe_splash_animation" "$temp_file"
    cross_platform_sed "SPLASH_DURATION_PLACEHOLDER" "$num_splash_duration" "$temp_file"
    
    # Bottom Menu
    cross_platform_sed "BOTTOMMENU_ITEMS_PLACEHOLDER" "\"$safe_bottommenu_items\"" "$temp_file"
    cross_platform_sed "BOTTOMMENU_BG_COLOR_PLACEHOLDER" "$safe_bottommenu_bg_color" "$temp_file"
    cross_platform_sed "BOTTOMMENU_ICON_COLOR_PLACEHOLDER" "$safe_bottommenu_icon_color" "$temp_file"
    cross_platform_sed "BOTTOMMENU_TEXT_COLOR_PLACEHOLDER" "$safe_bottommenu_text_color" "$temp_file"
    cross_platform_sed "BOTTOMMENU_FONT_PLACEHOLDER" "$safe_bottommenu_font" "$temp_file"
    cross_platform_sed "BOTTOMMENU_FONT_SIZE_PLACEHOLDER" "$num_bottommenu_font_size" "$temp_file"
    cross_platform_sed "BOTTOMMENU_FONT_BOLD_PLACEHOLDER" "$bool_bottommenu_font_bold" "$temp_file"
    cross_platform_sed "BOTTOMMENU_FONT_ITALIC_PLACEHOLDER" "$bool_bottommenu_font_italic" "$temp_file"
    cross_platform_sed "BOTTOMMENU_ACTIVE_TAB_COLOR_PLACEHOLDER" "$safe_bottommenu_active_tab_color" "$temp_file"
    cross_platform_sed "BOTTOMMENU_ICON_POSITION_PLACEHOLDER" "$safe_bottommenu_icon_position" "$temp_file"
    cross_platform_sed "BOTTOMMENU_VISIBLE_ON_PLACEHOLDER" "$safe_bottommenu_visible_on" "$temp_file"
    
    # Firebase
    cross_platform_sed "FIREBASE_CONFIG_ANDROID_PLACEHOLDER" "$safe_firebase_config_android" "$temp_file"
    cross_platform_sed "FIREBASE_CONFIG_IOS_PLACEHOLDER" "$safe_firebase_config_ios" "$temp_file"
    
    # Android Signing
    cross_platform_sed "KEY_STORE_URL_PLACEHOLDER" "$safe_key_store_url" "$temp_file"
    cross_platform_sed "CM_KEYSTORE_PASSWORD_PLACEHOLDER" "$safe_cm_keystore_password" "$temp_file"
    cross_platform_sed "CM_KEY_ALIAS_PLACEHOLDER" "$safe_cm_key_alias" "$temp_file"
    cross_platform_sed "CM_KEY_PASSWORD_PLACEHOLDER" "$safe_cm_key_password" "$temp_file"
    
    # iOS Signing (only for iOS/combined workflows)
    if [[ "$workflow_id" == *"ios"* || "$workflow_id" == "combined" ]]; then
        cross_platform_sed "APPLE_TEAM_ID_PLACEHOLDER" "$safe_apple_team_id" "$temp_file"
        cross_platform_sed "APNS_KEY_ID_PLACEHOLDER" "$safe_apns_key_id" "$temp_file"
        cross_platform_sed "APNS_AUTH_KEY_URL_PLACEHOLDER" "$safe_apns_auth_key_url" "$temp_file"
        cross_platform_sed "CERT_TYPE_PLACEHOLDER" "$safe_cert_type" "$temp_file"
        cross_platform_sed "CERT_PASSWORD_PLACEHOLDER" "$safe_cert_password" "$temp_file"
        cross_platform_sed "PROFILE_URL_PLACEHOLDER" "$safe_profile_url" "$temp_file"
        cross_platform_sed "CERT_P12_URL_PLACEHOLDER" "$safe_cert_p12_url" "$temp_file"
        cross_platform_sed "CERT_CER_URL_PLACEHOLDER" "$safe_cert_cer_url" "$temp_file"
        cross_platform_sed "CERT_KEY_URL_PLACEHOLDER" "$safe_cert_key_url" "$temp_file"
        cross_platform_sed "PROFILE_TYPE_PLACEHOLDER" "$safe_profile_type" "$temp_file"
        cross_platform_sed "APP_STORE_CONNECT_KEY_IDENTIFIER_PLACEHOLDER" "$safe_app_store_connect_key_identifier" "$temp_file"
        cross_platform_sed "APP_STORE_CONNECT_ISSUER_ID_PLACEHOLDER" "$safe_app_store_connect_issuer_id" "$temp_file"
        cross_platform_sed "APP_STORE_CONNECT_API_KEY_URL_PLACEHOLDER" "$safe_app_store_connect_api_key_url" "$temp_file"
        cross_platform_sed "IS_TESTFLIGHT_PLACEHOLDER" "$safe_is_testflight" "$temp_file"
        cross_platform_sed "UPLOAD_TO_APP_STORE_PLACEHOLDER" "$safe_upload_to_app_store" "$temp_file"
    fi
    
    # Email Configuration
    cross_platform_sed "ENABLE_EMAIL_NOTIFICATIONS_PLACEHOLDER" "$bool_enable_email_notifications" "$temp_file"
    cross_platform_sed "EMAIL_SMTP_SERVER_PLACEHOLDER" "$safe_email_smtp_server" "$temp_file"
    cross_platform_sed "EMAIL_SMTP_PORT_PLACEHOLDER" "$num_email_smtp_port" "$temp_file"
    cross_platform_sed "EMAIL_SMTP_USER_PLACEHOLDER" "$safe_email_smtp_user" "$temp_file"
    cross_platform_sed "EMAIL_SMTP_PASS_PLACEHOLDER" "$safe_email_smtp_pass" "$temp_file"
    
    # Build Environment
    cross_platform_sed "BUILD_ID_PLACEHOLDER" "$safe_build_id" "$temp_file"
    cross_platform_sed "BUILD_DIR_PLACEHOLDER" "$safe_build_dir" "$temp_file"
    cross_platform_sed "PROJECT_ROOT_PLACEHOLDER" "$safe_project_root" "$temp_file"
    cross_platform_sed "OUTPUT_DIR_PLACEHOLDER" "$safe_output_dir" "$temp_file"
    
    # Memory and Performance Settings
    cross_platform_sed "GRADLE_OPTS_PLACEHOLDER" "$safe_gradle_opts" "$temp_file"
    cross_platform_sed "XCODE_PARALLEL_JOBS_PLACEHOLDER" "$num_xcode_parallel_jobs" "$temp_file"
    cross_platform_sed "FLUTTER_BUILD_ARGS_PLACEHOLDER" "$safe_flutter_build_args" "$temp_file"

    # Move the temporary file to the final location
    if [[ -f "$temp_file" ]]; then
        # Atomic move operation
        if mv "$temp_file" "$final_file" 2>/dev/null; then
            log_success "✅ File generated successfully"
        else
            log_error "❌ Failed to move temporary file to final location"
            # Clean up temp file
            rm -f "$temp_file" 2>/dev/null || true
            return 1
        fi
    else
        log_error "❌ Temporary file not found, generation failed"
        return 1
    fi
    
    # Clean up any remaining temporary files
    find lib/config -name "*.tmp.*" -delete 2>/dev/null || true

    log_success "Dart environment configuration generated successfully."
    
    # Validate the generated file
    log_info "Validating generated environment configuration..."
    if flutter analyze "$final_file" >/dev/null 2>&1; then
        log_success "✅ Environment configuration is valid Dart code"
    else
        log_error "❌ Environment configuration has syntax errors"
        log_info "Generated file content:"
        cat "$final_file"
        log_info "Flutter analyze output:"
        flutter analyze "$final_file"
        return 1
    fi
    
    # Show a preview of the generated file
log_info "Generated file preview:"
    head -20 "$final_file" | while IFS= read -r line; do
log_info "   $line"
    done

    # Skip validation - frontend handles validation before build starts
    log_info "Skipping validation (handled by frontend)"

    log_success "Environment configuration generated successfully"
}

# Main execution
generate_env_config