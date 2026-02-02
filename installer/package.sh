#!/bin/bash
# OpenClawKit - Package the macOS installer

# Configuration
APP_NAME="OpenClawKit"
VERSION="1.0.0"
OUTPUT_DIR="./build"
BUNDLE_ID="com.openclawkit.installer"

# Create build directory
mkdir -p "$OUTPUT_DIR"
echo "Created build directory: $OUTPUT_DIR"

# Create app bundle structure
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources"
echo "Created app bundle structure"

# Copy installation script
cp install.sh "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/"
chmod +x "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/install.sh"
echo "Copied installation script"

# Copy assets
cp -R ../website/images/* "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/"
echo "Copied assets"

# Create Info.plist
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>favicon.svg</string>
    <key>CFBundleExecutable</key>
    <string>OpenClawKit</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 OpenClawKit. All rights reserved.</string>
</dict>
</plist>
EOF
echo "Created Info.plist"

# TODO: Compile Swift app
# This is a placeholder - in a real implementation, we would use Xcode or swiftc to build the application
echo "NOTE: Swift app compilation not implemented yet"
echo "In a real implementation, we would build the Swift application here"

# For now, create a placeholder launcher script
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/OpenClawKit" << EOF
#!/bin/bash
osascript -e 'tell application "Terminal" to do script "bash \\"$PWD/$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/install.sh\\""'
EOF
chmod +x "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/OpenClawKit"
echo "Created placeholder launcher script"

# Create disk image
hdiutil create -volname "$APP_NAME" -srcfolder "$OUTPUT_DIR/$APP_NAME.app" -ov -format UDZO "$OUTPUT_DIR/$APP_NAME.dmg"
echo "Created disk image: $OUTPUT_DIR/$APP_NAME.dmg"

echo "✅ Build complete!"
echo "Installer package is available at: $OUTPUT_DIR/$APP_NAME.dmg"