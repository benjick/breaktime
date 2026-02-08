#!/bin/bash
set -e

APP_NAME="BreakTime"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "BreakTime/Info.plist" "$APP_BUNDLE/Contents/"

if [ -f "BreakTime/Resources/AppIcon.icns" ]; then
    cp "BreakTime/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "App bundle created at: $APP_BUNDLE"
echo ""
echo "To install, run:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
