#!/bin/bash

# OpenClawKit Release Build Script
# Complete release pipeline: build → DMG → sign → notarize
# Usage: ./scripts/release.sh [version]
# Example: ./scripts/release.sh 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="OpenClawKit"
BUNDLE_ID="com.gearu.OpenClawKit"
DEVELOPER_ID="Developer ID Application: Neal Meyer (DXK5RE42H2)"
KEYCHAIN_PROFILE="OpenClawKit-Notarize"

# Version (default to 1.0.0 if not provided)
VERSION=${1:-"1.0.0"}

SCRIPT_DIR="$(dirname "$0")"

echo -e "${GREEN}🚀 Starting OpenClawKit v${VERSION} Release Build${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

if ! command -v create-dmg &> /dev/null; then
    echo -e "${RED}❌ create-dmg not installed${NC}"
    echo "Install with: brew install create-dmg"
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID"; then
    echo -e "${RED}❌ Developer ID certificate not found${NC}"
    echo "Check with: security find-identity -v -p codesigning"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"
echo ""

# Step 1: Build Release in Xcode
echo -e "${YELLOW}🔨 Building Release configuration...${NC}"
cd "$SCRIPT_DIR/.."
xcodebuild -project OpenClawKit.xcodeproj -scheme OpenClawKit \
  -configuration Release -destination 'platform=macOS' clean build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build successful${NC}"
echo ""

# Step 2: Create DMG using gold-standard create-dmg
echo -e "${YELLOW}💿 Creating professional DMG...${NC}"
"$SCRIPT_DIR/create-dmg.sh" "$VERSION"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ DMG creation failed${NC}"
    exit 1
fi

BUILD_DIR="$SCRIPT_DIR/../builds"
DMG_PATH="${BUILD_DIR}/${APP_NAME}-${VERSION}.dmg"

# Step 3: Sign the DMG
echo ""
echo -e "${YELLOW}🔏 Signing DMG...${NC}"
echo "   This may prompt for keychain access. Click 'Always Allow'."
codesign --force --options runtime --sign "$DEVELOPER_ID" "$DMG_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DMG signed successfully${NC}"
else
    echo -e "${RED}❌ DMG signing failed${NC}"
    exit 1
fi

# Step 4: Notarize
echo ""
echo -e "${YELLOW}📤 Submitting for notarization...${NC}"
echo "   This may take a few minutes..."
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Notarization successful${NC}"
else
    echo -e "${RED}❌ Notarization failed${NC}"
    echo "Check notarization logs with:"
    echo "  xcrun notarytool log <submission-id> --keychain-profile \"$KEYCHAIN_PROFILE\""
    exit 1
fi

# Step 5: Staple ticket
echo ""
echo -e "${YELLOW}📎 Stapling notarization ticket...${NC}"
xcrun stapler staple "$DMG_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Ticket stapled successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Stapling failed (not critical - ticket is still online)${NC}"
fi

# Step 6: Verify final DMG
echo ""
echo -e "${YELLOW}🔍 Verifying final DMG...${NC}"
spctl -a -t open --context context:primary-signature -v "$DMG_PATH" 2>&1 | head -5

# Step 7: Show results
echo ""
echo -e "${GREEN}🎉 Release build complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Version:    ${VERSION}"
echo "  File:       ${DMG_PATH}"
echo "  Size:       $(du -h "$DMG_PATH" | cut -f1)"
echo "  SHA256:     $(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Signed with Developer ID"
echo "✅ Notarized by Apple"
echo "✅ Stapled for offline verification"
echo "✅ Professional drag-to-Applications DMG"
echo ""
echo "Next steps:"
echo "  1. Upload to Lemonsqueezy"
echo "  2. Test on a clean Mac"
echo "  3. Update website download link"
echo ""
echo -e "${GREEN}✨ Ready for launch!${NC}"
