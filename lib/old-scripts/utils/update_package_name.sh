#!/bin/bash
# 🔧 Update Package Name in Build Configuration
# Dynamically updates package names in build.gradle.kts based on environment
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

update_package_name() {
    log "🔧 Updating package name in build configuration..."
    
    local build_gradle="android/app/build.gradle.kts"
    local package_name="${PKG_NAME:-co.pixaware.pixaware}"
    
    if [ ! -f "$build_gradle" ]; then
        log "❌ build.gradle.kts not found"
        exit 1
    fi
    
    log "📦 Using package name: $package_name"
    
    # Backup original file
    cp "$build_gradle" "${build_gradle}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up original build.gradle.kts"
    
    # Update namespace
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/namespace = \"com\.example\.quikapp004\"/namespace = \"$package_name\"/g" "$build_gradle"
        sed -i '' "s/applicationId = \"com\.example\.quikapp004\"/applicationId = \"$package_name\"/g" "$build_gradle"
    else
        sed -i "s/namespace = \"com\.example\.quikapp004\"/namespace = \"$package_name\"/g" "$build_gradle"
        sed -i "s/applicationId = \"com\.example\.quikapp004\"/applicationId = \"$package_name\"/g" "$build_gradle"
    fi
    
    log "✅ Updated package name to: $package_name"
    
    # Verify the changes
    if grep -q "namespace = \"$package_name\"" "$build_gradle"; then
        log "✅ Namespace updated successfully"
    else
        log "❌ Namespace update failed"
        exit 1
    fi
    
    if grep -q "applicationId = \"$package_name\"" "$build_gradle"; then
        log "✅ Application ID updated successfully"
    else
        log "❌ Application ID update failed"
        exit 1
    fi
}

main() {
    log "🚀 Starting package name update..."
    update_package_name
    log "🎉 Package name update completed successfully!"
}

main "$@"
