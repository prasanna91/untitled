#!/bin/bash
# 🔧 Fix Corrupted Retry Logic
# Replaces all corrupted retry logic with clean single-build logic
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

fix_corrupted_retry_logic() {
    log "🔧 Fixing corrupted retry logic in codemagic.yaml..."
    
    local yaml_file="codemagic.yaml"
    local temp_file="codemagic.yaml.tmp"
    
    if [ ! -f "$yaml_file" ]; then
        log "❌ codemagic.yaml not found"
        exit 1
    fi
    
    # Backup original file
    cp "$yaml_file" "${yaml_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up original codemagic.yaml"
    
    # Replace corrupted retry logic patterns
    log "🔧 Replacing corrupted retry logic..."
    
    # Pattern 1: Corrupted retry logic with break and else
    sed 's/# Enhanced build with retry logic/# Single build attempt - no retries/g' "$yaml_file" > "$temp_file"
    
    # Remove corrupted retry logic blocks
    sed -i '/if \.\/lib\/scripts\/android\/main\.sh; then/,/fi/d' "$temp_file"
    sed -i '/if \.\/lib\/scripts\/android\/main\.sh; then/,/fi/d' "$temp_file"
    
    # Add clean single-build logic
    sed -i 's/# Single build attempt - no retries/# Single build attempt - no retries\n          echo "🏗️ Building Android APK (single attempt)"\n\n          if .\/lib\/scripts\/android\/main.sh; then\n            echo "✅ Build completed successfully!"\n          else\n            echo "❌ Build failed"\n            exit 1\n          fi/g' "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$yaml_file"
    
    log "✅ Corrupted retry logic fixed successfully"
}

main() {
    log "🚀 Starting corrupted retry logic fix..."
    fix_corrupted_retry_logic
    log "🎉 Corrupted retry logic fix completed successfully!"
}

main "$@"
