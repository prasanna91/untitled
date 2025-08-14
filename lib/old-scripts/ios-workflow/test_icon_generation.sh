#!/bin/bash
# 🧪 Test Icon Generation Script
# Tests the icon generation functionality independently

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting icon generation test..."

# Check if we have a test image
if [ ! -f assets/images/logo.png ]; then
    log_error "No test image found at assets/images/logo.png"
    log_info "Please run the main icon installation script first"
    exit 1
fi

# Create test directory
TEST_DIR="test_icons"
mkdir -p "$TEST_DIR"

# Test icon sizes (just a few key ones)
declare -A test_sizes=(
    ["120x120@1x"]="test-120x120.png"
    ["152x152@1x"]="test-152x152.png"
    ["167x167@1x"]="test-167x167.png"
)

log_info "Testing icon generation with sips..."

# Test each method
for size in "${!test_sizes[@]}"; do
    filename="${test_sizes[$size]}"
    output_path="$TEST_DIR/$filename"
    
    if [[ "$size" =~ ^([0-9]+)x([0-9]+)@[0-9]+x$ ]]; then
        width="${BASH_REMATCH[1]}"
        height="${BASH_REMATCH[2]}"
        
        log_info "Testing $size ($width x $height)..."
        
        # Test Method 1: Standard sips resize
        if sips -z "$height" "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Method 1 worked for $size"
        else
            log_warning "Method 1 failed for $size"
        fi
        
        # Test Method 2: sips with format specification
        if sips -s format png --resampleHeightWidth "$height" "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Method 2 worked for $size"
        else
            log_warning "Method 2 failed for $size"
        fi
        
        # Test Method 3: sips with crop to center
        if sips -c "$height" "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Method 3 worked for $size"
        else
            log_warning "Method 3 failed for $size"
        fi
        
        # Test Method 4: sips with fit
        if sips -Z "$width" assets/images/logo.png --out "$output_path" >/dev/null 2>&1; then
            log_success "Method 4 worked for $size"
        else
            log_warning "Method 4 failed for $size"
        fi
    fi
done

# Check results
log_info "Test results:"
ls -la "$TEST_DIR"/*.png 2>/dev/null || log_warning "No test files generated"

# Clean up
rm -rf "$TEST_DIR"

log_success "Icon generation test completed" 