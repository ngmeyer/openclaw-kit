#!/bin/bash
# Build DMG installer for OpenClawKit
# Usage: ./scripts/build-dmg.sh [--sign] [--notarize]

set -e

# Configuration
APP_NAME="OpenClawKit"
VERSION=$(defaults read "$(pwd)/OpenClawKit/OpenClawKit/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="build"
DMG_TEMP="dmg_temp"
DEVELOPER_ID="Developer ID Application: Neal Meyer (DXK5RE42H2)"
NOTARIZE_PROFILE="OpenClawKit"  # xcrun notarytool store-credentials

# Parse arguments
SIGN=false
NOTARIZE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --sign) SIGN=true ;;
        --notarize) NOTARIZE=true; SIGN=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🔨 Building ${APP_NAME} v${VERSION}..."

# Step 1: Build the app
echo "📦 Building app..."
cd OpenClawKit
xcodebuild -project OpenClawKit.xcodeproj \
    -scheme OpenClawKit \
    -configuration Release \
    -archivePath "../${BUILD_DIR}/${APP_NAME}.xcarchive" \
    archive \
    DEVELOPMENT_TEAM="" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export the app
xcodebuild -exportArchive \
    -archivePath "../${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportOptionsPlist ../scripts/export-options.plist \
    -exportPath "../${BUILD_DIR}/export" \
    || {
        # If export fails, copy directly from archive
        echo "Using app from archive..."
        mkdir -p "../${BUILD_DIR}/export"
        cp -R "../${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app" "../${BUILD_DIR}/export/"
    }

cd ..

# Step 2: Code sign if requested
if [ "$SIGN" = true ]; then
    echo "🔏 Code signing app..."
    codesign --force --options runtime --sign "${DEVELOPER_ID}" \
        --timestamp "${BUILD_DIR}/export/${APP_NAME}.app"
fi

# Step 3: Create DMG
echo "💿 Creating DMG..."

# Clean up
rm -rf "${DMG_TEMP}"
rm -f "${BUILD_DIR}/${DMG_NAME}.dmg"

# Create temp directory structure
mkdir -p "${DMG_TEMP}"
cp -R "${BUILD_DIR}/export/${APP_NAME}.app" "${DMG_TEMP}/"

# Check if create-dmg is installed
if command -v create-dmg &> /dev/null; then
    echo "Using create-dmg..."
    
    # Create background if it doesn't exist
    if [ ! -f "assets/dmg-background.png" ]; then
        echo "⚠️  No custom background found. Creating simple DMG..."
        create-dmg \
            --volname "${APP_NAME} Installer" \
            --window-size 600 400 \
            --icon "${APP_NAME}.app" 150 200 \
            --app-drop-link 450 200 \
            "${BUILD_DIR}/${DMG_NAME}.dmg" \
            "${DMG_TEMP}/"
    else
        create-dmg \
            --volname "${APP_NAME} Installer" \
            --volicon "assets/app-icon.icns" \
            --background "assets/dmg-background.png" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "${APP_NAME}.app" 150 200 \
            --hide-extension "${APP_NAME}.app" \
            --app-drop-link 450 200 \
            "${BUILD_DIR}/${DMG_NAME}.dmg" \
            "${DMG_TEMP}/"
    fi
else
    echo "create-dmg not found, using hdiutil..."
    
    # Create Applications symlink
    ln -s /Applications "${DMG_TEMP}/Applications"
    
    # Create DMG
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "${DMG_TEMP}" \
        -ov -format UDZO \
        "${BUILD_DIR}/${DMG_NAME}.dmg"
fi

# Step 4: Sign DMG if requested
if [ "$SIGN" = true ]; then
    echo "🔏 Signing DMG..."
    codesign --force --sign "${DEVELOPER_ID}" --timestamp "${BUILD_DIR}/${DMG_NAME}.dmg"
fi

# Step 5: Notarize if requested
if [ "$NOTARIZE" = true ]; then
    echo "📤 Submitting for notarization..."
    xcrun notarytool submit "${BUILD_DIR}/${DMG_NAME}.dmg" \
        --keychain-profile "${NOTARIZE_PROFILE}" \
        --wait
    
    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "${BUILD_DIR}/${DMG_NAME}.dmg"
    
    echo "✅ Verifying notarization..."
    xcrun stapler validate "${BUILD_DIR}/${DMG_NAME}.dmg"
fi

# Cleanup
rm -rf "${DMG_TEMP}"

echo ""
echo "✅ DMG created: ${BUILD_DIR}/${DMG_NAME}.dmg"
echo ""

# Show file info
ls -lh "${BUILD_DIR}/${DMG_NAME}.dmg"
