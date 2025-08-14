#!/bin/bash
# 🔥 Force Fix Environment Configuration
# Resolves $BRANCH compilation errors and ensures valid Dart code

set -eo pipefail

# Logging function
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

log "🔧 Force fixing environment configuration..."

# Check if env_config.dart exists
if [ ! -f "lib/config/env_config.dart" ]; then
    log "❌ env_config.dart not found, cannot fix"
    exit 1
fi

# Fix $BRANCH compilation errors
log "🔧 Fixing $BRANCH compilation errors..."

# Replace any remaining $BRANCH patterns with actual value or placeholder
if grep -q '\$BRANCH' "lib/config/env_config.dart"; then
    log "⚠️ Found $BRANCH patterns, replacing with actual value..."
    
    # Get actual branch value or use default
    ACTUAL_BRANCH="${CM_BRANCH:-${BRANCH:-main}}"
    
    # Replace $BRANCH with actual value
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/\$BRANCH/$ACTUAL_BRANCH/g" "lib/config/env_config.dart"
    else
        sed -i "s/\$BRANCH/$ACTUAL_BRANCH/g" "lib/config/env_config.dart"
    fi
    
    log "✅ Replaced \$BRANCH with: $ACTUAL_BRANCH"
else
    log "✅ No \$BRANCH patterns found"
fi

# Fix any other shell variable patterns that might have leaked through
log "🔧 Checking for other shell variable leaks..."

# Common shell variables that might cause issues
SHELL_VARS=("CM_BUILD_ID" "CM_COMMIT" "CM_REPO_SLUG" "CM_PULL_REQUEST_NUMBER")

for var in "${SHELL_VARS[@]}"; do
    if grep -q "\$$var" "lib/config/env_config.dart"; then
        log "⚠️ Found \$$var pattern, replacing with placeholder..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/\$$var/\"$var\"/g" "lib/config/env_config.dart"
        else
            sed -i "s/\$$var/\"$var\"/g" "lib/config/env_config.dart"
        fi
        log "✅ Fixed \$$var pattern"
    fi
done

# Validate Dart syntax
log "🔍 Validating Dart syntax..."
if command -v flutter >/dev/null 2>&1; then
    if flutter analyze "lib/config/env_config.dart" >/dev/null 2>&1; then
        log "✅ Dart syntax validation passed"
    else
        log "❌ Dart syntax validation failed"
        log "Generated file content:"
        cat "lib/config/env_config.dart"
        log "Flutter analyze output:"
        flutter analyze "lib/config/env_config.dart"
        exit 1
    fi
else
    log "⚠️ Flutter not available, skipping syntax validation"
fi

# Final cleanup - ensure no shell patterns remain
log "🔧 Final cleanup..."
if grep -q '\$[A-Z_][A-Z0-9_]*' "lib/config/env_config.dart"; then
    log "⚠️ Found remaining shell variable patterns:"
    grep -n '\$[A-Z_][A-Z0-9_]*' "lib/config/env_config.dart" || true
    
    # Replace with string literals
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/\$\([A-Z_][A-Z0-9_]*\)/"$\1"/g' "lib/config/env_config.dart"
    else
        sed -i 's/\$\([A-Z_][A-Z0-9_]*\)/"$\1"/g' "lib/config/env_config.dart"
    fi
    
    log "✅ Replaced remaining shell variables with string literals"
fi

log "✅ Environment configuration force fix completed successfully!"
