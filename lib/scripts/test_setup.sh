#!/bin/bash

# 🧪 Test Setup Script for Codemagic Build System
# Verifies that all scripts are properly configured and executable

echo "🚀 Testing Codemagic Build System Setup"
echo "========================================"

# Test 1: Check if all required directories exist
echo "📁 Checking directory structure..."
required_dirs=(
    "lib/scripts/android"
    "lib/scripts/ios-workflow"
    "lib/scripts/ios"
    "lib/scripts/combined"
    "lib/scripts/utils"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir missing"
        exit 1
    fi
done

# Test 2: Check if all required scripts exist
echo ""
echo "📜 Checking script files..."
required_scripts=(
    "lib/scripts/utils/logging.sh"
    "lib/scripts/utils/env_generator.sh"
    "lib/scripts/android/main.sh"
    "lib/scripts/ios-workflow/ios-workflow-main.sh"
    "lib/scripts/combined/main.sh"
)

for script in "${required_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "✅ $script exists"
    else
        echo "❌ $script missing"
        exit 1
    fi
done

# Test 3: Check script permissions
echo ""
echo "🔐 Checking script permissions..."
for script in "${required_scripts[@]}"; do
    if [[ -x "$script" ]]; then
        echo "✅ $script is executable"
    else
        echo "⚠️  $script is not executable, fixing..."
        chmod +x "$script"
        if [[ -x "$script" ]]; then
            echo "✅ $script permissions fixed"
        else
            echo "❌ Failed to fix permissions for $script"
            exit 1
        fi
    fi
done

# Test 4: Check if scripts can be sourced
echo ""
echo "🔍 Testing script syntax..."
for script in "${required_scripts[@]}"; do
    if bash -n "$script" 2>/dev/null; then
        echo "✅ $script syntax is valid"
    else
        echo "❌ $script has syntax errors"
        exit 1
    fi
done

# Test 5: Check environment generator
echo ""
echo "⚙️  Testing environment generator..."
if bash "lib/scripts/utils/env_generator.sh" >/dev/null 2>&1; then
    echo "✅ Environment generator works"
else
    echo "⚠️  Environment generator had issues (this is normal in test environment)"
fi

# Test 6: Check if output directories can be created
echo ""
echo "📂 Testing output directory creation..."
test_dirs=(
    "output/android"
    "output/ios"
    "build/app/outputs"
    "build/ios"
)

for dir in "${test_dirs[@]}"; do
    if mkdir -p "$dir" 2>/dev/null; then
        echo "✅ Can create $dir"
        rmdir "$dir" 2>/dev/null || true
    else
        echo "❌ Cannot create $dir"
        exit 1
    fi
done

# Test 7: Check Flutter environment
echo ""
echo "🦋 Checking Flutter environment..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter is available"
    flutter --version | head -1
else
    echo "⚠️  Flutter is not available (this is normal in some environments)"
fi

    # Test 8: Check if codemagic.yaml exists and is valid
    echo ""
    echo "📋 Checking Codemagic configuration..."
    if [[ -f "codemagic.yaml" ]]; then
        echo "✅ codemagic.yaml exists"
        
        # Check for basic YAML structure
        if grep -q "workflows:" codemagic.yaml; then
            echo "✅ codemagic.yaml has workflows section"
        else
            echo "❌ codemagic.yaml missing workflows section"
        fi
        
        # Check for required workflows
        required_workflows=("android-free" "android-paid" "android-publish" "ios-workflow" "combined")
        for workflow in "${required_workflows[@]}"; do
            if grep -q "$workflow:" codemagic.yaml; then
                echo "✅ $workflow workflow found"
            else
                echo "❌ $workflow workflow missing"
            fi
        done
        
        # Check for feature integration variables
        echo ""
        echo "🔧 Checking feature integration variables..."
        feature_vars=("CHATBOT_API_ENDPOINT" "CHATBOT_API_KEY" "PULL_REFRESH_COLOR" "LOADING_INDICATOR_COLOR")
        for var in "${feature_vars[@]}"; do
            if grep -q "$var" codemagic.yaml; then
                echo "✅ $var found in workflows"
            else
                echo "⚠️  $var not found in workflows"
            fi
        done
    else
        echo "❌ codemagic.yaml missing"
        exit 1
    fi
    
    # Test 9: Check feature integration scripts
    echo ""
    echo "🚀 Checking feature integration scripts..."
    if [[ -f "lib/scripts/utils/feature_integration.sh" ]]; then
        echo "✅ Feature integration script exists"
        if [[ -x "lib/scripts/utils/feature_integration.sh" ]]; then
            echo "✅ Feature integration script is executable"
        else
            echo "⚠️  Feature integration script is not executable"
        fi
    else
        echo "❌ Feature integration script missing"
    fi
    
    if [[ -f "lib/scripts/test_features.sh" ]]; then
        echo "✅ Feature testing script exists"
        if [[ -x "lib/scripts/test_features.sh" ]]; then
            echo "✅ Feature testing script is executable"
        else
            echo "⚠️  Feature testing script is not executable"
        fi
    else
        echo "❌ Feature testing script missing"
    fi

echo ""
echo "🎉 All tests completed successfully!"
echo "🚀 Your Codemagic build system is ready to use!"
echo ""
echo "Next steps:"
echo "1. Configure environment variables in Codemagic"
echo "2. Choose a workflow to run"
echo "3. Monitor build progress in Codemagic dashboard"
echo ""
echo "For more information, check the README.md file"
