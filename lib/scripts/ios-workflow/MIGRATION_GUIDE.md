# 🔄 Migration Guide: Old Scripts to Enhanced iOS Workflow

## Overview

This guide helps you migrate from the old iOS workflow scripts to the new enhanced three-phase workflow. The new workflow provides better organization, enhanced error handling, and improved maintainability.

## 📋 Migration Checklist

### Before Migration
- [ ] Backup your current workflow configuration
- [ ] Review your current environment variables
- [ ] Test the new workflow in a development environment
- [ ] Update your Codemagic configuration

### After Migration
- [ ] Verify all build artifacts are generated correctly
- [ ] Test TestFlight upload functionality
- [ ] Validate error handling and reporting
- [ ] Update team documentation

## 🔄 Script Mapping

### Old Scripts → New Scripts

| Old Script | New Script | Purpose | Changes |
|------------|------------|---------|---------|
| `ios-workflow-main.sh` (old) | `ios-workflow-main.sh` (new) | Main orchestrator | Completely restructured |
| Various old scripts | `pre-build.sh` | Pre-build setup | Consolidated functionality |
| Various old scripts | `build.sh` | Core build process | Enhanced with retry logic |
| Various old scripts | `post-build.sh` | Post-build tasks | Comprehensive validation |

## 🚀 Quick Migration Steps

### Step 1: Update Script References

**Old Codemagic Configuration:**
```yaml
scripts:
  - name: iOS Build
    script: |
      bash lib/scripts/ios-workflow/ios-workflow-main.sh
```

**New Codemagic Configuration:**
```yaml
scripts:
  - name: iOS Workflow
    script: |
      bash lib/scripts/ios-workflow/ios-workflow-main.sh
```

### Step 2: Update Environment Variables

**Old Variables (still supported):**
```bash
BUNDLE_ID="com.example.app"
APP_NAME="MyApp"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
APPLE_TEAM_ID="ABC123DEF4"
```

**New Variables (recommended):**
```bash
# Add these for enhanced functionality
TARGET_ONLY_MODE="true"
MAX_RETRIES="2"
IS_TESTFLIGHT="true"
SEND_BUILD_NOTIFICATIONS="true"
```

### Step 3: Test the New Workflow

```bash
# Test individual phases
bash lib/scripts/ios-workflow/pre-build.sh
bash lib/scripts/ios-workflow/build.sh
bash lib/scripts/ios-workflow/post-build.sh

# Test complete workflow
bash lib/scripts/ios-workflow/ios-workflow-main.sh
```

## 🔧 Configuration Changes

### Environment Variable Updates

#### New Required Variables
```bash
# These are now required for optimal operation
TARGET_ONLY_MODE="true"               # Enable target-only mode
MAX_RETRIES="2"                       # Build retry attempts
```

#### Enhanced Optional Variables
```bash
# Enhanced functionality
IS_TESTFLIGHT="true"                  # TestFlight upload
SEND_BUILD_NOTIFICATIONS="true"       # Build notifications
CLEAN_COCOAPODS_CACHE="false"        # Cache cleanup control
CLEAN_FLUTTER_CACHE="false"          # Flutter cache cleanup
KEEP_ARCHIVE_FOR_DEBUG="false"       # Archive retention
```

### Build Configuration Updates

#### Old Configuration
```bash
# Old way - single script execution
bash lib/scripts/ios-workflow/ios-workflow-main.sh
```

#### New Configuration
```bash
# New way - phased execution with better control
export TARGET_ONLY_MODE="true"
export MAX_RETRIES="2"
export IS_TESTFLIGHT="true"
bash lib/scripts/ios-workflow/ios-workflow-main.sh
```

## 📊 Output Changes

### Old Output Structure
```
output/ios/
├── *.ipa
└── ARTIFACTS_SUMMARY.txt
```

### New Output Structure
```
output/ios/
├── *.ipa
├── BUILD_SUMMARY.txt          # Enhanced build summary
├── BUILD_REPORT.txt           # Detailed build report
├── WORKFLOW_SUMMARY.txt       # Complete workflow summary
└── WORKFLOW_ERROR.txt         # Error reports (if any)
```

