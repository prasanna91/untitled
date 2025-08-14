#!/bin/bash

# Build Optimization Script for QuikApp
# This script optimizes build performance for both Android and iOS

set -e

echo "🚀 Starting Build Optimization..."

# Android Build Optimizations
echo "📱 Optimizing Android Build..."

# Clean Gradle cache if it's too large
GRADLE_CACHE_SIZE=$(du -sm ~/.gradle/caches 2>/dev/null | cut -f1 || echo "0")
if [ "$GRADLE_CACHE_SIZE" -gt 5000 ]; then
    echo "🧹 Cleaning large Gradle cache..."
    rm -rf ~/.gradle/caches/modules-2
    rm -rf ~/.gradle/caches/transforms-*
fi

# Optimize Gradle daemon
echo "⚡ Optimizing Gradle daemon..."
./gradlew --stop 2>/dev/null || true
./gradlew --no-daemon --parallel --max-workers=8 assembleDebug

# iOS Build Optimizations
echo "🍎 Optimizing iOS Build..."

# Clean CocoaPods cache if needed
PODS_CACHE_SIZE=$(du -sm ~/Library/Caches/CocoaPods 2>/dev/null | cut -f1 || echo "0")
if [ "$PODS_CACHE_SIZE" -gt 2000 ]; then
    echo "🧹 Cleaning large CocoaPods cache..."
    rm -rf ~/Library/Caches/CocoaPods
fi

# Update Podfile for better performance
if [ -f "ios/Podfile" ]; then
    echo "📝 Updating Podfile for optimization..."
    # Add post_install optimizations if not present
    if ! grep -q "post_install" ios/Podfile; then
        cat >> ios/Podfile << 'EOF'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set deployment target to 12.0 for all pods
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Set provisioning profile to automatic for pods that don't support it
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      
      # Fix for Xcode 15 warnings
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CAMERA=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_MICROPHONE=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_PHOTOS=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_NOTIFICATIONS=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CONTACTS=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_CALENDAR=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_STORAGE=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_BIOMETRICS=1'
      
      # Fix for arm64 architecture issues
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
  
  # Fix for Xcode 15 compatibility
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end
EOF
    fi
fi

# Flutter optimizations
echo "🎯 Optimizing Flutter build..."

# Clean Flutter cache if needed
FLUTTER_CACHE_SIZE=$(du -sm ~/.pub-cache 2>/dev/null | cut -f1 || echo "0")
if [ "$FLUTTER_CACHE_SIZE" -gt 1000 ]; then
    echo "🧹 Cleaning large Flutter cache..."
    flutter pub cache clean
fi

# Update pubspec.lock for faster builds
flutter pub get --offline 2>/dev/null || flutter pub get

# Optimize Flutter build
flutter clean
flutter pub get

echo "✅ Build optimization completed!"
echo ""
echo "📊 Build Performance Tips:"
echo "• Use 'flutter run --release' for faster debug builds"
echo "• Use 'flutter build apk --split-per-abi' for smaller APKs"
echo "• Use 'flutter build ios --release' for faster iOS builds"
echo "• Consider using 'flutter build apk --target-platform android-arm64' for specific architectures"
echo ""
echo "🔧 Additional optimizations applied:"
echo "• Gradle daemon optimization"
echo "• CocoaPods cache management"
echo "• Flutter cache optimization"
echo "• Build configuration improvements" 