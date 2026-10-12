# Script khoi dong FastAPI Server cho Enigma
Write-Host "=== Dang khoi dong Enigma FastAPI Server... ===" -ForegroundColor Green

# Tu dong ho tro port forwarding cho Android Device / Emulator qua ADB neu co ket noi
try {
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $adbPath) {
        & $adbPath reverse tcp:8000 tcp:8000 2>$null
        Write-Host "[ADB] Da thiet lap reverse port tcp:8000 thanh cong cho Android." -ForegroundColor Cyan
    } elseif (Get-Command adb -ErrorAction SilentlyContinue) {
        adb reverse tcp:8000 tcp:8000 2>$null
        Write-Host "[ADB] Da thiet lap reverse port tcp:8000 thanh cong cho Android." -ForegroundColor Cyan
    }
} catch {}

# Kich hoat virtualenv neu co
if (Test-Path "$PSScriptRoot\venv\Scripts\Activate.ps1") {
    try { & "$PSScriptRoot\venv\Scripts\Activate.ps1" } catch {}
}

# Chay uvicorn tren 0.0.0.0 de Flutter Mobile / Android Emulator co the ket noi
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

