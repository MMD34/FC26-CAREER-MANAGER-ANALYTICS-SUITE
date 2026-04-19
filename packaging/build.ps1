# Build the FC26 Analytics one-file Windows executable.
# Usage: from repo root, run `powershell -ExecutionPolicy Bypass -File packaging/build.ps1`.
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    Write-Host "Cleaning previous build artefacts..."
    Remove-Item -Recurse -Force build, dist -ErrorAction SilentlyContinue

    Write-Host "Ensuring PyInstaller is installed..."
    python -m pip install --upgrade pyinstaller | Out-Null

    Write-Host "Running PyInstaller..."
    python -m PyInstaller "packaging/fc26_analytics.spec" --noconfirm

    $exe = Join-Path $repoRoot "dist/FC26Analytics.exe"
    if (Test-Path $exe) {
        Write-Host "Built: $exe"
    } else {
        throw "Build did not produce $exe"
    }
} finally {
    Pop-Location
}
