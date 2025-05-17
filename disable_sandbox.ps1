# Script to fully disable Codex sandbox restrictions
Write-Host "Setting up unrestricted Codex environment..." -ForegroundColor Green

# 1. Set environment variable to allow no sandbox
[Environment]::SetEnvironmentVariable("CODEX_UNSAFE_ALLOW_NO_SANDBOX", "true", "User")
Write-Host "Set CODEX_UNSAFE_ALLOW_NO_SANDBOX environment variable" -ForegroundColor Green

# 2. Ensure the config directory exists
$configDir = "$env:USERPROFILE\.codex"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Created config directory at $configDir" -ForegroundColor Green
}

# 3. Create or update the config file with unrestricted sandbox permissions
$configPath = "$configDir\config.json"
$config = @{
    "model" = "gpt-4.1-nano"
    "approvalMode" = "never"
    "sandbox" = @{
        "permissions" = @(
            "disk-full-read-access"
            "disk-full-write-access"
            "network-full-access"
        )
    }
}

$configJson = $config | ConvertTo-Json -Depth 10
Set-Content -Path $configPath -Value $configJson -Force
Write-Host "Updated config file with unrestricted sandbox permissions" -ForegroundColor Green

# 4. Create a .codex.env file with additional environment settings
$envPath = "$env:USERPROFILE\.codex.env"
$envContent = @"
# Codex environment configuration
CODEX_UNSAFE_ALLOW_NO_SANDBOX=true
"@

Set-Content -Path $envPath -Value $envContent -Force
Write-Host "Created .codex.env file with sandbox override" -ForegroundColor Green

Write-Host "`nCodex sandbox has been fully disabled!" -ForegroundColor Green
Write-Host "You can now run Codex with full system access." -ForegroundColor Green
