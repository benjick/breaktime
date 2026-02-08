#!/bin/bash
set -e

APP_NAME="BreakTime"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found. Running build first..."
    bash scripts/build-app.sh
fi

echo "Installing to /Applications..."
cp -r "$APP_BUNDLE" /Applications/
echo "Done! You can launch BreakTime from /Applications."
