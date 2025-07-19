# PowerShell script to program PWM project to Spartan 6 FPGA

Write-Host "Programming PWM project to Spartan 6..." -ForegroundColor Green

# Check if bitstream exists
$bitstreamPath = "..\bitstreams\Example.bit"
if (-not (Test-Path $bitstreamPath)) {
    Write-Host "Error: Bitstream file not found at $bitstreamPath" -ForegroundColor Red
    Write-Host "Please build the project first using 'make' or build scripts" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found bitstream: $bitstreamPath" -ForegroundColor Cyan

# Program using OpenOCD (relative path)
Write-Host "Starting OpenOCD programming..." -ForegroundColor Yellow
& "..\..\..\openocd-0.12.0\bin\openocd.exe" -f program_pwm.cfg

if ($LASTEXITCODE -eq 0) {
    Write-Host "Programming completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "Programming failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}
