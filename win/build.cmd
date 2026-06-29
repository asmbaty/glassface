@echo off
REM Build GlassFace for Windows. Requires the .NET 8 SDK.
cd /d "%~dp0"
dotnet build GlassFace.csproj -c Release
if errorlevel 1 exit /b 1
echo.
echo Done. Run with:  dotnet run --project GlassFace.csproj -c Release
echo Quit with:       Ctrl+Alt+Shift+Q   (or via the tray icon)
