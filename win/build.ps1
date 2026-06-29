# Build GlassFace for Windows — a transparent full-screen camera overlay.
# Requires the .NET 8 SDK (https://dotnet.microsoft.com/download). No Visual Studio needed.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '==> Restoring & building (Release)'
dotnet build GlassFace.csproj -c Release

Write-Host ''
Write-Host '==> Done.'
Write-Host '    Run with:        dotnet run --project GlassFace.csproj -c Release'
Write-Host '    Or a standalone exe:'
Write-Host '        dotnet publish GlassFace.csproj -c Release -r win-x64 --self-contained false'
Write-Host '    Quit the app with: Ctrl+Alt+Shift+Q   (or via the tray icon)'
