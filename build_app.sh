#!/bin/bash
# Kinako.app を build/ に作成します（Xcode 26 / Swift 6.2 以上が必要）
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

APP="build/Kinako.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Icon/Kinako.icns "$APP/Contents/Resources/Kinako.icns"
cp "$BIN/Kinako" "$APP/Contents/MacOS/Kinako"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Kinako</string>
    <key>CFBundleIdentifier</key><string>app.kinako.Kinako</string>
    <key>CFBundleIconFile</key><string>Kinako</string>
    <key>CFBundleName</key><string>Kinako</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "完成: $(pwd)/$APP"
open build
