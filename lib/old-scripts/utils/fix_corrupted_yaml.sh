#!/bin/bash
# 🔧 Fix Corrupted YAML Structure
# Cleans up all corrupted sections in codemagic.yaml
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

fix_corrupted_yaml() {
    log "🔧 Fixing corrupted YAML structure in codemagic.yaml..."
    
    local yaml_file="codemagic.yaml"
    local temp_file="codemagic.yaml.tmp"
    
    if [ ! -f "$yaml_file" ]; then
        log "❌ codemagic.yaml not found"
        exit 1
    fi
    
    # Backup original file
    cp "$yaml_file" "${yaml_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up original codemagic.yaml"
    
    # Fix corrupted sections
    log "🔧 Cleaning up corrupted build logic..."
    
    # Remove extra 'fi' statements
    sed '/^[[:space:]]*fi[[:space:]]*$/d' "$yaml_file" > "$temp_file"
    
    # Fix duplicate build messages
    sed -i 's/echo "🏗️ Building Android APK (single attempt)"/echo "🏗️ Building Android APK (single attempt)"/g' "$temp_file"
    
    # Remove empty lines after build logic
    sed -i '/^[[:space:]]*$/d' "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$yaml_file"
    
    log "✅ Corrupted YAML structure fixed successfully"
}

main() {
    log "🚀 Starting corrupted YAML fix..."
    fix_corrupted_yaml
    log "🎉 Corrupted YAML fix completed successfully!"
}

main "$@"
