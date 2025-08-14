#!/bin/bash
# 📧 Custom Email Notification Script for iOS Workflow
# Sends detailed email notifications for different build statuses

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [EMAIL] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

# Source environment configuration
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../lib/config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
else
    log "Environment configuration file not found, using system environment variables"
fi

# Function to safely get environment variable with fallback
get_api_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        printf "%s" "$value"
    else
        printf "%s" "$fallback"
    fi
}

# Set email configuration variables
export ENABLE_EMAIL_NOTIFICATIONS=$(get_api_var "ENABLE_EMAIL_NOTIFICATIONS" "false")
export EMAIL_SMTP_SERVER=$(get_api_var "EMAIL_SMTP_SERVER" "")
export EMAIL_SMTP_PORT=$(get_api_var "EMAIL_SMTP_PORT" "587")
export EMAIL_SMTP_USER=$(get_api_var "EMAIL_SMTP_USER" "")
export EMAIL_SMTP_PASS=$(get_api_var "EMAIL_SMTP_PASS" "")
export EMAIL_ID=$(get_api_var "EMAIL_ID" "admin@example.com")
export APP_NAME=$(get_api_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_api_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_api_var "VERSION_CODE" "1")
export BUNDLE_ID=$(get_api_var "BUNDLE_ID" "com.example.quikapp")
export WORKFLOW_ID=$(get_api_var "WORKFLOW_ID" "ios-workflow")
export PUSH_NOTIFY=$(get_api_var "PUSH_NOTIFY" "false")
export IS_TESTFLIGHT=$(get_api_var "IS_TESTFLIGHT" "false")

# Function to check if email notifications are enabled
is_email_enabled() {
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -n "$EMAIL_SMTP_SERVER" ] && [ -n "$EMAIL_SMTP_USER" ] && [ -n "$EMAIL_SMTP_PASS" ]; then
        return 0
    else
        return 1
    fi
}

# Function to create email content based on status
create_email_content() {
    local status="$1"
    local subject="$2"
    local build_info="$3"
    local additional_info="$4"
    
    local email_body=""
    
    case "$status" in
        "started")
            email_body="🚀 iOS Build Started
            
Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID
- Build Time: $(date)

Configuration:
- Push Notifications: $PUSH_NOTIFY
- TestFlight Upload: $IS_TESTFLIGHT
- Firebase Setup: $([ "$PUSH_NOTIFY" = "true" ] && echo "Enabled" || echo "Disabled")

Build Process:
$build_info

The build process has started and will notify you upon completion.

---
This is an automated notification from the iOS Workflow."
            ;;
            
        "success")
            email_body="✅ iOS Build Completed Successfully
            
Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID
- Build Time: $(date)

Build Results:
- IPA File: output/ios/Runner.ipa
- Build Status: SUCCESS
$build_info

Additional Information:
$additional_info

Build artifacts are available for download.

---
This is an automated notification from the iOS Workflow."
            ;;
            
        "failure")
            email_body="❌ iOS Build Failed
            
Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID
- Build Time: $(date)

Build Results:
- Build Status: FAILED
$build_info

Error Information:
$additional_info

Please check the build logs for more details.

---
This is an automated notification from the iOS Workflow."
            ;;
            
        "testflight_success")
            email_body="🚀 TestFlight Upload Successful
            
Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID
- Upload Time: $(date)

Upload Results:
- Upload Status: SUCCESS
- Processing Status: Submitted for Processing
- Estimated Processing Time: 5-30 minutes
$build_info

Next Steps:
1. Wait for processing to complete (5-30 minutes)
2. Check App Store Connect for build status
3. Add build to TestFlight testing group
4. Submit for Beta App Review (if required)

$additional_info

---
This is an automated notification from the iOS Workflow."
            ;;
            
        "testflight_failure")
            email_body="❌ TestFlight Upload Failed
            
Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID
- Upload Time: $(date)

Upload Results:
- Upload Status: FAILED
$build_info

Error Information:
$additional_info

Please check the upload logs and verify your App Store Connect API credentials.

---
This is an automated notification from the iOS Workflow."
            ;;
            
        *)
            email_body="📧 iOS Workflow Notification
            
Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID
- Time: $(date)

Status: $status
$build_info

$additional_info

---
This is an automated notification from the iOS Workflow."
            ;;
    esac
    
    echo "$email_body"
}

