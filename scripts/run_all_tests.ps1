# scripts/run_all_tests.ps1
# Automated Regression Suite PowerShell Runner for Windows

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   LiverAI Precision Diagnostics — QA Regression Suite     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$PythonExe = "python"
if (Test-Path ".venv\Scripts\python.exe") {
    $PythonExe = ".venv\Scripts\python.exe"
}

Write-Host "`n--> Running Web E2E & Cross-Platform Tests..." -ForegroundColor Yellow
& $PythonExe -m pytest tests/e2e/ -v

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Web / Cross-Platform Tests Failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n--> Running Mobile (Flutter) E2E Tests..." -ForegroundColor Yellow
Set-Location "Liver Disease Detection App"
flutter test test/e2e/
$MobileExitCode = $LASTEXITCODE
Set-Location ..

if ($MobileExitCode -ne 0) {
    Write-Host "`n[ERROR] Mobile Flutter Tests Failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "   ALL REGRESSION SUITES PASSED SUCCESSFULLY (100%)       " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
