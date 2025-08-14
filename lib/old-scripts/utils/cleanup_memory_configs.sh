#!/bin/bash
# 🧹 Cleanup Excessive Memory Configurations
# Removes unnecessary memory settings that can cause issues in Codemagic
set -eo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

cleanup_memory_configs() {
    log "🧹 Cleaning up excessive memory configurations from codemagic.yaml..."
    
    local yaml_file="codemagic.yaml"
    local temp_file="codemagic.yaml.tmp"
    
    if [ ! -f "$yaml_file" ]; then
        log "❌ codemagic.yaml not found"
        exit 1
    fi
    
    # Backup original file
    cp "$yaml_file" "${yaml_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log "📋 Backed up original codemagic.yaml"
    
    # Remove excessive memory configurations
    log "🔧 Removing excessive memory configurations..."
    
    # Remove GRADLE_OPTS lines with excessive memory settings
    sed '/GRADLE_OPTS.*-Xmx12G/d' "$yaml_file" > "$temp_file"
    
    # Remove other excessive memory-related variables
    sed -i '/GRADLE_WORKER_MAX_HEAP_SIZE.*2G/d' "$temp_file"
    sed -i '/XCODE_PARALLEL_JOBS.*8/d' "$temp_file"
    sed -i '/ASSET_OPTIMIZATION.*true/d' "$temp_file"
    sed -i '/IMAGE_COMPRESSION.*true/d' "$temp_file"
    sed -i '/PARALLEL_DOWNLOADS.*true/d' "$temp_file"
    sed -i '/DOWNLOAD_TIMEOUT.*300/d' "$temp_file"
    sed -i '/DOWNLOAD_RETRIES.*3/d' "$temp_file"
    sed -i '/FAIL_ON_WARNINGS.*false/d' "$temp_file"
    sed -i '/CONTINUE_ON_ERROR.*true/d' "$temp_file"
    sed -i '/RETRY_ON_FAILURE.*true/d' "$temp_file"
    sed -i '/ENABLE_BUILD_RECOVERY.*true/d' "$temp_file"
    sed -i '/CLEAN_ON_FAILURE.*true/d' "$temp_file"
    sed -i '/CACHE_ON_SUCCESS.*true/d' "$temp_file"
    
    # Remove export GRADLE_OPTS lines from scripts
    sed -i '/export GRADLE_OPTS/d' "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$yaml_file"
    
    log "✅ Memory configurations cleaned up successfully"
    
    # Show what was removed
    log "📋 Removed configurations:"
    log "   - GRADLE_OPTS with -Xmx12G settings"
    log "   - GRADLE_WORKER_MAX_HEAP_SIZE: 2G"
    log "   - XCODE_PARALLEL_JOBS: 8"
    log "   - Excessive optimization flags"
    log "   - Memory-intensive build settings"
    
    # Verify the cleanup
    if grep -q "GRADLE_OPTS.*-Xmx12G" "$yaml_file"; then
        log "❌ Still found excessive GRADLE_OPTS, manual cleanup may be needed"
    else
        log "✅ All excessive memory configurations removed"
    fi
}

main() {
    log "🚀 Starting memory configuration cleanup..."
    cleanup_memory_configs
    log "🎉 Memory configuration cleanup completed successfully!"
}

main "$@"
