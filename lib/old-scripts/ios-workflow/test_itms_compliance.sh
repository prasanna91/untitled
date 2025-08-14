#!/usr/bin/env bash

# Test ITMS Compliance for iOS App Store Upload
# Verifies all required icons and Info.plist entries

set -euo pipefail

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

echo "🧪 Testing ITMS Compliance for iOS App Store Upload..."

# Test 1: Check for ITMS-90022 (iPhone 120x120 icon)
log_info "🔍 Test 1: Checking ITMS-90022 (iPhone 120x120 icon)..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" ]]; then
    # Get file size to verify it's not empty
    FILE_SIZE=$(stat -f%z "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" 2>/dev/null || echo "0")
    if [[ "$FILE_SIZE" -gt 100 ]]; then
        log_success "✅ ITMS-90022: iPhone 120x120 icon exists and has content"
    else
        log_error "❌ ITMS-90022: iPhone 120x120 icon exists but is empty or corrupted"
    fi
else
    log_error "❌ ITMS-90022: Missing iPhone 120x120 icon (Icon-App-60x60@2x.png)"
fi

# Test 2: Check for ITMS-90023 (iPad Pro 167x167 icon)
log_info "🔍 Test 2: Checking ITMS-90023 (iPad Pro 167x167 icon)..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" ]]; then
    FILE_SIZE=$(stat -f%z "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" 2>/dev/null || echo "0")
    if [[ "$FILE_SIZE" -gt 100 ]]; then
        log_success "✅ ITMS-90023: iPad Pro 167x167 icon exists and has content"
    else
        log_error "❌ ITMS-90023: iPad Pro 167x167 icon exists but is empty or corrupted"
    fi
else
    log_error "❌ ITMS-90023: Missing iPad Pro 167x167 icon (Icon-App-83.5x83.5@2x.png)"
fi

# Test 3: Check for ITMS-90023 (iPad 152x152 icon)
log_info "🔍 Test 3: Checking ITMS-90023 (iPad 152x152 icon)..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" ]]; then
    FILE_SIZE=$(stat -f%z "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" 2>/dev/null || echo "0")
    if [[ "$FILE_SIZE" -gt 100 ]]; then
        log_success "✅ ITMS-90023: iPad 152x152 icon exists and has content"
    else
        log_error "❌ ITMS-90023: iPad 152x152 icon exists but is empty or corrupted"
    fi
else
    log_error "❌ ITMS-90023: Missing iPad 152x152 icon (Icon-App-76x76@2x.png)"
fi

# Test 4: Check for ITMS-90713 (CFBundleIconName in Info.plist)
log_info "🔍 Test 4: Checking ITMS-90713 (CFBundleIconName in Info.plist)..."
if [[ -f "ios/Runner/Info.plist" ]]; then
    if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
        # Get the actual value
        ICON_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconName" ios/Runner/Info.plist 2>/dev/null || echo "")
        if [[ -n "$ICON_NAME" ]]; then
            log_success "✅ ITMS-90713: CFBundleIconName exists in Info.plist with value: $ICON_NAME"
        else
            log_error "❌ ITMS-90713: CFBundleIconName exists but has no value"
        fi
    else
        log_error "❌ ITMS-90713: Missing CFBundleIconName in Info.plist"
    fi
else
    log_error "❌ ITMS-90713: Info.plist file not found"
fi

# Test 5: Check Info.plist syntax
log_info "🔍 Test 5: Checking Info.plist syntax..."
if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
    log_success "✅ Info.plist syntax is valid"
else
    log_error "❌ Info.plist syntax is invalid"
    plutil -lint ios/Runner/Info.plist
fi

# Test 6: Check app icon asset catalog
log_info "🔍 Test 6: Checking app icon asset catalog..."
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
    log_success "✅ App icon asset catalog exists"
    
    # Check if Contents.json is valid JSON
    if python3 -m json.tool "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then
        log_success "✅ App icon Contents.json is valid JSON"
    else
        log_error "❌ App icon Contents.json is not valid JSON"
    fi
else
    log_error "❌ App icon asset catalog missing"
fi

# Test 7: Check for all required icon sizes
log_info "🔍 Test 7: Checking for all required icon sizes..."
REQUIRED_ICONS=(
    "Icon-App-20x20@1x.png"
    "Icon-App-20x20@2x.png"
    "Icon-App-20x20@3x.png"
    "Icon-App-29x29@1x.png"
    "Icon-App-29x29@2x.png"
    "Icon-App-29x29@3x.png"
    "Icon-App-40x40@1x.png"
    "Icon-App-40x40@2x.png"
    "Icon-App-40x40@3x.png"
    "Icon-App-60x60@2x.png"
    "Icon-App-60x60@3x.png"
    "Icon-App-76x76@1x.png"
    "Icon-App-76x76@2x.png"
    "Icon-App-83.5x83.5@2x.png"
    "Icon-App-1024x1024@1x.png"
)

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
MISSING_ICONS=()
EMPTY_ICONS=()

