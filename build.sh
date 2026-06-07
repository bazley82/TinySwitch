#!/bin/bash
set -e

echo "=== Building TinySwitch ==="

# 1. Clean previous build files
echo "Cleaning old build artifacts..."
rm -rf build
mkdir -p build/TinySwitch.app/Contents/MacOS
mkdir -p build/TinySwitch.app/Contents/Resources

# 2. Compile Swift sources
echo "Compiling Swift files..."
SDK_PATH=$(xcrun --show-sdk-path)
swiftc -O -sdk "$SDK_PATH" -o build/TinySwitch.app/Contents/MacOS/TinySwitch Sources/*.swift

# 3. Generate Icon if needed
if [ -f "generate_icon.swift" ]; then
    echo "Running icon generator script..."
    swift generate_icon.swift
    iconutil -c icns AppIcon.iconset
fi

# 4. Package app bundle
echo "Packaging Info.plist and Resources..."
cp Info.plist build/TinySwitch.app/Contents/Info.plist
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns build/TinySwitch.app/Contents/Resources/
fi
if ls status_*.png 1>/dev/null 2>&1; then
    cp status_*.png build/TinySwitch.app/Contents/Resources/
fi

# 5. Deploy to Applications folder
echo "Deploying to ~/Applications..."
mkdir -p ~/Applications

# Kill running instance if exists
echo "Stopping any running instances of TinySwitch..."
killall TinySwitch 2>/dev/null || true

# Copy to ~/Applications
rm -rf ~/Applications/TinySwitch.app
cp -R build/TinySwitch.app ~/Applications/

# Codesign with entitlements to disable App Sandbox
echo "Applying codesign with disabled App Sandbox entitlements..."
codesign --force --deep --sign - --entitlements TinySwitch.entitlements ~/Applications/TinySwitch.app

echo "=== Build and Deployment Complete! ==="
echo "TinySwitch.app is now located in ~/Applications/"
