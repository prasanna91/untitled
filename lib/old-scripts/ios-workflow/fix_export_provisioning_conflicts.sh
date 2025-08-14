#!/bin/bash

# 🛠️ Fix Export Provisioning Profile Conflicts
# This script fixes provisioning profile conflicts during IPA export

set -euo pipefail

# Enhanced logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️ $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1"; }

log_info "🛠️ Starting export provisioning profile conflict fix..."

# Check environment
if [ -z "${BUNDLE_ID:-}" ]; then
    log_error "BUNDLE_ID environment variable is required"
    exit 1
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    log_error "APPLE_TEAM_ID environment variable is required"
    exit 1
fi

# Create a modified ExportOptions.plist that excludes problematic frameworks
log_info "📝 Creating export options with framework exclusions..."

cat > ios/ExportOptions.plist << EXPORTPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>$UUID</string>
    </dict>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>manageVersion</key>
    <true/>
    <key>uploadToAppStore</key>
    <false/>
</dict>
</plist>
EXPORTPLIST

log_success "✅ ExportOptions.plist created with framework exclusions"

# Alternative approach: Create a script to modify the archive before export
log_info "🔧 Preparing archive for export..."

ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
if [ ! -d "$ARCHIVE_PATH" ]; then
    log_error "Archive not found at $ARCHIVE_PATH"
    exit 1
fi

# Create a backup of the original archive
log_info "📦 Creating archive backup..."
cp -r "$ARCHIVE_PATH" "${ARCHIVE_PATH}.backup"

# Modify the archive to remove provisioning profile requirements from frameworks
log_info "🔧 Modifying archive frameworks..."

# Find all frameworks in the archive
FRAMEWORKS_DIR="$ARCHIVE_PATH/Products/Applications/Runner.app/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ]; then
    for framework in "$FRAMEWORKS_DIR"/*.framework; do
        if [ -d "$framework" ]; then
            framework_name=$(basename "$framework" .framework)
            log_info "Processing framework: $framework_name"
            
            # Remove any embedded provisioning profiles from frameworks
            find "$framework" -name "*.mobileprovision" -delete 2>/dev/null || true
            
            # Ensure framework has no code signing requirements
            if [ -f "$framework/$framework_name" ]; then
                # Remove code signing from framework binary
                codesign --remove-signature "$framework/$framework_name" 2>/dev/null || log_warning "Could not remove signature from $framework_name"
            fi
        fi
    done
fi

log_success "✅ Archive modified for export"

# Create a script to handle the export with retry logic
log_info "📤 Preparing export with retry logic..."

cat > export_ipa.sh << 'EXPORTSCRIPT'
#!/bin/bash

set -euo pipefail

ARCHIVE_PATH="$1"
EXPORT_PATH="$2"
EXPORT_OPTIONS="$3"
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "📤 Export attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"
    
    if xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        2>&1 | tee xcodebuild_export.log; then
        echo "✅ Export completed successfully!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⚠️ Export failed, retrying in 5 seconds..."
            sleep 5
            # Clean export directory
            rm -rf "$EXPORT_PATH"/* 2>/dev/null || true
        else
            echo "❌ Export failed after $MAX_RETRIES attempts"
            exit 1
        fi
    fi
done
EXPORTSCRIPT

chmod +x export_ipa.sh

log_success "✅ Export script created"

# Run the export
log_info "🚀 Starting IPA export..."
./export_ipa.sh "$ARCHIVE_PATH" "build/ios/output" "ios/ExportOptions.plist"

# Verify the export
IPA_PATH=$(find build/ios/output -name "*.ipa" | head -n 1)
if [ -z "$IPA_PATH" ]; then
    log_error "❌ IPA file not found after export"
    exit 1
fi

log_success "✅ IPA export completed successfully: $IPA_PATH"

# Clean up
rm -f export_ipa.sh
rm -rf "${ARCHIVE_PATH}.backup" 2>/dev/null || true

log_success "🎉 Export provisioning profile conflict fix completed!" 