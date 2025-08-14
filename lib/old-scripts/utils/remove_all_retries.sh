#!/bin/bash
# 🚫 Remove All Retry Mechanisms
# Removes all retry logic and MAX_RETRIES from codemagic.yaml
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

remove_all_retries() {
    log "🚫 Removing all retry mechanisms from codemagic.yaml..."
    
    local yaml_file="codemagic.yaml"
    local temp_file="codemagic.yaml.tmp"
    
    if [ ! -f "$yaml_file" ]; then
        log "❌ codemagic.yaml not found"
        exit 1
    fi
    
    # Backup original file
    cp "$yaml_file" "${yaml_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up original codemagic.yaml"
    
    # Remove MAX_RETRIES variables
    log "🔧 Removing MAX_RETRIES variables..."
    sed '/MAX_RETRIES: "2"/d' "$yaml_file" > "$temp_file"
    sed -i '/MAX_RETRIES: "3"/d' "$temp_file"
    
    # Remove retry logic from scripts
    log "🔧 Removing retry logic from build scripts..."
    
    # Remove retry loop patterns
    sed -i '/while \[ \$RETRY_COUNT -lt \$MAX_RETRIES \]; do/d' "$temp_file"
    sed -i '/echo "🏗️ Build attempt \$((RETRY_COUNT + 1)) of \$MAX_RETRIES"/d' "$temp_file"
    sed -i '/RETRY_COUNT=\$((RETRY_COUNT + 1))/d' "$temp_file"
    sed -i '/if \[ \$RETRY_COUNT -lt \$MAX_RETRIES \]; then/d' "$temp_file"
    sed -i '/echo "⚠️ Build failed, retrying in 10 seconds..."/d' "$temp_file"
    sed -i '/sleep 10/d' "$temp_file"
    sed -i '/flutter clean/d' "$temp_file"
    sed -i '/echo "❌ Build failed after \$MAX_RETRIES attempts"/d' "$temp_file"
    sed -i '/done/d' "$temp_file"
    
    # Remove MAX_RETRIES variable declarations
    sed -i '/MAX_RETRIES=\${MAX_RETRIES:-2}/d' "$temp_file"
    sed -i '/MAX_RETRIES=\${MAX_RETRIES:-3}/d' "$temp_file"
    sed -i '/RETRY_COUNT=0/d' "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$yaml_file"
    
    log "✅ All retry mechanisms removed successfully"
    
    # Show what was removed
    log "📋 Removed configurations:"
    log "   - MAX_RETRIES variables"
    log "   - Retry loop logic"
    log "   - Build retry mechanisms"
    log "   - Sleep and retry delays"
    
    # Verify the cleanup
    if grep -q "MAX_RETRIES" "$yaml_file"; then
        log "❌ Still found MAX_RETRIES, manual cleanup may be needed"
        grep -n "MAX_RETRIES" "$yaml_file"
    else
        log "✅ All MAX_RETRIES removed"
    fi
    
    if grep -q "while.*RETRY_COUNT" "$yaml_file"; then
        log "❌ Still found retry loops, manual cleanup may be needed"
        grep -n "while.*RETRY_COUNT" "$yaml_file"
    else
        log "✅ All retry loops removed"
    fi
}

main() {
    log "🚀 Starting retry mechanism removal..."
    remove_all_retries
    log "🎉 All retry mechanisms removed successfully!"
}

main "$@"
