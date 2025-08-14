#!/bin/bash
# 🔧 Fix All Missing fi Statements
# Fixes all missing fi statements in build scripts across all workflows
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

fix_all_missing_fi() {
    log "🔧 Fixing all missing fi statements in codemagic.yaml..."
    
    local yaml_file="codemagic.yaml"
    local temp_file="codemagic.yaml.tmp"
    
    if [ ! -f "$yaml_file" ]; then
        log "❌ codemagic.yaml not found"
        exit 1
    fi
    
    # Backup original file
    cp "$yaml_file" "${yaml_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up original codemagic.yaml"
    
    # Fix missing fi statements in build scripts
    log "🔧 Fixing missing fi statements in build scripts..."
    
    # Pattern 1: if main.sh then else exit 1 without fi
    sed 's/if \.\/lib\/scripts\/android\/main\.sh; then\(.*\)else\(.*\)exit 1$/if .\/lib\/scripts\/android\/main.sh; then\1else\2exit 1\n          fi/g' "$yaml_file" > "$temp_file"
    
    # Pattern 2: if combined/main.sh then else exit 1 without fi
    sed -i 's/if \.\/lib\/scripts\/combined\/main\.sh; then\(.*\)else\(.*\)exit 1$/if .\/lib\/scripts\/combined\/main.sh; then\1else\2exit 1\n          fi/g' "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$yaml_file"
    
    log "✅ All missing fi statements fixed successfully"
}

main() {
    log "🚀 Starting missing fi statement fix..."
    fix_all_missing_fi
    log "🎉 All missing fi statements fixed successfully!"
}

main "$@"