# Function to send email using different methods
send_email() {
    local subject="$1"
    local body="$2"
    local recipients="$3"
    
    log_info "Sending email notification..."
    log "Subject: $subject"
    log "Recipients: $recipients"
    
    # Method 1: Using mail command (if available)
    if command -v mail >/dev/null 2>&1; then
        log "Using mail command..."
        if echo -e "$body" | mail -s "$subject" \
            -S smtp="$EMAIL_SMTP_SERVER:$EMAIL_SMTP_PORT" \
            -S smtp-use-starttls \
            -S smtp-auth=login \
            -S smtp-auth-user="$EMAIL_SMTP_USER" \
            -S smtp-auth-password="$EMAIL_SMTP_PASS" \
            "$recipients" 2>/dev/null; then
            log_success "Email sent successfully using mail command"
            return 0
        else
            log_warning "Failed to send email using mail command"
        fi
    fi
    
    # Method 2: Using curl with SMTP (if mail command fails)
    if command -v curl >/dev/null 2>&1; then
        log "Using curl with SMTP..."
        # Create email content
        local email_content="From: $EMAIL_SMTP_USER
To: $recipients
Subject: $subject
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

$body"
        
        if curl --mail-from "$EMAIL_SMTP_USER" \
            --mail-rcpt "$recipients" \
            --upload-file <(echo -e "$email_content") \
            --ssl-reqd \
            --user "$EMAIL_SMTP_USER:$EMAIL_SMTP_PASS" \
            "smtp://$EMAIL_SMTP_SERVER:$EMAIL_SMTP_PORT" 2>/dev/null; then
            log_success "Email sent successfully using curl"
            return 0
        else
            log_warning "Failed to send email using curl"
        fi
    fi
    
    # Method 3: Using Python (if available)
    if command -v python3 >/dev/null 2>&1; then
        log "Using Python SMTP..."
        python3 -c "
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

msg = MIMEMultipart()
msg['From'] = '$EMAIL_SMTP_USER'
msg['To'] = '$recipients'
msg['Subject'] = '$subject'

body = '''$body'''
msg.attach(MIMEText(body, 'plain'))

try:
    server = smtplib.SMTP('$EMAIL_SMTP_SERVER', $EMAIL_SMTP_PORT)
    server.starttls()
    server.login('$EMAIL_SMTP_USER', '$EMAIL_SMTP_PASS')
    text = msg.as_string()
    server.sendmail('$EMAIL_SMTP_USER', '$recipients', text)
    server.quit()
    print('Email sent successfully')
except Exception as e:
    print(f'Failed to send email: {e}')
    exit(1)
" && log_success "Email sent successfully using Python" && return 0
    fi
    
    log_error "All email sending methods failed"
    return 1
}

# Function to get build information
get_build_info() {
    local info=""
    
    # Check if IPA exists
    if [ -f "output/ios/Runner.ipa" ]; then
        local ipa_size=$(stat -f%z "output/ios/Runner.ipa" 2>/dev/null || stat -c%s "output/ios/Runner.ipa" 2>/dev/null || echo "0")
        info+="- IPA File: output/ios/Runner.ipa ($ipa_size bytes)\n"
    fi
    
    # Check build summaries
    if [ -f "output/ios/WORKFLOW_SUMMARY.txt" ]; then
        info+="- Workflow Summary: Available\n"
    fi
    
    if [ -f "output/ios/ASSET_SUMMARY.txt" ]; then
        info+="- Asset Summary: Available\n"
    fi
    
    if [ "$PUSH_NOTIFY" = "true" ] && [ -f "output/ios/FIREBASE_SUMMARY.txt" ]; then
        info+="- Firebase Summary: Available\n"
    fi
    
    if [ "$IS_TESTFLIGHT" = "true" ] && [ -f "output/ios/TESTFLIGHT_SUMMARY.txt" ]; then
        info+="- TestFlight Summary: Available\n"
    fi
    
    echo -e "$info"
}

# Function to get additional information
get_additional_info() {
    local info=""
    
    # Environment information
    info+="Environment:\n"
    info+="- Workflow ID: $WORKFLOW_ID\n"
    info+="- Build Directory: $CM_BUILD_DIR\n"
    info+="- Build ID: $CM_BUILD_ID\n"
    
    # Feature flags
    info+="Features:\n"
    info+="- Push Notifications: $PUSH_NOTIFY\n"
    info+="- TestFlight Upload: $IS_TESTFLIGHT\n"
    info+="- Firebase Setup: $([ "$PUSH_NOTIFY" = "true" ] && echo "Enabled" || echo "Disabled")\n"
    
    echo -e "$info"
}