## 🔍 Troubleshooting Migration Issues

### Common Migration Problems

#### 1. Script Not Found Errors
**Problem**: Scripts not found or not executable
**Solution**: Ensure scripts are in the correct location and have execute permissions

```bash
# Check script locations
ls -la lib/scripts/ios-workflow/

# Make scripts executable
chmod +x lib/scripts/ios-workflow/*.sh
```

#### 2. Environment Variable Issues
**Problem**: Missing or incorrect environment variables
**Solution**: Verify all required variables are set

```bash
# Check required variables
echo "BUNDLE_ID: $BUNDLE_ID"
echo "APP_NAME: $APP_NAME"
echo "VERSION_NAME: $VERSION_NAME"
echo "VERSION_CODE: $VERSION_CODE"
echo "APPLE_TEAM_ID: $APPLE_TEAM_ID"
```

#### 3. Build Phase Failures
**Problem**: Individual phases failing
**Solution**: Test phases individually and check logs

```bash
# Test pre-build phase
bash lib/scripts/ios-workflow/pre-build.sh

# Test build phase
bash lib/scripts/ios-workflow/build.sh

# Test post-build phase
bash lib/scripts/ios-workflow/post-build.sh
```

### Rollback Plan

If migration issues occur, you can rollback to the old scripts:

1. **Restore old scripts** from your backup
2. **Revert Codemagic configuration** to use old scripts
3. **Remove new environment variables** that may cause conflicts
4. **Test old workflow** to ensure it still works

## 📈 Benefits of Migration

### Performance Improvements
- **Faster builds** with optimized Xcode and CocoaPods settings
- **Parallel processing** for dependency installation
- **Retry logic** reduces build failures
- **Better caching** and cleanup strategies

### Reliability Enhancements
- **Comprehensive error handling** with detailed reporting
- **Phase-specific error recovery** prevents complete workflow failures
- **Validation at each step** ensures build quality
- **Automatic fallbacks** for common issues

### Maintainability Improvements
- **Modular design** makes debugging easier
- **Comprehensive logging** provides better visibility
- **Standardized error handling** across all phases
- **Better documentation** and troubleshooting guides

## 🔄 Migration Timeline

### Phase 1: Preparation (Day 1-2)
- [ ] Review new workflow documentation
- [ ] Backup current configuration
- [ ] Set up test environment

### Phase 2: Testing (Day 3-5)
- [ ] Test new workflow in development
- [ ] Validate all functionality
- [ ] Fix any configuration issues

### Phase 3: Deployment (Day 6)
- [ ] Update production Codemagic configuration
- [ ] Deploy new workflow
- [ ] Monitor first production build

### Phase 4: Validation (Day 7+)
- [ ] Verify production builds
- [ ] Test TestFlight uploads
- [ ] Update team documentation

## 📞 Support During Migration

### Immediate Help
1. **Check logs** for specific error messages
2. **Review this migration guide** for common issues
3. **Test individual phases** to isolate problems
4. **Verify environment variables** are set correctly

### Escalation
If issues persist:
1. **Check the troubleshooting section** in the main README
2. **Review build logs** for detailed error information
3. **Verify iOS project configuration** and certificates
4. **Test with minimal configuration** to isolate issues

## 🎯 Success Metrics

### Migration Success Criteria
- [ ] All build phases complete successfully
- [ ] IPA files are generated correctly
- [ ] TestFlight upload works (if enabled)
- [ ] Error handling provides useful information
- [ ] Build performance is maintained or improved

### Post-Migration Validation
- [ ] Build artifacts are in expected locations
- [ ] Reports are generated correctly
- [ ] Error handling works as expected
- [ ] Team can troubleshoot issues independently

---

## 📝 Migration Notes

- **Backward Compatibility**: The new workflow maintains compatibility with existing environment variables
- **Gradual Migration**: You can migrate one phase at a time if needed
- **Rollback Safety**: Old scripts remain available for rollback if needed
- **Performance**: New workflow should provide better performance and reliability

**Need Help?** Check the main README.md for comprehensive documentation and troubleshooting guides.
