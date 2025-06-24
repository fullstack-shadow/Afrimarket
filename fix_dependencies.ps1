# PowerShell script to fix Flutter dependencies

# Clean Flutter project
Write-Host "Cleaning Flutter project..." -ForegroundColor Cyan
flutter clean

# Remove pubspec.lock to ensure fresh resolution
if (Test-Path "pubspec.lock") {
    Remove-Item "pubspec.lock"
}

# Remove .packages file
if (Test-Path ".packages") {
    Remove-Item ".packages"
}

# Remove .dart_tool directory
if (Test-Path ".dart_tool") {
    Remove-Item ".dart_tool" -Recurse -Force
}

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

# Upgrade packages
Write-Host "Upgrading packages..." -ForegroundColor Cyan
flutter pub upgrade --major-versions

# Run Flutter doctor to check for any issues
Write-Host "Running Flutter doctor..." -ForegroundColor Cyan
flutter doctor -v
