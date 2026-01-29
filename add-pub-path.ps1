# PowerShell script to add Dart Pub Cache bin to User Path

$pubPath = "$env:LOCALAPPDATA\Pub\Cache\bin"

# Get current user path
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Check if path is already present
if ($currentPath -split ";" -contains $pubPath) {
    Write-Host "Path already exists in User environment variables: $pubPath" -ForegroundColor Green
}
else {
    Write-Host "Adding $pubPath to User Path..." -ForegroundColor Cyan
    $newPath = "$currentPath;$pubPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Successfully added. PLEASE RESTART YOUR TERMINAL for changes to take effect." -ForegroundColor Green
}
