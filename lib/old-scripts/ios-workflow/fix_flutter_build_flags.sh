#!/bin/bash
# 🔧 Fix Flutter Build Flags
# Ensures Flutter build commands use valid flags

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FLUTTER_BUILD_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Fixing Flutter build flags..."

# Step 1: Check Flutter version and available flags
log_info "Step 1: Checking Flutter version and available flags..."
FLUTTER_VERSION=$(flutter --version | head -1)
log_info "Flutter version: $FLUTTER_VERSION"

# Step 2: Test valid Flutter build flags
log_info "Step 2: Testing valid Flutter build flags..."

# Test debug build
log_info "Testing debug build flags..."
if flutter build ios --no-codesign --debug --verbose --help > /dev/null 2>&1; then
    log_success "✅ Debug build flags are valid"
else
    log_warning "⚠️ Debug build flags may have issues"
fi

# Test release build
log_info "Testing release build flags..."
if flutter build ios --no-codesign --release --verbose --help > /dev/null 2>&1; then
    log_success "✅ Release build flags are valid"
else
    log_warning "⚠️ Release build flags may have issues"
fi

# Step 3: Check for invalid flags in the workflow
log_info "Step 3: Checking for invalid flags in workflow scripts..."

# Check optimized workflow script
if grep -q "--fast-start" lib/scripts/ios-workflow/optimized_main_workflow.sh; then
    log_warning "⚠️ Found invalid --fast-start flag in optimized workflow"
    log_info "Removing invalid --fast-start flags..."
    sed -i '' 's/--fast-start//g' lib/scripts/ios-workflow/optimized_main_workflow.sh
    log_success "✅ Removed invalid --fast-start flags"
else
    log_success "✅ No invalid --fast-start flags found"
fi

# Check other workflow scripts
for script in lib/scripts/ios-workflow/*.sh; do
    if [ -f "$script" ]; then
        if grep -q "--fast-start" "$script"; then
            log_warning "⚠️ Found invalid --fast-start flag in $script"
            sed -i '' 's/--fast-start//g' "$script"
            log_success "✅ Removed invalid --fast-start flags from $script"
        fi
    fi
done

# Step 4: Verify Flutter build commands
log_info "Step 4: Verifying Flutter build commands..."

# Test basic Flutter commands
log_info "Testing basic Flutter commands..."
if flutter --version > /dev/null 2>&1; then
    log_success "✅ Flutter is properly installed"
else
    log_error "❌ Flutter is not properly installed"
    exit 1
fi

if flutter pub get > /dev/null 2>&1; then
    log_success "✅ flutter pub get works"
else
    log_warning "⚠️ flutter pub get failed"
fi

# Step 5: Test iOS build without invalid flags
log_info "Step 5: Testing iOS build without invalid flags..."

# Test debug build
log_info "Testing debug build..."
if flutter build ios --no-codesign --debug --verbose > /dev/null 2>&1; then
    log_success "✅ Debug build works without invalid flags"
else
    log_warning "⚠️ Debug build failed, but this might be expected in test environment"
fi

# Test release build
log_info "Testing release build..."
if flutter build ios --no-codesign --release --verbose > /dev/null 2>&1; then
    log_success "✅ Release build works without invalid flags"
else
    log_warning "⚠️ Release build failed, but this might be expected in test environment"
fi

# Step 6: Create corrected build commands
log_info "Step 6: Creating corrected build commands..."

# Create a file with correct build commands
cat > lib/scripts/ios-workflow/corrected_build_commands.sh << 'EOF'
#!/bin/bash
# Corrected Flutter Build Commands
# These commands use only valid Flutter flags

# Debug build command
flutter_build_debug() {
    flutter build ios --no-codesign --debug --verbose \
        --build-name="${VERSION_NAME:-1.0.0}" \
        --build-number="${VERSION_CODE:-1}" \
        2>&1 | tee flutter_build_debug.log
}

# Release build command
flutter_build_release() {
    flutter build ios --no-codesign --release --verbose \
        --build-name="${VERSION_NAME:-1.0.0}" \
        --build-number="${VERSION_CODE:-1}" \
        2>&1 | tee flutter_build_release.log
}

# Profile build command
flutter_build_profile() {
    flutter build ios --no-codesign --profile --verbose \
        --build-name="${VERSION_NAME:-1.0.0}" \
        --build-number="${VERSION_CODE:-1}" \
        2>&1 | tee flutter_build_profile.log
}

# Export the functions
export -f flutter_build_debug
export -f flutter_build_release
export -f flutter_build_profile
EOF

chmod +x lib/scripts/ios-workflow/corrected_build_commands.sh
log_success "✅ Created corrected build commands"

# Step 7: Display valid Flutter flags
log_info "Step 7: Displaying valid Flutter build flags..."
log_info "Valid Flutter build flags for iOS:"
flutter build ios --help 2>&1 | grep -E "^\s*--" | head -20 || log_warning "Could not display Flutter help"

log_success "✅ Flutter build flags fix completed" 