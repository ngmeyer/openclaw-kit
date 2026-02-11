# Mission Control Integration Guide

## Quick Start: Adding Mission Control to OpenClawKit

### Option 1: Add as New Window (Recommended)

In `OpenClawKitApp.swift`, add this window to the `body`:

```swift
// Add after the main WindowGroup
Window("Mission Control", id: "mission-control") {
    MissionControlView()
        .frame(minWidth: 1200, minHeight: 800)
}
.windowStyle(.hiddenTitleBar)
.defaultSize(width: 1400, height: 900)
.commands {
    CommandGroup(after: .newItem) {
        Button("Open Mission Control") {
            if let url = URL(string: "openclawkit://mission-control") {
                NSWorkspace.shared.open(url)
            }
        }
        .keyboardShortcut("m", modifiers: [.command, .shift])
    }
}
```

Then add a menu item or button to open it:

```swift
// In your menu or toolbar
Button("Mission Control") {
    NSWorkspace.shared.open(URL(string: "openclawkit://mission-control")!)
}
```

### Option 2: Add as Tab in Main Window

If you have a tab-based interface:

```swift
TabView {
    // Existing tabs...
    
    MissionControlView()
        .tabItem {
            Label("Mission Control", systemImage: "square.grid.2x2")
        }
}
```

### Option 3: Add as Sheet/Modal

If you want it as a modal overlay:

```swift
struct MainView: View {
    @State private var showingMissionControl = false
    
    var body: some View {
        // Your main content
        
        Button("Open Mission Control") {
            showingMissionControl = true
        }
        .sheet(isPresented: $showingMissionControl) {
            MissionControlView()
                .frame(width: 1400, height: 900)
        }
    }
}
```

## Step-by-Step Integration

### 1. Verify Files Are in Place

Ensure all files are in the Xcode project:

```
OpenClawKit/OpenClawKit/
├── Models/
│   ├── MissionTask.swift
│   └── MissionAgent.swift
├── Services/
│   └── MissionDatabase.swift
├── ViewModels/
│   └── MissionControlViewModel.swift
└── Views/MissionControl/
    ├── MissionControlView.swift
    ├── TaskCard.swift
    ├── TaskDetailView.swift
    ├── PlanningView.swift
    └── AgentMonitorView.swift
```

### 2. Add Files to Xcode Target

1. Open Xcode project
2. Right-click on the project navigator
3. Select "Add Files to OpenClawKit..."
4. Navigate to the files above
5. Check **"Copy items if needed"** ✅
6. Check **"Add to targets: OpenClawKit"** ✅
7. Click **Add**

### 3. Build and Test

```bash
# Clean build folder
cmd + shift + K

# Build project
cmd + B

# Run app
cmd + R
```

### 4. Test Basic Functionality

1. Open Mission Control window/view
2. Click **"+ New Task"**
3. Create a sample task
4. Answer planning questions
5. Drag task to different columns
6. Open **Agent Monitor**
7. Restart app and verify data persists

## Troubleshooting

### Build Errors

**Error: Cannot find 'MissionTask' in scope**
- Solution: Make sure `MissionTask.swift` is added to the Xcode target
- Check: File Inspector → Target Membership → OpenClawKit ✅

**Error: Cannot find 'MissionDatabase' in scope**
- Solution: Add `MissionDatabase.swift` to target
- Make sure the class is marked as `public` or in the same module

**Error: Cannot find type 'Color' in scope**
- Solution: Import SwiftUI at the top of the file
- Add: `import SwiftUI`

### Runtime Issues

**Mission Control window is blank**
- Check: MissionControlView is being initialized correctly
- Check: ViewModel is loading data (check console logs)
- Try: Restart app and check data files exist

**Tasks not persisting**
- Check: App has file system permissions
- Check: `~/Library/Application Support/OpenClawKit/MissionControl/` exists
- Look for error logs in console

**Drag and drop not working**
- Check: macOS version supports drag and drop
- Try: Enable developer mode: `defaults write com.apple.dt.Xcode DVTEnableCoreDevice enabled`

## Customization

### Change Theme Colors

In `MissionControlView.swift`, modify the colors:

```swift
// Background
.background(Color(hex: "#0A0A0F")) // Change this

// Button colors
.background(Color(hex: "#3B82F6")) // Change primary button color
```

### Add Custom Status Columns

In `MissionTask.swift`, modify `TaskStatus` enum:

```swift
enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case planning = "PLANNING"
    case inbox = "INBOX"
    // Add your custom statuses here
    case yourStatus = "YOUR_STATUS"
    case assigned = "ASSIGNED"
    // ...
}
```

### Change Planning Questions

In `MissionControlViewModel.swift`, modify `generatePlanningQuestions()`:

```swift
private func generatePlanningQuestions() {
    let defaultQuestions = [
        "Your custom question 1?",
        "Your custom question 2?",
        // Add more...
    ]
    
    // ...
}
```

## Next: OpenClaw Integration

To connect Mission Control to real AI agents:

### 1. Add OpenClaw API Client

```swift
// In Services/OpenClawAPI.swift
class OpenClawAPI {
    let baseURL = "http://localhost:18789"
    
    func spawnAgent(config: AgentSpawnConfig) async throws -> String {
        // POST /v1/sessions/spawn
        // Return session key
    }
    
    func getSessionStatus(sessionKey: String) async throws -> SessionStatus {
        // GET /v1/sessions/{sessionKey}
    }
}
```

### 2. Update ViewModel

```swift
// In MissionControlViewModel.swift
func spawnAgent(for task: MissionTask, config: AgentSpawnConfig) async {
    let agent = MissionAgent(...)
    
    do {
        try database.saveAgent(agent)
        agents.append(agent)
        
        // Actually spawn via OpenClaw
        let api = OpenClawAPI()
        let sessionKey = try await api.spawnAgent(config: config)
        
        agent.sessionKey = sessionKey
        try database.saveAgent(agent)
        
        assignTask(task, to: agent)
    } catch {
        self.error = .agentSpawnFailed(error.localizedDescription)
    }
}
```

### 3. Add Polling for Updates

```swift
// In MissionControlViewModel.swift
private func refreshAgentStatus() {
    Task {
        let api = OpenClawAPI()
        
        for agent in agents where agent.sessionKey != nil {
            if let status = try? await api.getSessionStatus(sessionKey: agent.sessionKey!) {
                // Update agent status
                var updatedAgent = agent
                updatedAgent.updateStatus(status.isRunning ? .working : .idle)
                try? database.saveAgent(updatedAgent)
            }
        }
        
        // Reload agents
        agents = try database.loadAgents()
    }
}
```

## Resources

- **Spec:** `/Users/nealme/clawd/projects/openclaw-kit/MISSION_CONTROL_SPEC.md`
- **Implementation:** `/Users/nealme/clawd/projects/openclaw-kit/MISSION_CONTROL_IMPLEMENTATION.md`
- **Data Storage:** `~/Library/Application Support/OpenClawKit/MissionControl/`
- **Original Inspiration:** https://github.com/crshdn/mission-control

## Support

For questions or issues:
1. Check console logs for errors
2. Verify all files are in Xcode target
3. Test with a clean build (cmd + shift + K)
4. Check data persistence in Application Support folder

---

**Last Updated:** February 10, 2026  
**For:** OpenClawKit v1.0
