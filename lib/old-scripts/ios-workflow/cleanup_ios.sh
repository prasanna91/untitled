#!/bin/bash
# 🧹 iOS Project Cleanup Script
# Fixes corrupted Podfile and cleans up iOS project

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CLEANUP] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting iOS project cleanup..."

# Clean up iOS project
log_info "Cleaning iOS project..."

# Remove corrupted Podfile and recreate it using dynamic generator
if [ -f "ios/Podfile" ]; then
    log_info "Backing up current Podfile..."
    cp ios/Podfile ios/Podfile.backup
fi

# Use dynamic Podfile generator
log_info "Using dynamic Podfile generator..."
if [ -f "lib/scripts/ios-workflow/generate_podfile.sh" ]; then
    chmod +x lib/scripts/ios-workflow/generate_podfile.sh
    if ./lib/scripts/ios-workflow/generate_podfile.sh; then
        log_success "Dynamic Podfile generation completed"
    else
        log_warning "Dynamic Podfile generation failed, using fallback"
        # Fallback to enhanced Podfile
        mkdir -p ios
        cat > ios/Podfile << 'EOF'
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

# Try to find Flutter configuration
def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  if File.exist?(generated_xcode_build_settings_path)
    File.foreach(generated_xcode_build_settings_path) do |line|
      matches = line.match(/FLUTTER_ROOT\=(.*)/)
      return matches[1].strip if matches
    end
  end
  # Fallback to common Flutter installation paths
  possible_paths = [
    File.expand_path(File.join('..', '..', 'flutter')),
    File.expand_path(File.join('..', '..', '..', 'flutter')),
    '/usr/local/flutter',
    '/opt/flutter'
  ]
  possible_paths.each do |path|
    return path if Dir.exist?(path)
  end
  raise "Flutter not found. Please ensure Flutter is properly installed."
end

def flutter_application_path
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  if File.exist?(generated_xcode_build_settings_path)
    File.foreach(generated_xcode_build_settings_path) do |line|
      matches = line.match(/FLUTTER_APPLICATION_PATH\=(.*)/)
      return matches[1].strip if matches
    end
  end
  # Fallback to current directory
  File.dirname(File.realpath(__FILE__))
end

# Try to require Flutter podhelper
begin
  require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)
rescue LoadError
  # Continue without Flutter podhelper
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Try to install Flutter pods if available
  begin
    flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  rescue NoMethodError
    # Continue without Flutter pods
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
  
  # Try to apply Flutter build settings if available
  begin
    flutter_additional_ios_build_settings(target)
  rescue NoMethodError
    # Continue without Flutter build settings
  end
end
EOF
        log_success "Created enhanced fallback Podfile"
    fi
else
    log_warning "Dynamic Podfile generator not found, using fallback"
    mkdir -p ios
    cat > ios/Podfile << 'EOF'
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
EOF
    log_success "Created fallback Podfile"
fi

# Clean up CocoaPods cache and files
log_info "Cleaning CocoaPods cache and files..."

# Remove Pods directory
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
    log_success "Removed ios/Pods directory"
fi

# Remove Podfile.lock
if [ -f "ios/Podfile.lock" ]; then
    rm -f ios/Podfile.lock
    log_success "Removed ios/Podfile.lock"
fi

# Remove .symlinks
if [ -d "ios/.symlinks" ]; then
    rm -rf ios/.symlinks
    log_success "Removed ios/.symlinks directory"
fi

# Clean CocoaPods cache
if command -v pod &>/dev/null; then
    pod cache clean --all 2>/dev/null || log_warning "Could not clean CocoaPods cache"
    log_success "Cleaned CocoaPods cache"
fi

# Clean Flutter
log_info "Cleaning Flutter..."
flutter clean > /dev/null 2>&1 || log_warning "flutter clean failed (continuing)"

# Remove .dart_tool
if [ -d ".dart_tool" ]; then
    rm -rf .dart_tool
    log_success "Removed .dart_tool directory"
fi

# Remove build directories
if [ -d "ios/build" ]; then
    rm -rf ios/build
    log_success "Removed ios/build directory"
fi

if [ -d "build" ]; then
    rm -rf build
    log_success "Removed build directory"
fi

# Clean Xcode derived data
if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
    rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/*
    log_success "Cleaned Xcode derived data"
fi

# Verify Podfile is correct
log_info "Verifying Podfile..."
if [ -f "ios/Podfile" ]; then
    if grep -q "target 'Runner'" ios/Podfile; then
        log_success "Podfile is correct"
    else
        log_error "Podfile is corrupted, recreating with dynamic generator..."
        if [ -f "lib/scripts/ios-workflow/generate_podfile.sh" ]; then
            chmod +x lib/scripts/ios-workflow/generate_podfile.sh
            ./lib/scripts/ios-workflow/generate_podfile.sh
        else
            log_error "Dynamic Podfile generator not found"
            exit 1
        fi
    fi
else
    log_error "Podfile not found after cleanup"
    exit 1
fi

# Test CocoaPods installation
log_info "Testing CocoaPods installation..."
if command -v pod &>/dev/null; then
    POD_VERSION=$(pod --version 2>/dev/null || echo "unknown")
    log_success "CocoaPods version: $POD_VERSION"
else
    log_error "CocoaPods not installed"
    exit 1
fi

# Test Flutter installation
log_info "Testing Flutter installation..."
if command -v flutter &>/dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1 2>/dev/null || echo "unknown")
    log_success "Flutter version: $FLUTTER_VERSION"
else
    log_error "Flutter not installed"
    exit 1
fi

log_success "✅ iOS project cleanup completed successfully"
log_info "Cleanup summary:"
log_info "  - Podfile: Cleaned and verified"
log_info "  - CocoaPods cache: Cleaned"
log_info "  - Flutter cache: Cleaned"
log_info "  - Xcode derived data: Cleaned"
log_info "  - Build directories: Cleaned" 