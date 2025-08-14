#!/bin/bash
# 🔍 Validate and Fix ProGuard Rules
# Ensures ProGuard syntax is correct before build

set -eo pipefail

# Logging function
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

log "🔍 Validating ProGuard rules..."

# Check if ProGuard file exists
proguard_file="android/app/proguard-rules.pro"

if [ ! -f "$proguard_file" ]; then
    log "❌ ProGuard rules file not found: $proguard_file"
    exit 1
fi

log "✅ ProGuard rules file found: $proguard_file"

# Validate ProGuard syntax
validate_proguard_syntax() {
    log "🔍 Checking ProGuard syntax..."
    
    local errors_found=false
    
    # Check for common syntax errors
    if grep -q "@.*{" "$proguard_file"; then
        log "❌ Found invalid @ annotation syntax in ProGuard rules"
        log "   Lines with @ annotations:"
        grep -n "@.*{" "$proguard_file" || true
        errors_found=true
    fi
    
    # Check for unmatched braces
    local open_braces=$(grep -o "{" "$proguard_file" | wc -l)
    local close_braces=$(grep -o "}" "$proguard_file" | wc -l)
    
    if [ "$open_braces" != "$close_braces" ]; then
        log "❌ Unmatched braces in ProGuard rules"
        log "   Open braces: $open_braces, Close braces: $close_braces"
        errors_found=true
    fi
    
    # Check for invalid class patterns
    if grep -q "com\.example\..*\.\*\*" "$proguard_file"; then
        log "❌ Found invalid class pattern syntax"
        log "   Invalid patterns:"
        grep -n "com\.example\..*\.\*\*" "$proguard_file" || true
        errors_found=true
    fi
    
    if [ "$errors_found" = true ]; then
        log "❌ ProGuard syntax validation failed"
        return 1
    else
        log "✅ ProGuard syntax validation passed"
        return 0
    fi
}

# Fix common ProGuard syntax issues
fix_proguard_syntax() {
    log "🔧 Fixing ProGuard syntax issues..."
    
    # Backup original file
    cp "$proguard_file" "${proguard_file}.backup"
    
    # Fix @ annotation syntax issues
    if grep -q "@.*{" "$proguard_file"; then
        log "🔧 Fixing @ annotation syntax..."
        
        # Replace invalid @ syntax with proper -keep class syntax
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/-keep class \* {[[:space:]]*@com\.example\.quikapp004\.chat\.\*\* { \*; }[[:space:]]*}/-keep class com.example.quikapp004.chat.** { *; }/g' "$proguard_file"
        else
            sed -i 's/-keep class \* {[[:space:]]*@com\.example\.quikapp004\.chat\.\*\* { \*; }[[:space:]]*}/-keep class com.example.quikapp004.chat.** { *; }/g' "$proguard_file"
        fi
        
        log "✅ Fixed @ annotation syntax"
    fi
    
    # Fix class pattern syntax
    if grep -q "com\.example\..*\.\*\*" "$proguard_file"; then
        log "🔧 Fixing class pattern syntax..."
        
        # Replace invalid patterns with correct ones
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/com\.example\.quikapp004\.chat\.\*\*/com.example.quikapp004.chat.**/g' "$proguard_file"
            sed -i '' 's/com\.example\.quikapp004\.services\.\*\*/com.example.quikapp004.services.**/g' "$proguard_file"
            sed -i '' 's/com\.example\.quikapp004\.utils\.\*\*/com.example.quikapp004.utils.**/g' "$proguard_file"
            sed -i '' 's/com\.example\.quikapp004\.module\.\*\*/com.example.quikapp004.module.**/g' "$proguard_file"
        else
            sed -i 's/com\.example\.quikapp004\.chat\.\*\*/com.example.quikapp004.chat.**/g' "$proguard_file"
            sed -i 's/com\.example\.quikapp004\.services\.\*\*/com.example.quikapp004.services.**/g' "$proguard_file"
            sed -i 's/com\.example\.quikapp004\.utils\.\*\*/com.example.quikapp004.utils.**/g' "$proguard_file"
            sed -i 's/com\.example\.quikapp004\.module\.\*\*/com.example.quikapp004.module.**/g' "$proguard_file"
        fi
        
        log "✅ Fixed class pattern syntax"
    fi
    
    # Ensure proper package name (should match actual package from environment)
    local actual_package="${PKG_NAME:-co.pixaware.pixaware}"
    if [ -z "$actual_package" ]; then
        log "⚠️ PKG_NAME not set, using default: co.pixaware.pixaware"
        actual_package="co.pixaware.pixaware"
    fi
    
    log "🔧 Updating package names to: $actual_package"
    
    # Update all package references dynamically
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/com\.example\.quikapp004/$actual_package/g" "$proguard_file"
        sed -i '' "s/com\.example\.quikapptest06/$actual_package/g" "$proguard_file"
        sed -i '' "s/com\.example\.myapp/$actual_package/g" "$proguard_file"
        sed -i '' "s/com\.myapp\.app/$actual_package/g" "$proguard_file"
        sed -i '' "s/com\.mynewapp\.app/$actual_package/g" "$proguard_file"
        sed -i '' "s/com\.example\.flutter_app/$actual_package/g" "$proguard_file"
        sed -i '' "s/com\.example\.app/$actual_package/g" "$proguard_file"
    else
        sed -i "s/com\.example\.quikapp004/$actual_package/g" "$proguard_file"
        sed -i "s/com\.example\.quikapptest06/$actual_package/g" "$proguard_file"
        sed -i "s/com\.example\.myapp/$actual_package/g" "$proguard_file"
        sed -i "s/com\.myapp\.app/$actual_package/g" "$proguard_file"
        sed -i "s/com\.mynewapp\.app/$actual_package/g" "$proguard_file"
        sed -i "s/com\.example\.flutter_app/$actual_package/g" "$proguard_file"
        sed -i "s/com\.example\.app/$actual_package/g" "$proguard_file"
    fi
    
    log "✅ Updated all package names to $actual_package"
}

# Main execution
main() {
    log "🚀 Starting ProGuard validation and fixes..."
    
    # Validate syntax first
    if ! validate_proguard_syntax; then
        log "⚠️ ProGuard syntax issues found, attempting to fix..."
        fix_proguard_syntax
        
        # Validate again after fixes
        if ! validate_proguard_syntax; then
            log "❌ ProGuard syntax still invalid after fixes"
            log "📋 Current ProGuard file content:"
            cat "$proguard_file"
            exit 1
        fi
    fi
    
    log "✅ ProGuard rules are valid and ready for build"
    
    # Show final validation
    log "📋 Final ProGuard rules validation:"
    log "   File: $proguard_file"
    log "   Size: $(wc -c < "$proguard_file") bytes"
    log "   Lines: $(wc -l < "$proguard_file")"
    
    # Show key rules
    log "🔑 Key ProGuard rules:"
    grep -E "^-keep class|^-keepclassmembers" "$proguard_file" | head -10
}

# Run main function
main "$@"