# Main function to send build status email
send_build_status_email() {
    local status="$1"
    local error_message="$2"
    
    if ! is_email_enabled; then
        log_info "Email notifications not enabled or missing configuration"
        return 0
    fi
    
    log_info "Preparing email notification for status: $status"
    
    # Create subject based on status
    local subject=""
    case "$status" in
        "started")
            subject="🚀 iOS Build Started - $APP_NAME v$VERSION_NAME"
            ;;
        "success")
            subject="✅ iOS Build Success - $APP_NAME v$VERSION_NAME"
            ;;
        "failure")
            subject="❌ iOS Build Failed - $APP_NAME v$VERSION_NAME"
            ;;
        "testflight_success")
            subject="🚀 TestFlight Upload Success - $APP_NAME v$VERSION_NAME"
            ;;
        "testflight_failure")
            subject="❌ TestFlight Upload Failed - $APP_NAME v$VERSION_NAME"
            ;;
        *)
            subject="📧 iOS Workflow Notification - $APP_NAME v$VERSION_NAME"
            ;;
    esac
    
    # Get build information
    local build_info=$(get_build_info)
    local additional_info=$(get_additional_info)
    
    # Add error message if provided
    if [ -n "$error_message" ]; then
        additional_info+="\nError Details:\n$error_message"
    fi
    
    # Create email content
    local email_body=$(create_email_content "$status" "$subject" "$build_info" "$additional_info")
    
    # Send email
    if send_email "$subject" "$email_body" "$EMAIL_ID"; then
        log_success "Build status email sent successfully"
        return 0
    else
        log_error "Failed to send build status email"
        return 1
    fi
}

# Function to send custom notification
send_custom_notification() {
    local subject="$1"
    local message="$2"
    local recipients="${3:-$EMAIL_ID}"
    
    if ! is_email_enabled; then
        log_info "Email notifications not enabled or missing configuration"
        return 0
    fi
    
    log_info "Sending custom notification..."
    
    if send_email "$subject" "$message" "$recipients"; then
        log_success "Custom notification sent successfully"
        return 0
    else
        log_error "Failed to send custom notification"
        return 1
    fi
}

# Function to create email summary
create_email_summary() {
    log_info "Creating email summary..."
    
    cat > output/ios/EMAIL_SUMMARY.txt <<EOF
Email Notification Summary
=========================

Configuration:
- Email Notifications: $ENABLE_EMAIL_NOTIFICATIONS
- SMTP Server: $EMAIL_SMTP_SERVER
- SMTP Port: $EMAIL_SMTP_PORT
- SMTP User: $EMAIL_SMTP_USER
- Recipient: $EMAIL_ID

Build Information:
- App Name: $APP_NAME
- Version: $VERSION_NAME ($VERSION_CODE)
- Bundle ID: $BUNDLE_ID
- Workflow ID: $WORKFLOW_ID

Feature Status:
- Push Notifications: $PUSH_NOTIFY
- TestFlight Upload: $IS_TESTFLIGHT
- Firebase Setup: $([ "$PUSH_NOTIFY" = "true" ] && echo "Enabled" || echo "Disabled")

Email Methods Available:
- mail command: $(command -v mail >/dev/null 2>&1 && echo "Available" || echo "Not available")
- curl SMTP: $(command -v curl >/dev/null 2>&1 && echo "Available" || echo "Not available")
- Python SMTP: $(command -v python3 >/dev/null 2>&1 && echo "Available" || echo "Not available")

Summary Time: $(date)
EOF

    log_success "Email summary created"
}

# Main execution
main() {
    log_info "Email Notification System"
    log "Checking email configuration..."
    
    if is_email_enabled; then
        log_success "Email notifications are enabled"
        create_email_summary
        
        # If called with arguments, send specific notification
        if [ $# -gt 0 ]; then
            local status="$1"
            local error_message="${2:-}"
            send_build_status_email "$status" "$error_message"
        else
            log_info "No specific notification requested"
            log "Usage: $0 <status> [error_message]"
            log "Status options: started, success, failure, testflight_success, testflight_failure"
        fi
    else
        log_info "Email notifications not enabled or missing configuration"
        log "To enable email notifications, set:"
        log "  - ENABLE_EMAIL_NOTIFICATIONS=true"
        log "  - EMAIL_SMTP_SERVER=smtp.gmail.com"
        log "  - EMAIL_SMTP_USER=your-email@gmail.com"
        log "  - EMAIL_SMTP_PASS=your-app-password"
    fi
}

# Execute main function with arguments
main "$@" 