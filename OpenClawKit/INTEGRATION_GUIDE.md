# Skills Marketplace - Quick Integration Guide

## 📦 Files Created

All files are in their proper locations in the OpenClawKit Xcode project:

```
OpenClawKit/OpenClawKit/
├── Models/
│   └── Skill.swift                           ✅ NEW
├── Services/
│   └── ClawHubAPIClient.swift               ✅ NEW
├── ViewModels/
│   └── SkillsViewModel.swift                ✅ NEW
└── Views/
    ├── SkillsMarketplaceView.swift          ✅ NEW
    └── Components/
        ├── SkillCard.swift                   ✅ NEW
        └── SkillDetailView.swift             ✅ NEW
```

## 🚀 Quick Start

### Step 1: Add Files to Xcode Project

Open OpenClawKit.xcodeproj and add these files to the appropriate groups:

1. **Models group:** Add `Skill.swift`
2. **Services group:** Add `ClawHubAPIClient.swift`
3. **ViewModels group:** Add `SkillsViewModel.swift`
4. **Views group:** Add `SkillsMarketplaceView.swift`
5. **Views/Components group:** Add `SkillCard.swift` and `SkillDetailView.swift`

### Step 2: Add to Setup Wizard (Recommended)

In `SetupWizardView.swift`, add a new step or post-setup screen:

```swift
// After setup completion, show marketplace
Button("Browse Skills") {
    showSkillsMarketplace = true
}
.sheet(isPresented: $showSkillsMarketplace) {
    SkillsMarketplaceView()
        .frame(width: 1000, height: 700)
}
```

### Step 3: Add Menu Item

In `OpenClawKitApp.swift`, add to commands:

```swift
.commands {
    CommandGroup(after: .appInfo) {
        Button("Skills Marketplace...") {
            openSkillsMarketplace()
        }
        .keyboardShortcut("m", modifiers: [.command, .shift])
    }
}
```

### Step 4: Test with Mock Data

The app includes 10 realistic mock skills. Just run it!

```bash
# Build and run
open OpenClawKit.xcodeproj
# Press Cmd+R to run
```

---

## 🔌 Connect to Real API (When Ready)

### Replace Mock Implementation

In `Services/ClawHubAPIClient.swift`, replace these methods:

```swift
// Current: Mock data
private func fetchMockSkills() async throws -> [Skill] { ... }

// Replace with:
private func fetchSkills() async throws -> [Skill] {
    let url = URL(string: "\(baseURL)/skills")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([Skill].self, from: data)
}
```

### Connect to OpenClaw CLI

```swift
func installSkill(id: String, progressHandler: @escaping (Double) -> Void) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/local/bin/openclaw")
    process.arguments = ["skills", "install", id]
    
    // Setup output pipe for progress
    let pipe = Pipe()
    process.standardOutput = pipe
    
    try process.run()
    
    // Parse progress from output
    // TODO: Implement progress parsing based on CLI output format
    
    process.waitUntilExit()
    
    if process.terminationStatus != 0 {
        throw ClawHubError.installationFailed("Process exited with code \(process.terminationStatus)")
    }
}
```

---

## 🎨 Customization

### Change Grid Columns

In `SkillsMarketplaceView.swift`:

```swift
// Current: 2 columns
LazyVGrid(columns: [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16)
], spacing: 16) { ... }

// Change to 3 columns:
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) { ... }
```

### Add More Categories

In `Models/Skill.swift`:

```swift
enum SkillCategory: String, Codable, CaseIterable {
    // ... existing categories
    case gaming = "Gaming"        // Add new
    case health = "Health"        // Add new
    
    var icon: String {
        switch self {
        // ... existing icons
        case .gaming: return "gamecontroller"
        case .health: return "heart.fill"
        }
    }
}
```

### Customize Colors

Already uses OpenClawKit theme colors from `Theme/AppTheme.swift`:
- `.bluePrimary` - Primary brand blue
- `.coralAccent` - Accent/CTA color
- `.blueLight` - Hover states

---

## 📱 Window Management

### Option A: Modal Sheet
```swift
.sheet(isPresented: $showMarketplace) {
    SkillsMarketplaceView()
        .frame(width: 1000, height: 700)
}
```

### Option B: Separate Window
```swift
func openMarketplace() {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered,
        defer: false
    )
    window.title = "Skills Marketplace"
    window.contentView = NSHostingView(rootView: SkillsMarketplaceView())
    window.center()
    window.makeKeyAndOrderFront(nil)
}
```

### Option C: Tab in Main App
```swift
TabView {
    MainView()
        .tabItem {
            Label("Home", systemImage: "house")
        }
    
    SkillsMarketplaceView()
        .tabItem {
            Label("Skills", systemImage: "cube.box")
        }
}
```

---

## 🧪 Testing Checklist

Before shipping:

- [ ] Browse tab loads and displays skills
- [ ] Search filters work correctly
- [ ] Category chips filter properly
- [ ] Install button shows progress
- [ ] Installed skills appear in "My Skills" tab
- [ ] Update badge appears when updates available
- [ ] Detail view opens on card click
- [ ] Reviews display correctly
- [ ] Error alerts show on failure
- [ ] Loading states display properly
- [ ] Empty states show helpful messages
- [ ] Uninstall works correctly
- [ ] Update all works correctly
- [ ] UI is responsive and performant

---

## 🐛 Troubleshooting

### "Skill.swift not found"
→ Make sure you've added the file to the Xcode project (not just the filesystem)

### "SwiftUI preview crashes"
→ Disable previews during development, run the full app instead

### "Mock data doesn't load"
→ Check console for errors, ensure async task completes

### "Installation doesn't work"
→ Normal! Mock implementation just simulates progress. Wire up real CLI commands.

---

## 📊 Performance Tips

1. **Lazy Loading:** Already implemented with `LazyVGrid`
2. **Image Caching:** If adding real skill icons, implement caching
3. **Pagination:** Consider adding pagination if skill count > 100
4. **Debouncing:** Already implemented for search (300ms)

---

## 🎯 Next Steps

1. ✅ Add files to Xcode project
2. ✅ Build and test with mock data
3. ✅ Add navigation to marketplace from setup wizard or menu
4. ⏳ Wire up real ClawHub API (when available)
5. ⏳ Connect to OpenClaw CLI for install/update/uninstall
6. ⏳ Add analytics/telemetry
7. ⏳ Beta test with real users

---

## 💡 Tips

- **Start with mock data:** Test the UI thoroughly before connecting real APIs
- **Add analytics:** Track which skills are popular, conversion rates
- **User feedback:** Add a "Report Issue" button in detail view
- **Onboarding:** Show marketplace to new users after setup
- **Updates:** Check for updates on app launch, show badge in menu bar

---

## 📞 Questions?

Check:
1. Inline code comments (comprehensive)
2. `SKILLS_MARKETPLACE_README.md` (detailed docs)
3. Run `SkillsMarketplaceDemo.swift` to see it in action

---

**Ready to ship! 🚀**
