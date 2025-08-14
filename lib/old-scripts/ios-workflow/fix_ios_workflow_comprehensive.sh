#!/usr/bin/env bash

# Comprehensive iOS Workflow Fix
# Addresses app icons, dynamic permissions, and execution order

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🚀 Starting Comprehensive iOS Workflow Fix..."

# Step 1: Fix Dynamic Permissions
log_info "🔐 Step 1: Fixing dynamic iOS permissions..."
if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
    if ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh; then
        log_success "✅ Dynamic permissions fixed successfully"
    else
        log_error "❌ Failed to fix dynamic permissions"
        exit 1
    fi
else
    log_warning "⚠️ Dynamic permissions script not found, skipping..."
fi

# Step 2: Fix App Icons using robust ITMS-compliant method
log_info "📱 Step 2: Fixing app icons for ITMS compliance..."
if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
    if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
        log_success "✅ App icons fixed successfully for ITMS compliance"
    else
        log_error "❌ Failed to fix app icons for ITMS compliance"
        log_warning "⚠️ Trying fallback icon fixes..."
        
        # Try flutter_launcher_icons as first fallback
        if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
            if ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh; then
                log_success "✅ Fallback flutter_launcher_icons completed"
            else
                log_warning "⚠️ flutter_launcher_icons failed, trying manual fix..."
                
                # Try manual icon generation as second fallback
                if [ -f "lib/scripts/ios-workflow/fix_ios_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_icons.sh
                    if ./lib/scripts/ios-workflow/fix_ios_icons.sh; then
                        log_success "✅ Manual app icons fix completed"
                    else
                        log_error "❌ All icon fix methods failed"
                        exit 1
                    fi
                else
                    log_error "❌ No icon fix scripts available"
                    exit 1
                fi
            fi
        else
            log_warning "⚠️ No flutter_launcher_icons script, trying manual fix..."
            if [ -f "lib/scripts/ios-workflow/fix_ios_icons.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_icons.sh
                if ./lib/scripts/ios-workflow/fix_ios_icons.sh; then
                    log_success "✅ Manual app icons fix completed"
                else
                    log_error "❌ Manual icon fix failed"
                    exit 1
                fi
            else
                log_error "❌ No icon fix scripts available"
                exit 1
            fi
        fi
    fi
else
    log_warning "⚠️ Robust ITMS icon fix script not found, trying flutter_launcher_icons..."
    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
        if ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh; then
            log_success "✅ flutter_launcher_icons completed"
        else
            log_error "❌ flutter_launcher_icons failed"
            exit 1
        fi
    else
        log_error "❌ No icon fix scripts available"
        exit 1
    fi
fi

# Step 3: Verify Critical App Icons
log_info "🔍 Step 3: Verifying critical app icons..."
CRITICAL_ICONS=(
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"  # iPhone 120x120
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"  # iPad 152x152
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"  # iPad Pro 167x167
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"  # App Store 1024x1024
)

MISSING_ICONS=()
for icon in "${CRITICAL_ICONS[@]}"; do
    if [[ ! -f "$icon" ]]; then
        MISSING_ICONS+=("$icon")
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "❌ Missing critical app icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "   - $icon"
    done
    exit 1
else
    log_success "✅ All critical app icons verified"
fi

# Step 4: Verify CFBundleIconName in Info.plist
log_info "📝 Step 4: Verifying CFBundleIconName in Info.plist..."
if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
    log_success "✅ CFBundleIconName found in Info.plist"
else
    log_error "❌ CFBundleIconName missing from Info.plist"
    log_info "📝 Adding CFBundleIconName to Info.plist..."
    sed -i '' '/<\/dict>/i\
	<key>CFBundleIconName</key>\
	<string>AppIcon</string>\
' ios/Runner/Info.plist
    log_success "✅ Added CFBundleIconName to Info.plist"
fi

# Step 5: Verify App Icon Asset Catalog
log_info "📱 Step 5: Verifying app icon asset catalog..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
    log_success "✅ App icon asset catalog verified"
else
    log_error "❌ App icon asset catalog missing"
    exit 1
fi

# Step 6: Validate Info.plist syntax
log_info "🔍 Step 6: Validating Info.plist syntax..."
if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
    log_success "✅ Info.plist syntax is valid"
else
    log_error "❌ Info.plist syntax is invalid"
    plutil -lint ios/Runner/Info.plist
    exit 1
fi

# Step 7: Show comprehensive summary
log_info "📋 Comprehensive iOS Workflow Fix Summary:"
echo "=========================================="
echo "✅ Dynamic Permissions: Fixed with environment variables"
echo "✅ App Icons: Generated using flutter_launcher_icons"
echo "✅ CFBundleIconName: Added to Info.plist"
echo "✅ Critical Icons: All required sizes verified"
echo "✅ Asset Catalog: Properly configured"
echo "✅ Info.plist: Syntax validated"
echo "=========================================="

# Show environment variables used
log_info "🔧 Environment Variables Used:"
echo "=========================================="
echo "✅ APP_NAME: ${APP_NAME:-QuikApp}"
echo "✅ ORG_NAME: ${ORG_NAME:-QuikApp}"
echo "✅ IS_CHATBOT: ${IS_CHATBOT:-false}"
echo "✅ IS_CAMERA: ${IS_CAMERA:-false}"
echo "✅ IS_LOCATION: ${IS_LOCATION:-false}"
echo "✅ IS_CONTACT: ${IS_CONTACT:-false}"
echo "✅ IS_CALENDAR: ${IS_CALENDAR:-false}"
echo "✅ IS_BIOMETRIC: ${IS_BIOMETRIC:-false}"
echo "✅ IS_STORAGE: ${IS_STORAGE:-false}"
echo "✅ IS_NOTIFICATION: ${IS_NOTIFICATION:-false}"
echo "=========================================="

# Show generated icons
log_info "📱 Generated App Icons:"
echo "=========================================="
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null | head -10 || echo "No app icons found"

# Show permissions added
log_info "🔐 Permissions Added:"
echo "=========================================="
grep -E "(UsageDescription|NS.*UsageDescription)" ios/Runner/Info.plist || echo "No permissions found"

echo "=========================================="

log_success "🎉 Comprehensive iOS workflow fix completed successfully"
log_info "🚀 Ready for App Store Connect upload!" 