for icon in "${REQUIRED_ICONS[@]}"; do
    if [[ -f "$ICON_DIR/$icon" ]]; then
        FILE_SIZE=$(stat -f%z "$ICON_DIR/$icon" 2>/dev/null || echo "0")
        if [[ "$FILE_SIZE" -gt 100 ]]; then
            log_success "✅ Found icon: $icon (${FILE_SIZE} bytes)"
        else
            EMPTY_ICONS+=("$icon")
            log_warning "⚠️ Empty icon: $icon (${FILE_SIZE} bytes)"
        fi
    else
        MISSING_ICONS+=("$icon")
        log_error "❌ Missing icon: $icon"
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "❌ Missing icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "   - $icon"
    done
fi

if [[ ${#EMPTY_ICONS[@]} -gt 0 ]]; then
    log_warning "⚠️ Empty icons:"
    for icon in "${EMPTY_ICONS[@]}"; do
        log_warning "   - $icon"
    done
fi

# Test 8: Check bundle identifier
log_info "🔍 Test 8: Checking bundle identifier..."
if [[ -f "ios/Runner/Info.plist" ]]; then
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
    if [[ -n "$BUNDLE_ID" ]]; then
        log_success "✅ Bundle identifier: $BUNDLE_ID"
        
        # Check if it's not the default
        if [[ "$BUNDLE_ID" != "com.example.sampleprojects.sampleProject" && "$BUNDLE_ID" != "com.test.app" ]]; then
            log_success "✅ Bundle identifier is not default"
        else
            log_warning "⚠️ Bundle identifier is still default: $BUNDLE_ID"
        fi
    else
        log_error "❌ No bundle identifier found in Info.plist"
    fi
else
    log_error "❌ Info.plist not found"
fi

# Test 9: Check app name
log_info "🔍 Test 9: Checking app name..."
if [[ -f "ios/Runner/Info.plist" ]]; then
    APP_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" ios/Runner/Info.plist 2>/dev/null || echo "")
    if [[ -n "$APP_NAME" ]]; then
        log_success "✅ App display name: $APP_NAME"
    else
        log_warning "⚠️ No app display name found in Info.plist"
    fi
else
    log_error "❌ Info.plist not found"
fi

# Test 10: Check version information
log_info "🔍 Test 10: Checking version information..."
if [[ -f "ios/Runner/Info.plist" ]]; then
    VERSION_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" ios/Runner/Info.plist 2>/dev/null || echo "")
    VERSION_CODE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ios/Runner/Info.plist 2>/dev/null || echo "")
    
    if [[ -n "$VERSION_NAME" ]]; then
        log_success "✅ Version name: $VERSION_NAME"
    else
        log_warning "⚠️ No version name found in Info.plist"
    fi
    
    if [[ -n "$VERSION_CODE" ]]; then
        log_success "✅ Version code: $VERSION_CODE"
    else
        log_warning "⚠️ No version code found in Info.plist"
    fi
else
    log_error "❌ Info.plist not found"
fi

# Summary
log_info "📋 ITMS Compliance Test Summary:"
echo "=========================================="

# Count results
TOTAL_TESTS=10
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Check each test result
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if grep -q "CFBundleIconName" ios/Runner/Info.plist 2>/dev/null; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if [[ ${#MISSING_ICONS[@]} -eq 0 ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

if [[ -n "$BUNDLE_ID" && "$BUNDLE_ID" != "com.example.sampleprojects.sampleProject" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    WARNING_TESTS=$((WARNING_TESTS + 1))
fi

if [[ -n "$APP_NAME" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    WARNING_TESTS=$((WARNING_TESTS + 1))
fi

if [[ -n "$VERSION_NAME" && -n "$VERSION_CODE" ]]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    WARNING_TESTS=$((WARNING_TESTS + 1))
fi

echo "✅ Passed: $PASSED_TESTS"
echo "❌ Failed: $FAILED_TESTS"
echo "⚠️ Warnings: $WARNING_TESTS"
echo "📊 Total: $TOTAL_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "🎉 All ITMS compliance tests passed!"
    log_info "🚀 Ready for App Store Connect upload"
    exit 0
else
    log_error "❌ Some ITMS compliance tests failed"
    log_info "🔧 Run the dynamic iOS app icon fix script to resolve issues"
    exit 1
fi 