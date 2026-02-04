# OpenClawKit Beta Release Checklist

## ✅ Completed Tasks

### 1. Code Committed to GitHub
- All SwiftUI code pushed to main branch
- Commit history includes licensing, theming, and tests

### 2. App & Website Styling Matched
- Created `AppTheme.swift` with website colors:
  - Blue Primary: #1E3A8A
  - Coral Accent: #FB7C4A
- Updated all UI components to use consistent theme
- Floating orb backgrounds use brand colors

### 3. App Icons
- Already created in all required sizes (16px to 1024px)
- Located in `Assets.xcassets/AppIcon.appiconset/`

### 4. Sandbox Issues Fixed
- `ENABLE_APP_SANDBOX = NO` in project settings
- Entitlements file created

### 5. @AlexFinn Research
- Research completed (no specific DMG/licensing content found from this source)
- General best practices applied from other sources

### 6. NVIDIA Kimi K2.5 Default
- Added as first provider option
- `requiresApiKey = false` for free tier
- Default model: `nvidia/kimi-k2.5`

### 7. Tests Written
- Unit tests for:
  - SetupStep
  - AIProvider
  - MessagingChannel
  - KeychainHelper
  - IntegrityChecker
  - LicenseError
  - LemonSqueezy response parsing
- UI tests for app launch

### 8. DMG Installer Script
- `scripts/build-dmg.sh` created
- Supports:
  - Custom background
  - Drag-to-Applications layout
  - Code signing (`--sign`)
  - Notarization (`--notarize`)

### 9. License System
- Lemonsqueezy integration complete
- KeychainHelper for secure storage
- License validation with 7-day offline grace period
- Machine ID binding
- License step added to wizard

### 10. Security/Anti-Crack
- IntegrityChecker with:
  - Code signature validation
  - Debugger detection
  - Bundle ID verification
- License stored encrypted in Keychain
- Machine-specific binding

---

## 🔲 Remaining Tasks (For Beta)

### Before Building DMG

1. **Configure Xcode CLI** (requires Neal):
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. **Update Lemonsqueezy IDs** in `LicenseService.swift`:
   ```swift
   private let storeId = YOUR_STORE_ID
   private let productId = YOUR_PRODUCT_ID
   ```

3. **Update Code Signing Identity** in `scripts/build-dmg.sh`:
   ```bash
   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
   ```

4. **Create DMG Background** (600x400 PNG):
   - Save to `assets/dmg-background.png`
   - Include arrow pointing from app to Applications folder

5. **Set up notarization profile** (one-time):
   ```bash
   xcrun notarytool store-credentials "OpenClawKit" \
     --apple-id your@email.com \
     --team-id TEAMID
   ```

### Testing on Various Mac Setups

Options for multi-machine testing:
1. **Virtual machines** - UTM or VMware with different macOS versions
2. **TestFlight** - For Mac Catalyst (if converted)
3. **Manual beta testers** - Send DMG to friends with different Macs
4. **CI/CD** - GitHub Actions with macOS runners

### Running the Build

```bash
# Without signing (for internal testing)
./scripts/build-dmg.sh

# With signing (for distribution)
./scripts/build-dmg.sh --sign

# With signing + notarization (for public release)
./scripts/build-dmg.sh --notarize
```

---

## 📋 Beta Testing Checklist

### Test on These Configurations:
- [ ] macOS 12 Monterey (Intel)
- [ ] macOS 13 Ventura (Apple Silicon)
- [ ] macOS 14 Sonoma (Apple Silicon)
- [ ] macOS 15 Sequoia (Apple Silicon)
- [ ] Fresh Mac (no Node.js installed)
- [ ] Mac with existing Node.js
- [ ] Mac with existing OpenClaw installation

### Features to Test:
- [ ] License activation flow
- [ ] Invalid license key error handling
- [ ] System check (Node.js detection)
- [ ] Installation progress
- [ ] NVIDIA Kimi setup (no API key needed)
- [ ] Anthropic setup (API key required)
- [ ] Channel configuration
- [ ] Gateway launch
- [ ] DMG drag-to-install experience
- [ ] Gatekeeper approval (notarized build)

---

## 🚀 Release Steps

1. Update version number in Xcode project
2. Run all tests: `xcodebuild test -project OpenClawKit.xcodeproj -scheme OpenClawKit`
3. Build DMG: `./scripts/build-dmg.sh --notarize`
4. Upload DMG to website/CDN
5. Update Lemonsqueezy product with download link
6. Announce beta!
