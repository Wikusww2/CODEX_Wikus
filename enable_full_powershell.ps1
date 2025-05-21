# Script to enable Codex to run all Windows PowerShell commands
Write-Host "Setting up Codex for full PowerShell command execution..." -ForegroundColor Green

# 1. Create a PowerShell runner script that Codex can use
$codexDir = "$env:USERPROFILE\.codex"
if (-not (Test-Path $codexDir)) {
    New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
}

$psRunnerDir = "$codexDir\ps-runner"
if (-not (Test-Path $psRunnerDir)) {
    New-Item -ItemType Directory -Path $psRunnerDir -Force | Out-Null
}

# Create run-ps-command.bat - a batch file that can run any PowerShell command
$runPsCommandBat = @"
@echo off
powershell -ExecutionPolicy Bypass -Command %*
"@
Set-Content -Path "$psRunnerDir\run-ps-command.bat" -Value $runPsCommandBat -Force

# 2. Update the config file to use the new approach
$configPath = "$codexDir\config.json"

# Read existing config
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Make sure approvalMode is set to never for automatic command execution
if ($config.PSObject.Properties.Name -contains "approvalMode") {
    $config.approvalMode = "full-auto"
} else {
    $config | Add-Member -NotePropertyName "approvalMode" -NotePropertyValue "full-auto" -Force
}

# Ensure sandbox policy is set to allow full access
if ($config.PSObject.Properties.Name -contains "sandbox") {
    $config.sandbox = @{
        "permissions" = @(
            "disk-full-read-access",
            "disk-full-write-access", 
            "network-full-access"
        )
    }
} else {
    $config | Add-Member -NotePropertyName "sandbox" -NotePropertyValue @{
        "permissions" = @(
            "disk-full-read-access",
            "disk-full-write-access", 
            "network-full-access"
        )
    } -Force
}

# Add safe commands list including our PowerShell runner
$safeCommands = @(
    "run-ps-command.bat",
    "powershell",
    "cmd",
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

# 3. Make sure the runner directory is in the PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $currentPath.Contains($psRunnerDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$psRunnerDir", "User")
}

# 4. Create a .codex.env file with additional environment settings
$envPath = "$env:USERPROFILE\.codex.env"
$envContent = @"
# Codex environment configuration
CODEX_UNSAFE_ALLOW_NO_SANDBOX=true
"@
Set-Content -Path $envPath -Value $envContent -Force

# 5. Create a test script to verify functionality
$testScript = @"
# Test script for Codex PowerShell execution
Write-Host "Testing PowerShell execution from Codex..." -ForegroundColor Green
Write-Host "Current time: $(Get-Date)" -ForegroundColor Green
Write-Host "Current user: $env:USERNAME" -ForegroundColor Green
Write-Host "Computer name: $env:COMPUTERNAME" -ForegroundColor Green
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host "Test completed successfully!" -ForegroundColor Green
"@
Set-Content -Path "$codexDir\test-ps-execution.ps1" -Value $testScript -Force

Write-Host "`nSetup complete! Codex should now be able to run all PowerShell commands." -ForegroundColor Green
Write-Host "You'll need to restart Codex for these changes to take effect." -ForegroundColor Green
Write-Host "`nWhen using Codex, try these examples:" -ForegroundColor Green
Write-Host "1. To run a direct PowerShell command:" -ForegroundColor Yellow
Write-Host "   'Run this PowerShell command: Get-Process | Sort-Object CPU -Descending | Select-Object -First 5'" -ForegroundColor White
Write-Host "2. To open applications:" -ForegroundColor Yellow
Write-Host "   'Run this PowerShell command: Start-Process calc.exe'" -ForegroundColor White
Write-Host "3. To run the test script:" -ForegroundColor Yellow
Write-Host "   'Run this PowerShell command: & $codexDir\test-ps-execution.ps1'" -ForegroundColor White
