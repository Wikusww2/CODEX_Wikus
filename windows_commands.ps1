# Windows Commands Helper for Codex
# This script creates a configuration that explicitly tells Codex to use Windows commands

Write-Host "Setting up Windows-specific command configuration for Codex..." -ForegroundColor Green

# 1. Update the config file with Windows-specific settings
$configDir = "$env:USERPROFILE\.codex"
$configPath = "$configDir\config.json"

# Read existing config
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Add Windows-specific settings
$config | Add-Member -NotePropertyName "operatingSystem" -NotePropertyValue "windows" -Force
$config | Add-Member -NotePropertyName "safeCommands" -NotePropertyValue @(
    "calc",
    "notepad",
    "explorer",
    "cmd",
    "powershell",
    "Start-Process"
) -Force

# Save updated config
$configJson = $config | ConvertTo-Json -Depth 10
Set-Content -Path $configPath -Value $configJson -Force

# 2. Create a batch file for common Windows applications
$batchDir = "$env:USERPROFILE\.codex\windows_commands"
if (-not (Test-Path $batchDir)) {
    New-Item -ItemType Directory -Path $batchDir -Force | Out-Null
}

# Create calculator.bat
$calcBat = @"
@echo off
start calc.exe
"@
Set-Content -Path "$batchDir\calculator.bat" -Value $calcBat -Force

# Create notepad.bat
$notepadBat = @"
@echo off
start notepad.exe
"@
Set-Content -Path "$batchDir\notepad.bat" -Value $notepadBat -Force

# Create explorer.bat
$explorerBat = @"
@echo off
start explorer.exe
"@
Set-Content -Path "$batchDir\explorer.bat" -Value $explorerBat -Force

# 3. Add the batch directory to the PATH environment variable
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $currentPath.Contains($batchDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$batchDir", "User")
}

Write-Host "Windows command configuration complete!" -ForegroundColor Green
Write-Host "Codex should now be able to use Windows commands correctly." -ForegroundColor Green
Write-Host "Try asking Codex to 'open calculator' again." -ForegroundColor Green
