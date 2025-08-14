# 🚀 QuikApp Project Name Update Scripts

This directory contains scripts to automatically update the `APP_NAME` variable in all Codemagic workflows to use the project name from `pubspec.yaml` with lowercase and no spaces.

## 📋 What These Scripts Do

The scripts automatically:
1. **Extract** the project name from `pubspec.yaml`
2. **Convert** it to lowercase with no spaces (e.g., "My App Name" → "myappname")
3. **Update** all `APP_NAME: $APP_NAME` entries in `codemagic.yaml` to use the actual project name
4. **Validate** the changes and create backups

## 🔧 Available Scripts

### 1. **Bash Script** (Linux/macOS/Git Bash)
- **File**: `update_project_name.sh`
- **Usage**: `bash update_project_name.sh [OPTIONS]`

### 2. **PowerShell Script** (Windows)
- **File**: `update_project_name.ps1`
- **Usage**: `powershell -ExecutionPolicy Bypass -File update_project_name.ps1 [OPTIONS]`

### 3. **Batch File Wrapper** (Windows)
- **File**: `update_project_name.bat`
- **Usage**: `update_project_name.bat [OPTIONS]`

## 🚀 Usage Examples

### Basic Usage (with backup)
```bash
# Bash (Linux/macOS)
bash update_project_name.sh

# PowerShell (Windows)
powershell -ExecutionPolicy Bypass -File update_project_name.ps1

# Batch (Windows)
update_project_name.bat
```

### Dry Run (see what would change)
```bash
# Bash
bash update_project_name.sh --dry-run

# PowerShell
powershell -ExecutionPolicy Bypass -File update_project_name.ps1 -DryRun

# Batch
update_project_name.bat --dry-run
```

### No Backup
```bash
# Bash
bash update_project_name.sh --no-backup

# PowerShell
powershell -ExecutionPolicy Bypass -File update_project_name.ps1 -NoBackup

# Batch
update_project_name.bat --no-backup
```

### Verbose Output
```bash
# Bash
bash update_project_name.sh --verbose

# PowerShell
powershell -ExecutionPolicy Bypass -File update_project_name.ps1 -Verbose

# Batch
update_project_name.bat --verbose
```

### Help
```bash
# Bash
bash update_project_name.sh --help

# PowerShell
powershell -ExecutionPolicy Bypass -File update_project_name.ps1 -Help

# Batch
update_project_name.bat --help
```

## 📁 Workflows Updated

The scripts update `APP_NAME` in all 5 Codemagic workflows:

1. **android-free** - Basic Android build
2. **android-paid** - Android build with Firebase
3. **android-publish** - Production Android build
4. **ios-workflow** - iOS build workflow
5. **combined** - Combined Android+iOS build

## 🔍 How It Works

### 1. **Project Name Extraction**
```yaml
# From pubspec.yaml
name: quikappbs
```
Extracts: `quikappbs`

### 2. **Format Conversion**
- Input: `quikappbs`
- Output: `quikappbs` (already lowercase, no spaces)

### 3. **Workflow Update**
```yaml
# Before
APP_NAME: $APP_NAME

# After
APP_NAME: quikappbs
```

## 🛡️ Safety Features

- **Automatic Backup**: Creates timestamped backup before changes
- **Validation**: Checks YAML syntax and update count
- **Dry Run**: Preview changes without applying them
- **Error Handling**: Comprehensive error checking and reporting

## 📊 Example Output

```
[INFO] 🚀 Starting QuikApp Project Name Update...
[INFO] Project name from pubspec.yaml: quikappbs
[INFO] Converting to APP_NAME format: quikappbs
[INFO] Updating APP_NAME in all 5 workflows...
[INFO] Updating workflow: android-free
[SUCCESS] Successfully updated android-free workflow
[INFO] Updating workflow: android-paid
[SUCCESS] Successfully updated android-paid workflow
[INFO] Updating workflow: android-publish
[SUCCESS] Successfully updated android-publish workflow
[INFO] Updating workflow: ios-workflow
[SUCCESS] Successfully updated ios-workflow workflow
[INFO] Updating workflow: combined
[SUCCESS] Successfully updated combined workflow
[SUCCESS] All workflows updated successfully!
[SUCCESS] Validation passed!

[SUCCESS] 🎉 Project name update completed!
  Project name: quikappbs
  APP_NAME: quikappbs
  Backup: codemagic.yaml.backup.20250812_173336
```

## 🔧 Prerequisites

- **Bash Script**: Requires bash shell (available on Linux, macOS, Git Bash)
- **PowerShell Script**: Requires PowerShell 5.0+ (Windows 10+)
- **Batch Script**: Requires Windows with PowerShell support
- **Files**: Must be run from project root directory containing `pubspec.yaml` and `codemagic.yaml`

## 🚨 Important Notes

1. **Always run from project root**: The scripts expect to find `pubspec.yaml` and `codemagic.yaml` in the current directory
2. **Backup creation**: By default, creates a backup before making changes
3. **Workflow detection**: Automatically detects and updates all 5 workflows
4. **Validation**: Performs YAML validation and update count verification
5. **Git integration**: After running, commit the updated `codemagic.yaml` file

## 🆘 Troubleshooting

### Common Issues

1. **"pubspec.yaml not found"**
   - Solution: Run script from project root directory

2. **"codemagic.yaml not found"**
   - Solution: Ensure codemagic.yaml exists in project root

3. **PowerShell execution policy error**
   - Solution: Use `-ExecutionPolicy Bypass` flag or run as administrator

4. **Permission denied (bash script)**
   - Solution: Make script executable with `chmod +x update_project_name.sh`

### Getting Help

- Use `--help` or `-h` flag for usage information
- Use `--dry-run` or `-d` to preview changes
- Check backup files if something goes wrong

## 📝 Integration with CI/CD

These scripts can be integrated into your CI/CD pipeline:

```yaml
# Example GitHub Actions step
- name: Update Project Name
  run: |
    bash lib/scripts/utils/update_project_name.sh --no-backup
```

```yaml
# Example Codemagic pre-build script
- name: Update Project Name
  script: |
    bash lib/scripts/utils/update_project_name.sh --no-backup
```

## 🔄 When to Use

- **Project Renaming**: When changing the project name in `pubspec.yaml`
- **CI/CD Setup**: During initial project configuration
- **Workflow Updates**: When adding new workflows to `codemagic.yaml`
- **Maintenance**: Regular updates to keep configurations in sync

---

**Built with ❤️ by the QuikApp Team**
