#!/bin/bash

# Fix Provisioning Profile Conflicts with CocoaPods
# This script resolves issues where pods don't support provisioning profiles

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

# Function to backup original files
backup_files() {
    log_info "Creating backups..."
    
    if [ -f "ios/Podfile" ]; then
        cp ios/Podfile ios/Podfile.backup.$(date +%Y%m%d_%H%M%S)
        log_success "Podfile backed up"
    fi
    
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup.$(date +%Y%m%d_%H%M%S)
        log_success "project.pbxproj backed up"
    fi
}

# Function to fix Podfile for provisioning profile conflicts
fix_podfile() {
    log_info "Fixing Podfile for provisioning profile conflicts..."
    
    # Create a temporary Podfile with automatic provisioning for pods
    cat > ios/Podfile.fixed << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
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
  
  # Fix for provisioning profile conflicts
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      
      # Set automatic provisioning for all pods to avoid conflicts
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
        config.build_settings['DEVELOPMENT_TEAM'] = ''
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
        
        # Ensure deployment target is set correctly
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        
        # Fix for Xcode 15+ warnings
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CAMERA=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_MICROPHONE=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_SPEECH_RECOGNIZER=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_NOTIFICATIONS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_MEDIA_LIBRARY=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_SENSORS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_BLUETOOTH=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_APP_TRACKING_TRANSPARENCY=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CRITICAL_ALERTS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_TV=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_NOTIFICATION_TIME_SENSITIVE=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_INTERNET_ADDRESS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_NETWORK=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_PHOTOS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_PHOTOS_ADD_ONLY=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CALENDAR=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CONTACTS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_APPLE_MUSIC=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_FACE_ID=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_HEALTH=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_HOMEKIT=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_MOTION=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_REMINDERS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_SIRI=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_SPEECH_RECOGNIZER=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_VIDEO_SUBTITLES=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_WEATHER=1'
      end
    end
  end
end
EOF

    # Replace the original Podfile with the fixed version
    mv ios/Podfile.fixed ios/Podfile
    log_success "Podfile updated with automatic provisioning for pods"
}

# Function to fix project.pbxproj for provisioning profile conflicts
fix_project_pbxproj() {
    log_info "Fixing project.pbxproj for provisioning profile conflicts..."
    
    if [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        log_warning "project.pbxproj not found, skipping project file fixes"
        return
    fi
    
    # Create a temporary file for the fixed project.pbxproj
    temp_file="ios/Runner.xcodeproj/project.pbxproj.temp"
    
    # Process the project.pbxproj to fix provisioning profile issues
    awk '
    BEGIN { in_pods_section = 0; in_build_settings = 0; }
    
    # Detect if we are in a Pods target section
    /^[[:space:]]*[A-Z0-9]{24}[[:space:]]*\/\* Pods \*\/ = {/ {
        in_pods_section = 1
        print
        next
    }
    
    # Detect if we are in build settings section
    /^[[:space:]]*buildSettings = {/ {
        in_build_settings = 1
        print
        next
    }
    
    # Detect end of build settings section
    /^[[:space:]]*};/ {
        if (in_build_settings) {
            in_build_settings = 0
            # Add automatic provisioning settings for pods
            if (in_pods_section) {
                print "				CODE_SIGN_STYLE = Automatic;"
                print "				DEVELOPMENT_TEAM = \"\";"
                print "				PROVISIONING_PROFILE_SPECIFIER = \"\";"
                print "				IPHONEOS_DEPLOYMENT_TARGET = 13.0;"
            }
        }
        print
        next
    }
    
    # Detect end of Pods section
    /^[[:space:]]*};[[:space:]]*\/\* End PBXNativeTarget section \*\/$/ {
        if (in_pods_section) {
            in_pods_section = 0
        }
        print
        next
    }
    
    # Remove any existing provisioning profile settings for pods
    /^[[:space:]]*PROVISIONING_PROFILE_SPECIFIER[[:space:]]*=/ {
        if (in_pods_section && in_build_settings) {
            # Skip this line (remove it)
            next
        }
    }
    
    /^[[:space:]]*CODE_SIGN_STYLE[[:space:]]*=/ {
        if (in_pods_section && in_build_settings) {
            # Skip this line (remove it)
            next
        }
    }
    
    /^[[:space:]]*DEVELOPMENT_TEAM[[:space:]]*=/ {
        if (in_pods_section && in_build_settings) {
            # Skip this line (remove it)
            next
        }
    }
    
    # Print all other lines unchanged
    { print }
    ' ios/Runner.xcodeproj/project.pbxproj > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" ios/Runner.xcodeproj/project.pbxproj
    log_success "project.pbxproj updated to remove manual provisioning for pods"
}

# Function to clean and reinstall pods
clean_and_reinstall_pods() {
    log_info "Cleaning and reinstalling pods..."
    
    cd ios
    
    # Clean existing pods
    log_info "Cleaning existing pods..."
    rm -rf Pods
    rm -rf Podfile.lock
    rm -rf .symlinks
    rm -rf Flutter/Flutter.framework
    rm -rf Flutter/Flutter.podspec
    
    # Reinstall pods
    log_info "Installing pods with fixed configuration..."
    pod install --repo-update --verbose
    
    cd ..
    log_success "Pods reinstalled with automatic provisioning"
}

# Function to verify the fix
verify_fix() {
    log_info "Verifying the fix..."
    
    # Check if Podfile has the correct post_install hook
    if grep -q "CODE_SIGN_STYLE.*Automatic" ios/Podfile; then
        log_success "✅ Podfile contains automatic provisioning settings"
    else
        log_error "❌ Podfile does not contain automatic provisioning settings"
        return 1
    fi
    
    # Check if pods directory exists
    if [ -d "ios/Pods" ]; then
        log_success "✅ Pods directory exists"
    else
        log_error "❌ Pods directory not found"
        return 1
    fi
    
    # Check if Podfile.lock exists
    if [ -f "ios/Podfile.lock" ]; then
        log_success "✅ Podfile.lock exists"
    else
        log_error "❌ Podfile.lock not found"
        return 1
    fi
    
    log_success "✅ All verification checks passed"
}

# Main execution
main() {
    log_info "🚀 Starting Provisioning Profile Conflict Fix..."
    
    # Step 1: Check environment
    check_environment
    
    # Step 2: Backup files
    backup_files
    
    # Step 3: Fix Podfile
    fix_podfile
    
    # Step 4: Fix project.pbxproj
    fix_project_pbxproj
    
    # Step 5: Clean and reinstall pods
    clean_and_reinstall_pods
    
    # Step 6: Verify the fix
    verify_fix
    
    log_success "🎉 Provisioning profile conflict fix completed successfully!"
}

# Run main function
main "$@" 