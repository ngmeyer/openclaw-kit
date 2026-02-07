#!/bin/bash

# OpenClawKit DMG Creator
# Uses create-dmg (brew install create-dmg) - the gold standard for macOS DMG creation
# https://github.com/create-dmg/create-dmg

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_NAME="OpenClawKit"
VERSION=${1:-"1.0.0"}
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="$(dirname "$0")/../builds"
ASSETS_DIR="$(dirname "$0")/assets"

echo -e "${GREEN}🚀 Creating DMG for OpenClawKit v${VERSION}${NC}"
echo ""

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${RED}❌ create-dmg not found${NC}"
    echo "Install it with: brew install create-dmg"
    exit 1
fi

# Find the built app
DERIVED_DATA_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "OpenClawKit-*" -type d | head -1)
if [ -z "$DERIVED_DATA_PATH" ]; then
    echo -e "${RED}❌ Error: Could not find DerivedData path${NC}"
    exit 1
fi

APP_PATH="${DERIVED_DATA_PATH}/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: App not found. Build Release configuration first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 App:${NC} ${APP_PATH}"

# Create assets directory and background if needed
mkdir -p "$ASSETS_DIR"

# Create background images if they don't exist
if [ ! -f "$ASSETS_DIR/dmg-background.png" ]; then
    echo -e "${YELLOW}🎨 Creating background images...${NC}"
    
    # Check if ImageMagick is available
    if command -v convert &> /dev/null; then
        # Create 1x background (660x400)
        convert -size 660x400 \
            gradient:'#1a1a2e'-'#16213e' \
            -gravity center \
            -fill '#4a9eff' -font Helvetica-Bold -pointsize 28 \
            -annotate +0-80 'OpenClawKit' \
            -fill '#888888' -font Helvetica -pointsize 14 \
            -annotate +0+100 'Drag the app to your Applications folder' \
            "$ASSETS_DIR/dmg-background.png"
        
        # Create 2x background (1320x800)
        convert -size 1320x800 \
            gradient:'#1a1a2e'-'#16213e' \
            -gravity center \
            -fill '#4a9eff' -font Helvetica-Bold -pointsize 56 \
            -annotate +0-160 'OpenClawKit' \
            -fill '#888888' -font Helvetica -pointsize 28 \
            -annotate +0+200 'Drag the app to your Applications folder' \
            "$ASSETS_DIR/dmg-background@2x.png"
        
        # Combine into multi-resolution TIFF for best compatibility
        tiffutil -cathidpicheck "$ASSETS_DIR/dmg-background.png" "$ASSETS_DIR/dmg-background@2x.png" -out "$ASSETS_DIR/dmg-background.tiff"
        
        echo -e "${GREEN}✅ Background images created${NC}"
    else
        echo -e "${YELLOW}⚠️  ImageMagick not found. Using solid color background.${NC}"
        echo "Install ImageMagick for custom backgrounds: brew install imagemagick"
    fi
fi

# Clean up old DMGs
rm -f "${BUILD_DIR}/${DMG_NAME}.dmg"
mkdir -p "$BUILD_DIR"

# Create staging directory
STAGING_DIR="/tmp/${DMG_NAME}-staging-$$"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy app to staging
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create DMG using create-dmg
echo -e "${YELLOW}💿 Creating DMG with create-dmg...${NC}"

if [ -f "$ASSETS_DIR/dmg-background.tiff" ]; then
    # Use custom background
    create-dmg \
        --volname "$APP_NAME" \
        --window-size 660 400 \
        --window-pos 200 120 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 180 200 \
        --app-drop-link 480 200 \
        --background "$ASSETS_DIR/dmg-background.tiff" \
        --format ULFO \
        --filesystem HFS+ \
        --no-internet-enable \
        "${BUILD_DIR}/${DMG_NAME}.dmg" \
        "$STAGING_DIR/"
else
    # Use built-in background
    create-dmg \
        --volname "$APP_NAME" \
        --window-size 660 400 \
        --window-pos 200 120 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 180 200 \
        --app-drop-link 480 200 \
        --format ULFO \
        --filesystem HFS+ \
        --no-internet-enable \
        "${BUILD_DIR}/${DMG_NAME}.dmg" \
        "$STAGING_DIR/"
fi

# Clean up staging
rm -rf "$STAGING_DIR"

# Show results
echo ""
echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  File:       ${BUILD_DIR}/${DMG_NAME}.dmg"
echo "  Size:       $(du -h "${BUILD_DIR}/${DMG_NAME}.dmg" | cut -f1)"
echo "  Layout:     Professional drag-to-Applications"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✨ Ready for distribution!${NC}"
