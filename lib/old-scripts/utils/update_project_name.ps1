# 🚀 QuikApp Project Name Update Script (PowerShell)
# Automatically updates APP_NAME in all Codemagic workflows to use project name from pubspec.yaml
# Converts project name to lowercase with no spaces

param(
    [switch]$DryRun,
    [switch]$NoBackup,
    [switch]$Verbose,
    [switch]$Help
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to show usage
function Show-Usage {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -DryRun         Show what would be changed without making changes" -ForegroundColor White
    Write-Host "  -NoBackup       Don't create backup" -ForegroundColor White
    Write-Host "  -Verbose        Verbose output" -ForegroundColor White
    Write-Host "  -Help           Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "This script automatically updates the APP_NAME variable in all Codemagic workflows" -ForegroundColor White
    Write-Host "to use the project name from pubspec.yaml with lowercase and no spaces." -ForegroundColor White
    Write-Host ""
    Write-Host "Example:" -ForegroundColor White
    Write-Host "  $($MyInvocation.MyCommand.Name)                    # Update with backup" -ForegroundColor White
    Write-Host "  $($MyInvocation.MyCommand.Name) -DryRun           # Show changes without applying" -ForegroundColor White
    Write-Host "  $($MyInvocation.MyCommand.Name) -NoBackup         # Update without backup" -ForegroundColor White
}

# Function to get project name from pubspec.yaml
function Get-ProjectName {
    try {
        $pubspecContent = Get-Content "pubspec.yaml" -Raw
        $nameMatch = [regex]::Match($pubspecContent, '^name:\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        if ($nameMatch.Success) {
            $projectName = $nameMatch.Groups[1].Value.Trim().Trim('"')
            return $projectName
        } else {
            Write-Error "Could not extract project name from pubspec.yaml"
            exit 1
        }
    } catch {
        Write-Error "Error reading pubspec.yaml: $($_.Exception.Message)"
        exit 1
    }
}

# Function to convert project name to APP_NAME format (lowercase, no spaces)
function Convert-ToAppName {
    param([string]$ProjectName)
    return $ProjectName.ToLower() -replace '\s+', ''
}

# Function to backup codemagic.yaml
function Backup-Codemagic {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "codemagic.yaml.backup.$timestamp"
    
    try {
        Copy-Item "codemagic.yaml" $backupFile
        Write-Status "Backup created: $backupFile"
        return $backupFile
    } catch {
        Write-Error "Failed to create backup: $($_.Exception.Message)"
        exit 1
    }
}

# Function to update APP_NAME in a specific workflow
function Update-WorkflowAppName {
    param(
        [string]$WorkflowName,
        [string]$NewAppName
    )
    
    Write-Status "Updating workflow: $WorkflowName"
    
    try {
        $content = Get-Content "codemagic.yaml" -Raw
        $pattern = "(?m)^(\s+$($WorkflowName):.*?)(?=^\s+[a-zA-Z-]+:|$)"
        $workflowMatch = [regex]::Match($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($workflowMatch.Success) {
            $workflowContent = $workflowMatch.Groups[1].Value
            $updatedWorkflow = $workflowContent -replace 'APP_NAME:\s*\$APP_NAME', "APP_NAME: $NewAppName"
            
            if ($workflowContent -ne $updatedWorkflow) {
                $content = $content -replace [regex]::Escape($workflowContent), $updatedWorkflow
                Set-Content "codemagic.yaml" $content -NoNewline
                Write-Success "Successfully updated $WorkflowName workflow"
                return $true
            } else {
                Write-Warning "APP_NAME not found in $WorkflowName workflow"
                return $false
            }
        } else {
            Write-Warning "Workflow $WorkflowName not found"
            return $false
        }
    } catch {
        Write-Error "Failed to update $WorkflowName workflow: $($_.Exception.Message)"
        return $false
    }
}

# Function to update all workflows
function Update-AllWorkflows {
    param([string]$NewAppName)
    
    $workflows = @("android-free", "android-paid", "android-publish", "ios-workflow", "combined")
    $successCount = 0
    $totalWorkflows = $workflows.Count
    
    Write-Status "Updating APP_NAME in all $totalWorkflows workflows..."
    
    foreach ($workflow in $workflows) {
        if (Update-WorkflowAppName -WorkflowName $workflow -NewAppName $NewAppName) {
            $successCount++
        }
    }
    
    Write-Status "Updated $successCount out of $totalWorkflows workflows"
    
    if ($successCount -eq $totalWorkflows) {
        Write-Success "All workflows updated successfully!"
        return $true
    } else {
        Write-Warning "Some workflows may not have been updated"
        return $false
    }
}

# Function to validate the updated codemagic.yaml
function Test-Codemagic {
    param([string]$NewAppName)
    
    Write-Status "Validating updated codemagic.yaml..."
    
    try {
        # Check if all APP_NAME entries were updated
        $content = Get-Content "codemagic.yaml" -Raw
        $appNameCount = ([regex]::Matches($content, 'APP_NAME:')).Count
        $updatedCount = ([regex]::Matches($content, "APP_NAME: $NewAppName")).Count
        
        Write-Status "Found $appNameCount APP_NAME entries, $updatedCount updated to new value"
        
        if ($appNameCount -eq $updatedCount) {
            Write-Success "All APP_NAME entries updated successfully"
            return $true
        } else {
            Write-Warning "Some APP_NAME entries may not have been updated"
            return $false
        }
    } catch {
        Write-Error "Validation failed: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    # Show help if requested
    if ($Help) {
        Show-Usage
        return
    }
    
    # Check if we're in the right directory
    if (-not (Test-Path "pubspec.yaml")) {
        Write-Error "pubspec.yaml not found. Please run this script from the project root directory."
        return
    }
    
    if (-not (Test-Path "codemagic.yaml")) {
        Write-Error "codemagic.yaml not found. Please run this script from the project root directory."
        return
    }
    
    Write-Status "🚀 Starting QuikApp Project Name Update..."
    
    # Get project name from pubspec.yaml
    $projectName = Get-ProjectName
    Write-Status "Project name from pubspec.yaml: $projectName"
    
    # Convert to APP_NAME format
    $newAppName = Convert-ToAppName -ProjectName $projectName
    Write-Status "Converting to APP_NAME format: $newAppName"
    
    if ($DryRun) {
        Write-Status "DRY RUN MODE - No changes will be made"
        Write-Status "Would update APP_NAME to: $newAppName"
        
        # Show what would be changed
        Write-Host ""
        Write-Status "Current APP_NAME entries in codemagic.yaml:"
        $content = Get-Content "codemagic.yaml"
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match 'APP_NAME:') {
                Write-Host "$($i + 1): $($content[$i])"
            }
        }
        
        Write-Host ""
        Write-Status "Would update these workflows:"
        Write-Host "  - android-free"
        Write-Host "  - android-paid"
        Write-Host "  - android-publish"
        Write-Host "  - ios-workflow"
        Write-Host "  - combined"
        
        return
    }
    
    # Create backup if requested
    $backupFile = ""
    if (-not $NoBackup) {
        $backupFile = Backup-Codemagic
    }
    
    # Update all workflows
    if (Update-AllWorkflows -NewAppName $newAppName) {
        Write-Success "All workflows updated successfully!"
    } else {
        Write-Warning "Some workflows may not have been updated"
    }
    
    # Validate the updated file
    if (Test-Codemagic -NewAppName $newAppName) {
        Write-Success "Validation passed!"
    } else {
        Write-Warning "Validation issues detected"
    }
    
    # Show summary
    Write-Host ""
    Write-Success "🎉 Project name update completed!"
    Write-Host "  Project name: $projectName"
    Write-Host "  APP_NAME: $newAppName"
    if ($backupFile) {
        Write-Host "  Backup: $backupFile"
    }
    Write-Host ""
    Write-Status "You can now commit the updated codemagic.yaml file"
    
    if ($Verbose) {
        Write-Host ""
        Write-Status "Updated APP_NAME entries:"
        $content = Get-Content "codemagic.yaml"
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "APP_NAME: $newAppName") {
                Write-Host "$($i + 1): $($content[$i])"
            }
        }
    }
}

# Run main function
Main
