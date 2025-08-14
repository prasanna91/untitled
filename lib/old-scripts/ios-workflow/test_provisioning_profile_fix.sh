#!/bin/bash

# Test Provisioning Profile Conflict Fix
# This script tests the provisioning profile conflict fix

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

# Function to check if we're in the right directory
check_environment() {
    log_info "Checking environment..."
    
    if [ ! -d "ios" ]; then
        log_error "iOS directory not found. Please run this script from the project root."
        exit 1
    fi
    
    if [ ! -f "ios/Podfile" ]; then
        log_error "Podfile not found in ios directory."
        exit 1
    fi
    
    log_success "Environment check passed"
}

# Function to test the fix script
test_fix_script() {
    log_info "Testing provisioning profile conflict fix script..."
    
    if [ ! -f "lib/scripts/ios-workflow/fix_provisioning_profile_conflicts.sh" ]; then
        log_error "Fix script not found"
        return 1
    fi
    
    if [ ! -x "lib/scripts/ios-workflow/fix_provisioning_profile_conflicts.sh" ]; then
        log_error "Fix script is not executable"
        return 1
    fi
    
    log_success "Fix script exists and is executable"
    return 0
}

# Function to check Podfile configuration
check_podfile_configuration() {
    log_info "Checking Podfile configuration..."
    
    if [ ! -f "ios/Podfile" ]; then
        log_error "Podfile not found"
        return 1
    fi
    
    # Check for automatic provisioning settings
    if grep -q "CODE_SIGN_STYLE.*Automatic" ios/Podfile; then
        log_success "✅ Podfile contains automatic provisioning settings"
    else
        log_warning "⚠️ Podfile does not contain automatic provisioning settings"
        return 1
    fi
    
    # Check for post_install hook
    if grep -q "post_install" ios/Podfile; then
        log_success "✅ Podfile contains post_install hook"
    else
        log_warning "⚠️ Podfile does not contain post_install hook"
        return 1
    fi
    
    # Check for deployment target setting
    if grep -q "IPHONEOS_DEPLOYMENT_TARGET.*13.0" ios/Podfile; then
        log_success "✅ Podfile contains correct deployment target"
    else
        log_warning "⚠️ Podfile does not contain correct deployment target"
        return 1
    fi
    
    return 0
}

# Function to check project.pbxproj configuration
check_project_configuration() {
    log_info "Checking project.pbxproj configuration..."
    
    if [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        log_warning "project.pbxproj not found, skipping project file checks"
        return 0
    fi
    
    # Check for automatic provisioning in project file
    if grep -q "CODE_SIGN_STYLE = Automatic" ios/Runner.xcodeproj/project.pbxproj; then
        log_success "✅ project.pbxproj contains automatic provisioning settings"
    else
        log_warning "⚠️ project.pbxproj does not contain automatic provisioning settings"
    fi
    
    return 0
}

# Function to check pods installation
check_pods_installation() {
    log_info "Checking pods installation..."
    
    if [ ! -d "ios/Pods" ]; then
        log_error "❌ Pods directory not found"
        return 1
    fi
    
    if [ ! -f "ios/Podfile.lock" ]; then
        log_error "❌ Podfile.lock not found"
        return 1
    fi
    
    log_success "✅ Pods installation verified"
    return 0
}

# Function to simulate provisioning profile conflict
simulate_conflict() {
    log_info "Simulating provisioning profile conflict..."
    
    # Create a test Podfile with manual provisioning
    cat > ios/Podfile.test << 'EOF'
# Test Podfile with manual provisioning (should cause conflicts)
platform :ios, '13.0'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # This will cause provisioning profile conflicts
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      
      # Manual provisioning (will cause conflicts)
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
        config.build_settings['DEVELOPMENT_TEAM'] = 'TEAM123'
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'PROFILE123'
      end
    end
  end
end
EOF

    log_success "✅ Test Podfile created with manual provisioning"
}

# Function to test the fix
test_fix() {
    log_info "Testing the fix..."
    
    # Backup current Podfile
    if [ -f "ios/Podfile" ]; then
        cp ios/Podfile ios/Podfile.backup.test
        log_success "Current Podfile backed up"
    fi
    
    # Replace with test Podfile
    mv ios/Podfile.test ios/Podfile
    
    # Run the fix
    log_info "Running provisioning profile conflict fix..."
    if ./lib/scripts/ios-workflow/fix_provisioning_profile_conflicts.sh; then
        log_success "✅ Fix script executed successfully"
    else
        log_error "❌ Fix script failed"
        return 1
    fi
    
    # Check if the fix worked
    if check_podfile_configuration; then
        log_success "✅ Fix verified - Podfile now has automatic provisioning"
    else
        log_error "❌ Fix verification failed"
        return 1
    fi
    
    # Restore original Podfile
    if [ -f "ios/Podfile.backup.test" ]; then
        mv ios/Podfile.backup.test ios/Podfile
        log_success "Original Podfile restored"
    fi
    
    return 0
}

# Function to run comprehensive tests
run_tests() {
    log_info "🚀 Starting comprehensive provisioning profile fix tests..."
    
    local test_results=()
    
    # Test 1: Environment check
    if check_environment; then
        test_results+=("✅ Environment check passed")
    else
        test_results+=("❌ Environment check failed")
    fi
    
    # Test 2: Fix script availability
    if test_fix_script; then
        test_results+=("✅ Fix script test passed")
    else
        test_results+=("❌ Fix script test failed")
    fi
    
    # Test 3: Current Podfile configuration
    if check_podfile_configuration; then
        test_results+=("✅ Current Podfile configuration test passed")
    else
        test_results+=("❌ Current Podfile configuration test failed")
    fi
    
    # Test 4: Project configuration
    if check_project_configuration; then
        test_results+=("✅ Project configuration test passed")
    else
        test_results+=("❌ Project configuration test failed")
    fi
    
    # Test 5: Pods installation
    if check_pods_installation; then
        test_results+=("✅ Pods installation test passed")
    else
        test_results+=("❌ Pods installation test failed")
    fi
    
    # Test 6: Fix simulation
    if test_fix; then
        test_results+=("✅ Fix simulation test passed")
    else
        test_results+=("❌ Fix simulation test failed")
    fi
    
    # Print test results
    log_info "📊 Test Results:"
    for result in "${test_results[@]}"; do
        echo "  $result"
    done
    
    # Count passed tests
    local passed_tests=$(echo "${test_results[@]}" | grep -o "✅" | wc -l)
    local total_tests=${#test_results[@]}
    
    log_info "📈 Test Summary: $passed_tests/$total_tests tests passed"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "🎉 All tests passed! Provisioning profile fix is working correctly."
        return 0
    else
        log_error "❌ Some tests failed. Please review the results above."
        return 1
    fi
}

# Main execution
main() {
    log_info "🧪 Starting Provisioning Profile Fix Tests..."
    
    run_tests
    
    if [ $? -eq 0 ]; then
        log_success "🎉 All provisioning profile fix tests completed successfully!"
        exit 0
    else
        log_error "❌ Some provisioning profile fix tests failed!"
        exit 1
    fi
}

# Run main function
main "$@" 