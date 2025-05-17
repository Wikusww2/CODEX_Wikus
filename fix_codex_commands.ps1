# Script to fix Codex command execution issues
Write-Host "Setting up direct command execution for Codex..." -ForegroundColor Green

# 1. Create a batch file that Codex can use to run PowerShell scripts
$batchDir = "$env:USERPROFILE\.codex\windows_commands"
if (-not (Test-Path $batchDir)) {
    New-Item -ItemType Directory -Path $batchDir -Force | Out-Null
    Write-Host "Created commands directory at $batchDir" -ForegroundColor Green
}

# Create run-ps.bat - a batch file that can run PowerShell scripts
$runPsBat = @"
@echo off
powershell -ExecutionPolicy Bypass -File %*
"@
Set-Content -Path "$batchDir\run-ps.bat" -Value $runPsBat -Force
Write-Host "Created run-ps.bat helper script" -ForegroundColor Green

# 2. Update the config file to use the new approach
$configDir = "$env:USERPROFILE\.codex"
$configPath = "$configDir\config.json"

# Read existing config
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Make sure approvalMode is set to never
if ($config.PSObject.Properties.Name -contains "approvalMode") {
    $config.approvalMode = "never"
} else {
    $config | Add-Member -NotePropertyName "approvalMode" -NotePropertyValue "never" -Force
}

# Add Windows-specific settings
$config | Add-Member -NotePropertyName "operatingSystem" -NotePropertyValue "windows" -Force

# Add safe commands list
$safeCommands = @(
    "powershell",
    "run-ps.bat",
    "notepad",
    "calc",
    "explorer"
)

if ($config.PSObject.Properties.Name -contains "safeCommands") {
    $config.safeCommands = $safeCommands
} else {
    $config | Add-Member -NotePropertyName "safeCommands" -NotePropertyValue $safeCommands -Force
}

# Save updated config
$configJson = $config | ConvertTo-Json -Depth 10
Set-Content -Path $configPath -Value $configJson -Force
Write-Host "Updated config with safe commands and approval settings" -ForegroundColor Green

# 3. Make sure the batch directory is in the PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $currentPath.Contains($batchDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$batchDir", "User")
    Write-Host "Added commands directory to PATH" -ForegroundColor Green
}

# 4. Create a .codex.env file with additional environment settings
$envPath = "$env:USERPROFILE\.codex.env"
$envContent = @"
# Codex environment configuration
CODEX_UNSAFE_ALLOW_NO_SANDBOX=true
"@

Set-Content -Path $envPath -Value $envContent -Force
Write-Host "Updated .codex.env file with sandbox override" -ForegroundColor Green

Write-Host "`nSetup complete! Now Codex should be able to run commands correctly." -ForegroundColor Green
Write-Host "You'll need to restart Codex for these changes to take effect." -ForegroundColor Green
Write-Host "When you restart Codex, try these commands:" -ForegroundColor Green
Write-Host "  - 'Open calculator for me'" -ForegroundColor Green
Write-Host "  - 'Open Windows Settings'" -ForegroundColor Green
Write-Host "  - 'Open Notepad'" -ForegroundColor Green
