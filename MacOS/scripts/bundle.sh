#!/bin/bash
APP_NAME="Tanto"
# Ensure build exists
swift build -c release
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"
cp .build/release/Tanto "$APP_NAME.app/Contents/MacOS/$APP_NAME"
cat > "$APP_NAME.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.tanto.macos</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST
echo "Created $APP_NAME.app"
