# Mission Control for OpenClawKit 🚀

**A multi-agent task orchestration dashboard built in SwiftUI**

![Status](https://img.shields.io/badge/status-Phase%201%20Complete-green)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)

---

## What is Mission Control?

Mission Control is a Kanban-style dashboard for managing AI agents working on multiple tasks simultaneously. Think "JIRA for AI agents" - you create tasks, AI helps plan them, and agents autonomously execute while you monitor progress.

### Key Features ✨

- **📋 Kanban Board** - 7-column workflow (Planning → Done)
- **🧠 AI Planning** - Q&A-based task requirements gathering
- **🤖 Agent Management** - Spawn, monitor, and manage AI agents
- **📊 Real-time Stats** - Track tasks, agents, and completion rates
- **💾 Persistent Data** - JSON-based storage for all mission data
- **🎨 Beautiful UI** - Dark theme, smooth animations, intuitive UX

---

## Quick Start

### 1. Files Included

All implementation files are in `/projects/openclaw-kit/OpenClawKit/OpenClawKit/`:

```
├── Models/
│   ├── MissionTask.swift          # Task data model
│   └── MissionAgent.swift         # Agent data model
├── Services/
│   └── MissionDatabase.swift      # JSON storage layer
├── ViewModels/
│   └── MissionControlViewModel.swift # State management
└── Views/MissionControl/
    ├── MissionControlView.swift   # Main dashboard
    ├── TaskCard.swift             # Task card component
    ├── TaskDetailView.swift       # Task detail modal
    ├── PlanningView.swift         # AI planning Q&A
    └── AgentMonitorView.swift     # Agent monitoring
```

### 2. Integration

**See:** [MISSION_CONTROL_INTEGRATION.md](./MISSION_CONTROL_INTEGRATION.md) for detailed steps.

**Quick option:** Add to `OpenClawKitApp.swift`:

```swift
Window("Mission Control", id: "mission-control") {
    MissionControlView()
}
.windowStyle(.hiddenTitleBar)
.defaultSize(width: 1400, height: 900)
```

### 3. Build & Run

```bash
# Open in Xcode
open OpenClawKit/OpenClawKit.xcodeproj

# Clean build
cmd + shift + K

# Build & run
cmd + R
```

---

## User Workflow

### Creating a Task

1. Click **"+ New Task"** button
2. Enter title, description, and priority
3. Task enters **PLANNING** status
4. AI presents 5 clarifying questions
5. Answer questions (or skip)
6. Task moves to **INBOX**
7. Ready for agent assignment!

### Spawning an Agent

1. Open task detail (click task card)
2. Scroll to "Agent Assignment" section
3. Click **"Spawn Agent"** button
4. Agent is created with role based on task
5. Task moves to **ASSIGNED** status
6. Agent begins work (future: OpenClaw integration)

### Managing Tasks

- **Drag & Drop** - Move tasks between columns
- **Edit** - Click task → pencil icon → modify
- **Delete** - Click task → scroll down → Delete Task
- **View Details** - Click any task card

### Monitoring Agents

1. Click the agent counter badge in header
2. View all agents grouped by status:
   - **Active** (working on tasks)
   - **Available** (idle, ready for work)
   - **Other** (offline, error, etc.)
3. View agent details, stop, or delete agents

---

## Architecture

### Data Flow

```
User Action
    ↓
MissionControlView (SwiftUI)
    ↓
MissionControlViewModel (ObservableObject)
    ↓
MissionDatabase (JSON File Storage)
    ↓
~/Library/Application Support/OpenClawKit/MissionControl/*.json
```

### Key Design Decisions

**Why JSON instead of SQLite?**
- No external dependencies
- Easy to debug and inspect
- Simple MVP implementation
- Can migrate to SQLite/Core Data later

**Why separate view files?**
- Modularity and reusability
- Easier testing and maintenance
- Clear separation of concerns

**Why ObservableObject ViewModel?**
- Natural SwiftUI integration
- Centralized state management
- Clean separation of business logic

---

## Status Workflow

Tasks flow through 7 statuses:

```
PLANNING → INBOX → ASSIGNED → IN_PROGRESS → TESTING → REVIEW → DONE
   🧠        📥       👤           ⚙️          ✅         👁️      ✓
```

- **PLANNING** - AI asking clarifying questions
- **INBOX** - Ready for agent assignment
- **ASSIGNED** - Agent assigned, not started
- **IN_PROGRESS** - Agent actively working
- **TESTING** - Agent testing deliverables
- **REVIEW** - Human review required
- **DONE** - Task complete

---

## Data Models

### MissionTask

```swift
struct MissionTask {
    let id: UUID
    var title: String
    var description: String
    var status: TaskStatus
    var assignedAgent: String?
    var planningQA: [QAPair]
    var deliverables: [Deliverable]
    var priority: TaskPriority
    var tags: [String]
    // timestamps...
}
```

### MissionAgent

```swift
struct MissionAgent {
    let id: UUID
    var name: String
    var role: String
    var sessionKey: String?
    var status: AgentStatus
    var currentTask: UUID?
    var capabilities: [String]
    var model: String
    var totalTasksCompleted: Int
    // timestamps...
}
```

---

## Current Status

### ✅ Phase 1: Complete (MVP)

- Kanban board with 7 columns
- Task CRUD operations
- Drag-and-drop task movement
- Planning Q&A workflow (5 default questions)
- Agent data model and UI
- Agent monitor dashboard
- JSON file persistence
- Statistics tracking
- Dark theme UI

### 🚧 Phase 2: In Progress (OpenClaw Integration)

- [ ] Connect to OpenClaw Gateway
- [ ] Actually spawn agents via `/v1/sessions/spawn`
- [ ] Poll for agent status updates
- [ ] Capture agent deliverables
- [ ] Real-time agent progress tracking

### 📅 Phase 3: Planned (Multi-Agent Orchestration)

- [ ] Agent-to-agent communication
- [ ] Autonomous task claiming
- [ ] Conflict resolution UI
- [ ] Inter-agent messaging log
- [ ] Advanced coordination features

### 🔮 Phase 4: Future (Advanced Features)

- [ ] AI-generated planning questions
- [ ] Rich deliverable viewer (code, markdown, images)
- [ ] Voice-activated task creation
- [ ] Export/import tasks (JSON, CSV)
- [ ] Multi-user collaboration
- [ ] Mobile companion app

---

## Testing

**See:** [MISSION_CONTROL_TEST_PLAN.md](./MISSION_CONTROL_TEST_PLAN.md) for complete test cases.

### Quick Test Checklist

- [ ] Create a task
- [ ] Answer planning questions
- [ ] Drag task between columns
- [ ] Edit task details
- [ ] Delete task
- [ ] View agent monitor
- [ ] Restart app (test persistence)
- [ ] Test with 10+ tasks

---

## Performance

### Target Metrics

| Operation | Target | Status |
|-----------|--------|--------|
| Create task | <100ms | ⏳ Not measured |
| Drag/drop | <50ms | ⏳ Not measured |
| Data save | <100ms | ⏳ Not measured |
| Data load | <500ms | ⏳ Not measured |

### Scalability

- Tested with: **1-10 tasks** ✅
- Designed for: **50+ tasks** 🎯
- Future goal: **100+ tasks with 10+ agents** 🚀

---

## File Structure

```
MISSION_CONTROL_*.md         # Documentation
└── OpenClawKit/OpenClawKit/
    ├── Models/
    │   ├── MissionTask.swift       (6KB)
    │   └── MissionAgent.swift      (8KB)
    ├── Services/
    │   └── MissionDatabase.swift   (14KB)
    ├── ViewModels/
    │   └── MissionControlViewModel.swift (14KB)
    └── Views/MissionControl/
        ├── MissionControlView.swift    (12KB)
        ├── TaskCard.swift              (5KB)
        ├── TaskDetailView.swift        (14KB)
        ├── PlanningView.swift          (9KB)
        └── AgentMonitorView.swift      (14KB)
```

**Total:** 8 Swift files, ~96KB of code

---

## Configuration

### Storage Location

```
~/Library/Application Support/OpenClawKit/MissionControl/
├── tasks.json       # All tasks
├── agents.json      # All agents
└── messages.json    # Agent messages
```

### Default Planning Questions

1. What is the primary goal of this task?
2. Who is the target audience or beneficiary?
3. What are the key requirements or constraints?
4. What deliverables are expected?
5. What skills or capabilities are needed?

*(Can be customized in `MissionControlViewModel.swift`)*

---

## Troubleshooting

### Tasks not persisting
- Check app has file system permissions
- Verify directory exists: `~/Library/Application Support/OpenClawKit/MissionControl/`
- Check console for error logs

### Drag and drop not working
- Ensure macOS version is compatible (10.15+)
- Try clean build (cmd + shift + K)
- Check for any SwiftUI errors in console

### Agent spawning doesn't work
- **Expected:** Phase 1 has placeholder only
- **Future:** OpenClaw integration in Phase 2
- Agent is created in database but doesn't execute yet

### UI looks broken
- Verify all view files are added to Xcode target
- Check for missing imports (`import SwiftUI`)
- Try force-reload (cmd + option + P in Simulator)

---

## Contributing

### Adding New Features

1. **New Status Column:** Modify `TaskStatus` enum in `MissionTask.swift`
2. **Custom Questions:** Edit `generatePlanningQuestions()` in ViewModel
3. **New Agent Role:** Add to `determineAgentRole()` in ViewModel
4. **UI Customization:** Modify colors/layout in view files

### Code Style

- SwiftUI best practices
- MVVM architecture
- Clear comments for complex logic
- Consistent naming conventions

---

## Resources

### Documentation
- [Spec Document](./MISSION_CONTROL_SPEC.md) - Original feature specification
- [Implementation Summary](./MISSION_CONTROL_IMPLEMENTATION.md) - What was built
- [Integration Guide](./MISSION_CONTROL_INTEGRATION.md) - How to add to app
- [Test Plan](./MISSION_CONTROL_TEST_PLAN.md) - Comprehensive testing

### Inspiration
- **Original Concept:** [Mission Control by @pbteja1998](https://github.com/crshdn/mission-control)
- **Similar Tools:** Linear, Jira, Asana (but for AI agents!)

---

## License

Part of OpenClawKit (proprietary)

---

## Changelog

### [1.0.0] - 2026-02-10 (Phase 1 MVP)

**Added:**
- Kanban board with 7-column workflow
- Task creation, editing, deletion
- Planning Q&A workflow
- Agent data models and UI
- Agent monitor dashboard
- JSON file persistence
- Statistics tracking
- Dark theme UI

**Known Issues:**
- Agent spawning is placeholder only (no OpenClaw integration yet)
- Planning questions are hardcoded (no AI generation)
- No real-time agent updates (no polling yet)

---

## Roadmap

### Feb 2026 (Phase 2)
- [ ] OpenClaw Gateway integration
- [ ] Real agent spawning
- [ ] Live agent status updates
- [ ] Deliverable capture

### Mar 2026 (Phase 3)
- [ ] Multi-agent coordination
- [ ] Agent-to-agent messaging
- [ ] Autonomous task claiming
- [ ] Advanced monitoring

### Apr 2026 (Phase 4)
- [ ] AI-generated planning
- [ ] Voice commands
- [ ] Rich deliverable viewer
- [ ] Export/import features

---

## Contact

**Project:** OpenClawKit  
**Website:** [openclawkit.ai](https://openclawkit.ai)  
**Support:** support@openclawkit.ai  
**Implementation Date:** February 10, 2026

---

**Built with ❤️ for the future of AI agent orchestration**
