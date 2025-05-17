# Direct Command Runner for Codex
# This script creates a simple interface to run commands directly

function Show-Menu {
    Clear-Host
    Write-Host "===== CODEX COMMAND RUNNER =====" -ForegroundColor Cyan
    Write-Host "This utility allows you to run commands directly from Codex" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1: Open Calculator" -ForegroundColor Green
    Write-Host "2: Open Notepad" -ForegroundColor Green
    Write-Host "3: Open Windows Settings" -ForegroundColor Green
    Write-Host "4: Show Running Processes" -ForegroundColor Green
    Write-Host "5: System Information" -ForegroundColor Green
    Write-Host "6: Run Custom PowerShell Command" -ForegroundColor Yellow
    Write-Host "Q: Quit" -ForegroundColor Red
    Write-Host ""
    Write-Host "Enter your choice: " -NoNewline -ForegroundColor Cyan
}

function Execute-Command {
    param (
        [string]$Command
    )
    
    Write-Host "`nExecuting: $Command" -ForegroundColor Yellow
    Write-Host "------------------------------" -ForegroundColor Yellow
    
    try {
        Invoke-Expression $Command
        Write-Host "`nCommand executed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "`nError executing command: $_" -ForegroundColor Red
    }
    
    Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main loop
do {
    Show-Menu
    $choice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character.ToString().ToLower()
    
    switch ($choice) {
        '1' { Execute-Command "Start-Process calc.exe" }
        '2' { Execute-Command "Start-Process notepad.exe" }
        '3' { Execute-Command "Start-Process ms-settings:" }
        '4' { Execute-Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table -AutoSize" }
        '5' { Execute-Command "Get-ComputerInfo | Select-Object WindowsProductName, OsHardwareAbstractionLayer, CsManufacturer, CsModel | Format-List" }
        '6' {
            Write-Host "`nEnter PowerShell command to execute:" -ForegroundColor Yellow
            $customCommand = Read-Host
            if ($customCommand -ne "") {
                Execute-Command $customCommand
            }
        }
        'q' { 
            Write-Host "`nExiting Command Runner. Goodbye!" -ForegroundColor Cyan
            return 
        }
        default { 
            Write-Host "`nInvalid choice. Press any key to continue..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
} while ($true)
