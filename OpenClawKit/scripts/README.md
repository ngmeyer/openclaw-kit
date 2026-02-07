# OpenClawKit Build Scripts

This folder contains helper scripts for building and releasing OpenClawKit.

## Scripts

### `release.sh`

**Complete release build** — builds, signs, notarizes, and creates a professional DMG.

```bash
./scripts/release.sh [version]
```

Examples:
```bash
./scripts/release.sh 1.0.0
./scripts/release.sh 1.1.0-beta
```

This script:
1. Builds Release configuration in Xcode
2. Creates a professional DMG with drag-to-Applications layout
3. Signs the DMG with Developer ID
4. Submits to Apple for notarization
5. Staples the notarization ticket
6. Verifies the final package

### `create-dmg.sh`

**Create DMG only** — creates a professional DMG from an existing build.

```bash
./scripts/create-dmg.sh [version]
```

This creates a DMG with:
- Custom background image showing "Drag to Applications"
- OpenClawKit.app on the left
- Applications folder alias on the right
- Proper icon positioning (128x128)
- Clean, professional appearance

## Prerequisites

### Developer ID Certificate

Must be installed in your keychain:

```bash
security find-identity -v -p codesigning
```

Should show: `Developer ID Application: Neal Meyer (DXK5RE42H2)`

### Notarytool Profile

Configure once:

```bash
xcrun notarytool store-credentials "OpenClawKit-Notarize" \
  --apple-id goatboy160@yahoo.com \
  --team-id DXK5RE42H2 \
  --password <app-specific-password>
```

## Usage

### Full Release (Recommended)

```bash
cd /Users/nealme/clawd/openclaw-kit/OpenClawKit
./scripts/release.sh 1.0.0
```

This does everything: build → DMG → sign → notarize → staple.

### Just Create DMG (Testing)

If you already have a Release build and just want to test the DMG:

```bash
./scripts/create-dmg.sh 1.0.0
```

## Output

Both scripts create:
- `builds/OpenClawKit-{VERSION}.dmg`

The DMG shows:
```
┌─────────────────────────────────┐
│      OpenClawKit                │
│  Drag the app to the            │
│  Applications folder            │
│                                 │
│   [App Icon]      →    [Apps]   │
│                                 │
│   OpenClawKit    Applications   │
└─────────────────────────────────┘
```

## Troubleshooting

**"Could not find DerivedData path"**
→ Run the full release.sh script, or build manually in Xcode first

**Keychain prompt appears**
→ Click "Always Allow" to let codesign access your keychain

**Notarization fails**
→ Check logs: `xcrun notarytool log <id> --keychain-profile "OpenClawKit-Notarize"`

**DMG layout looks wrong**
→ The AppleScript may need adjustment for your screen size. Edit create-dmg.sh and adjust the `bounds` values.

## Distribution

After successful build:

1. **Test locally**: Double-click DMG, verify layout, drag to Applications, launch
2. **Test on clean Mac**: Copy to a Mac without OpenClaw installed
3. **Upload to Lemonsqueezy**: Set as the downloadable file for the product
4. **Update website**: Update download link on openclawkit.ai

## Manual Steps (if scripts fail)

If scripts don't work, you can create the DMG manually:

1. Build Release in Xcode
2. Open Disk Utility → File → New Image → Blank Image
3. Mount the image, copy app, create Applications alias
4. Use View → Show View Options to arrange icons
5. Convert to compressed (UDZO) format
6. Sign: `codesign --sign "Developer ID..." OpenClawKit.dmg`
7. Notarize: `xcrun notarytool submit ...`
8. Staple: `xcrun stapler staple OpenClawKit.dmg`
