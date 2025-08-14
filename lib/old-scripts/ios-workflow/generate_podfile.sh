#!/bin/bash
# 🍎 Dynamic Podfile Generator for iOS Workflow
# Generates Podfile based on Flutter configuration availability

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting dynamic Podfile generation..."

# Check if Flutter configuration files exist
FLUTTER_CONFIG_PATH="ios/../Flutter/Generated.xcconfig"
FLUTTER_ROOT=""
FLUTTER_APPLICATION_PATH=""

# Try to create Flutter configuration if it doesn't exist
if [ ! -f "$FLUTTER_CONFIG_PATH" ]; then
    log_warning "Flutter configuration not found, attempting to create it..."
    
    # Create Flutter directory if it doesn't exist
    mkdir -p ios/../Flutter
    
    # Try to find Flutter installation
    FLUTTER_PATH=$(which flutter 2>/dev/null || echo "")
    if [ -n "$FLUTTER_PATH" ]; then
        FLUTTER_ROOT=$(dirname "$FLUTTER_PATH")
        log_info "Found Flutter at: $FLUTTER_ROOT"
        
        # Create basic Generated.xcconfig
        cat > "$FLUTTER_CONFIG_PATH" << EOF
FLUTTER_ROOT=$FLUTTER_ROOT
FLUTTER_APPLICATION_PATH=$(pwd)
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF
        log_success "Created Flutter configuration file"
    else
        log_warning "Flutter not found in PATH, will use fallback configuration"
    fi
fi

if [ -f "$FLUTTER_CONFIG_PATH" ]; then
    log_info "Flutter configuration found, extracting paths..."
    
    # Extract FLUTTER_ROOT
    if grep -q "FLUTTER_ROOT=" "$FLUTTER_CONFIG_PATH"; then
        FLUTTER_ROOT=$(grep "FLUTTER_ROOT=" "$FLUTTER_CONFIG_PATH" | cut -d'=' -f2 | tr -d '"')
        log_success "Found FLUTTER_ROOT: $FLUTTER_ROOT"
    fi
    
    # Extract FLUTTER_APPLICATION_PATH
    if grep -q "FLUTTER_APPLICATION_PATH=" "$FLUTTER_CONFIG_PATH"; then
        FLUTTER_APPLICATION_PATH=$(grep "FLUTTER_APPLICATION_PATH=" "$FLUTTER_CONFIG_PATH" | cut -d'=' -f2 | tr -d '"')
        log_success "Found FLUTTER_APPLICATION_PATH: $FLUTTER_APPLICATION_PATH"
    fi
else
    log_warning "Flutter configuration not found, will use fallback Podfile"
fi

# Create Podfile directory if it doesn't exist
mkdir -p ios

# Generate Podfile based on configuration availability
if [ -n "$FLUTTER_ROOT" ] && [ -n "$FLUTTER_APPLICATION_PATH" ]; then
    log_info "Generating full Flutter Podfile..."
    cat > ios/Podfile << EOF
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

def flutter_application_path
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_APPLICATION_PATH\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_APPLICATION_PATH not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
EOF
    log_success "Generated full Flutter Podfile"
else
    log_info "Generating enhanced fallback Podfile with Flutter dependencies..."
    cat > ios/Podfile << EOF
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
  log_warning "Flutter podhelper not found, using basic configuration"
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Try to install Flutter pods if available
  begin
    flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  rescue NoMethodError
    log_warning "flutter_install_all_ios_pods not available, skipping Flutter pods"
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
    log_warning "flutter_additional_ios_build_settings not available"
  end
end
EOF
    log_success "Generated enhanced fallback Podfile"
fi

# Verify Podfile was created
if [ -f "ios/Podfile" ]; then
    log_success "✅ Podfile created successfully at ios/Podfile"
    log_info "Podfile contents:"
    cat ios/Podfile
else
    log_error "❌ Failed to create Podfile"
    exit 1
fi

log_success "Dynamic Podfile generation completed" 