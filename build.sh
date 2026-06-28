#!/bin/bash
# Build GlassFace.app — a transparent full-screen camera overlay for macOS.
set -euo pipefail

cd "$(dirname "$0")"

APP="GlassFace.app"
BIN_DIR="$APP/Contents/MacOS"
RES_DIR="$APP/Contents/Resources"
BIN="$BIN_DIR/GlassFace"

echo "==> Cleaning previous build"
rm -rf "$APP"

echo "==> Creating bundle structure"
mkdir -p "$BIN_DIR" "$RES_DIR"

if [ ! -f AppIcon.icns ]; then
    echo "==> Generating app icon"
    swiftc -O -o /tmp/glassface-makeicon make_icon.swift -framework Cocoa
    /tmp/glassface-makeicon
fi

echo "==> Compiling Swift"
swiftc -O -o "$BIN" Sources/*.swift main.swift \
    -framework Cocoa -framework AVFoundation -framework Carbon -framework Vision

echo "==> Installing Info.plist and icon"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$RES_DIR/AppIcon.icns"

echo "==> Ad-hoc code signing (so camera permission persists)"
codesign --force --deep --sign - "$APP" || \
    echo "    (codesign skipped/failed — app still runs, permission prompt may reappear)"

echo "==> Done: $APP"
echo "    Run with:  open $APP"
echo "    Quit with: Control+Option+Command+Q   (or: killall GlassFace)"
