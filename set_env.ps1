# PowerShell script to set environment variables from env.sh
$envContent = Get-Content "lib/config/env.sh"

foreach ($line in $envContent) {
    if ($line -match '^export\s+(\w+)="([^"]*)"') {
        $varName = $matches[1]
        $varValue = $matches[2]
        [Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
        Write-Host "Set $varName = $varValue"
    }
}

Write-Host "Environment variables set successfully!"
