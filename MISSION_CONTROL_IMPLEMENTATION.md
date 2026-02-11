# Mission Control Implementation Guide

## Overview

Mission Control is a multi-agent orchestration dashboard for OpenClawKit, enabling users to manage AI agents working on complex tasks simultaneously. This document describes the Phase 2 implementation.

**Version:** 2.0.0  
**Last Updated:** February 10, 2026  
**Status:** ✅ Feature Complete (MVP)

---

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      OpenClawKit.app                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ChatView (Main Interface)                                │  │
│  │  ┌──────────────────────────────────────────────────────┐│  │
│  │  │ [Mission Control Button] → Opens MissionControlView ││  │
│  │  └──────────────────────────────────────────────────────┘│  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  MissionControlView (Kanban Dashboard)                    │  │
│  │  ├── KanbanColumn × 5 (Planning, Inbox, Assigned, etc.)  │  │
│  │  ├── TaskCard (Draggable task cards)                      │  │
│  │  ├── TaskDetailView (Task info + timeline)                │  │
│  │  ├── AgentMonitorView (Live agent list)                   │  │
│  │  └── PlanningView (AI Q&A before execution)               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Services Layer                                           │  │
│  │  ├── OpenClawGateway (API client for agent management)   │  │
│  │  ├── MissionDatabase (JSON file persistence)              │  │
│  │  └── MissionControlViewModel (State management)           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                   OpenClaw Gateway
                   (localhost:18789)
                              │
                              ▼
                    AI Providers (via Gateway)
```

---

## File Structure

```
OpenClawKit/
├── Models/
│   ├── MissionTask.swift          # Task data model
│   └── MissionAgent.swift         # Agent data model
├── ViewModels/
│   └── MissionControlViewModel.swift  # State management
├── Views/
│   └── MissionControl/
│       ├── MissionControlView.swift   # Main Kanban board
│       ├── TaskCard.swift             # Draggable task card
│       ├── TaskDetailView.swift       # Full task info
│       ├── AgentMonitorView.swift     # Agent list + status
│       └── PlanningView.swift         # AI planning Q&A
├── Services/
│   ├── OpenClawGateway.swift          # Gateway API client
│   └── MissionDatabase.swift          # JSON persistence
└── Theme/
    └── AppTheme.swift                 # Shared colors/styles
```

---

## Components

### 1. MissionControlView.swift (Main Kanban Board)

**Purpose:** Primary dashboard showing tasks in a 5-column Kanban layout.

**Features:**
- 5 columns: Planning, Inbox, Assigned, In Progress, Review
- Drag-and-drop task cards between columns
- Header with agent count and "New Task" button
- Footer with statistics and gateway connection status
- Sheet presentations for task details, planning, and agent monitor

**Key Properties:**
```swift
@StateObject private var viewModel = MissionControlViewModel()
@State private var draggedTask: MissionTask?
```

**Sheets:**
- `showingTaskDetail` → TaskDetailView
- `showingPlanningView` → PlanningView
- `showingAgentMonitor` → AgentMonitorView
- `showingNewTaskSheet` → NewTaskSheet

### 2. TaskCard.swift (Draggable Task Component)

**Purpose:** Individual task card displayed in Kanban columns.

**Features:**
- Priority indicator with icon
- Agent assignment badge
- Description preview (2 lines)
- Planning Q&A count indicator
- Deliverables count indicator
- Relative timestamp ("2h ago")
- Tags display (up to 3)
- Border color based on status

**Drag Support:**
```swift
.onDrag {
    self.draggedTask = task
    return NSItemProvider(object: task.id.uuidString as NSString)
}
```

### 3. TaskDetailView.swift (Full Task Info + Timeline)

**Purpose:** Detailed view of a single task with all metadata.

**Sections:**
1. **Header:** Title (editable), status badge, priority badge
2. **Task Info:** Description, created/updated dates
3. **Planning Q&A:** Questions and answers from planning phase
4. **Deliverables:** List of task outputs
5. **Agent Assignment:** Current agent or "Spawn Agent" button
6. **Actions:** Status change buttons, delete button

**Edit Mode:**
- Toggle edit mode for title/description
- Auto-saves on "Save" button

### 4. AgentMonitorView.swift (Live Agent List)

**Purpose:** Monitor all agents with their status and current tasks.

**Sections:**
1. **Active Agents:** Currently working agents
2. **Available Agents:** Idle agents ready for tasks
3. **Other Agents:** Error/offline agents

**Agent Card Features:**
- Status indicator (green/yellow/red)
- Role icon and name
- Model badge (sonnet, kimi, etc.)
- Activity description
- Current task (if assigned)
- Task completion count
- Last activity timestamp
- Stop/Delete actions

**Footer Stats:**
- Working count
- Available count
- Total tasks completed

### 5. PlanningView.swift (AI Planning + Questions)

**Purpose:** Guided Q&A flow before task execution.

**Flow:**
1. Display current question
2. User enters answer
3. "Next Question" or "Skip"
4. Repeat until all questions answered
5. "Complete Planning" → Move task to Inbox

**Default Questions:**
1. What is the primary goal of this task?
2. Who is the target audience or beneficiary?
3. What are the key requirements or constraints?
4. What deliverables are expected?
5. What skills or capabilities are needed?

**Completion:**
- Saves Q&A pairs to task
- Moves task to Inbox status
- Shows TaskDetailView for agent spawning

---

## Data Models

### MissionTask

```swift
struct MissionTask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var status: TaskStatus
    var assignedAgent: String?
    var createdAt: Date
    var updatedAt: Date
    var planningQA: [QAPair]
    var deliverables: [Deliverable]
    var priority: TaskPriority
    var tags: [String]
}

enum TaskStatus: String, Codable, CaseIterable {
    case planning, inbox, assigned, inProgress, testing, review, done
}

enum TaskPriority: String, Codable, CaseIterable {
    case low, medium, high, urgent
}
```

### MissionAgent

```swift
struct MissionAgent: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var sessionKey: String?
    var status: AgentStatus
    var currentTask: UUID?
    var capabilities: [String]
    var createdAt: Date
    var lastActivity: Date
    var model: String
    var totalTasksCompleted: Int
}

enum AgentStatus: String, Codable {
    case idle, working, waiting, error, offline
}
```

### AgentMessage

```swift
struct AgentMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let fromAgent: UUID
    let toAgent: UUID?
    var message: String
    let timestamp: Date
    var messageType: MessageType
    
    enum MessageType: String, Codable {
        case communication, taskClaim, taskHandoff, 
             agreement, refutation, praise, question, update
    }
}
```

---

## Services

### OpenClawGateway.swift

**Purpose:** API client for OpenClaw Gateway communication.

**Configuration:**
- Reads from `~/.openclaw/openclaw.json`
- Default: `http://localhost:18789`

**Methods:**
```swift
// Connection
func checkConnection() async

// Sessions
func listSessions(kinds: [String]?, limit: Int) async throws -> [SessionInfo]
func spawnAgent(config: AgentSpawnRequest) async throws -> SpawnResponse
func sendMessage(sessionKey: String, message: String) async throws -> MessageResponse
func getSessionHistory(sessionKey: String, limit: Int) async throws -> [HistoryMessage]
func stopSession(sessionKey: String) async throws

// Streaming
func subscribeToEvents(sessionKey: String, onEvent: @escaping (SessionEvent) -> Void)
func unsubscribeFromEvents()

// Chat
func chat(message: String, model: String?, sessionId: String?, 
          onChunk: @escaping (String) -> Void,
          onComplete: @escaping () -> Void,
          onError: @escaping (Error) -> Void)
```

### MissionDatabase.swift

**Purpose:** JSON file-based persistence for tasks, agents, and messages.

**Storage Location:** `~/Library/Application Support/OpenClawKit/MissionControl/`

**Files:**
- `tasks.json` - All tasks
- `agents.json` - All agents
- `messages.json` - Agent messages

**Methods:**
```swift
// Tasks
func saveTask(_ task: MissionTask) throws
func loadTasks() throws -> [MissionTask]
func deleteTask(_ taskId: UUID) throws

// Agents
func saveAgent(_ agent: MissionAgent) throws
func loadAgents() throws -> [MissionAgent]
func deleteAgent(_ agentId: UUID) throws

// Messages
func saveMessage(_ message: AgentMessage) throws
func loadMessages(forAgent agentId: UUID, limit: Int) throws -> [AgentMessage]
func loadRecentMessages(limit: Int) throws -> [AgentMessage]

// Management
func clearAllData() throws
func getStatistics() throws -> DatabaseStatistics
```

---

## ViewModel

### MissionControlViewModel

**Purpose:** Central state management for Mission Control.

**Published Properties:**
```swift
@Published var tasks: [MissionTask]
@Published var agents: [MissionAgent]
@Published var recentMessages: [AgentMessage]
@Published var selectedTask: MissionTask?
@Published var selectedAgent: MissionAgent?
@Published var isLoading: Bool
@Published var error: MissionError?
@Published var isGatewayConnected: Bool
@Published var stats: TaskStatistics

// Sheet control
@Published var showingTaskDetail: Bool
@Published var showingPlanningView: Bool
@Published var showingAgentMonitor: Bool
@Published var showingNewTaskSheet: Bool

// Planning state
@Published var planningTask: MissionTask?
@Published var currentQuestion: String
@Published var planningQuestions: [QAPair]
@Published var isPlanningComplete: Bool
```

**Key Methods:**
```swift
// Data
func loadData()
func updateStatistics()

// Tasks
func createTask(title: String, description: String, priority: TaskPriority)
func updateTask(_ task: MissionTask)
func deleteTask(_ task: MissionTask)
func moveTask(_ task: MissionTask, to status: TaskStatus)
func assignTask(_ task: MissionTask, to agent: MissionAgent)

// Planning
func startPlanning(for task: MissionTask)
func answerPlanningQuestion(_ answer: String)

// Agents
func spawnAgent(for task: MissionTask, config: AgentSpawnConfig) async
func stopAgent(_ agent: MissionAgent)
func deleteAgent(_ agent: MissionAgent)

// Messages
func sendMessage(from: UUID, to: UUID?, message: String, type: MessageType)

// Helpers
func tasks(for status: TaskStatus) -> [MissionTask]
var availableAgents: [MissionAgent]
var workingAgents: [MissionAgent]
```

---

## Integration with ChatView

Mission Control is accessed via a button in the ChatView header:

```swift
// In ChatHeaderView
Button(action: onMissionControl) {
    HStack(spacing: 6) {
        Image(systemName: "square.grid.3x3")
        Text("Mission Control")
    }
    .foregroundColor(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
        LinearGradient(
            colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6")],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .cornerRadius(8)
}

// In ChatView body
.sheet(isPresented: $showingMissionControl) {
    MissionControlView()
        .frame(minWidth: 1200, minHeight: 800)
}
```

---

## Theme & Styling

Mission Control uses the app's dark theme:

**Background:** `Color(hex: "#0A0A0F")`

**Status Colors:**
- Planning: `#9333EA` (Purple)
- Inbox: `#3B82F6` (Blue)
- Assigned: `#F59E0B` (Amber)
- In Progress: `#10B981` (Green)
- Testing: `#F97316` (Orange)
- Review: `#8B5CF6` (Violet)
- Done: `#6B7280` (Gray)

**Agent Status Colors:**
- Idle: `#6B7280` (Gray)
- Working: `#10B981` (Green)
- Waiting: `#F59E0B` (Amber)
- Error: `#EF4444` (Red)
- Offline: `#374151` (Dark Gray)

---

## Quality Gates

### ✅ Completed

- [x] All Swift files compile without errors
- [x] No memory leaks (weak captures, proper cleanup)
- [x] Thread-safe state management (@MainActor)
- [x] Error handling for network failures
- [x] Beautiful UI matching OpenClawKit design
- [x] Gateway connection status indicator
- [x] Real-time agent status updates
- [x] Drag-and-drop task management
- [x] Persistent storage (JSON files)
- [x] Task lifecycle management
- [x] Agent spawning via Gateway API
- [x] Planning workflow with Q&A

### ⚠️ Known Limitations

1. **SSE Streaming:** Event streaming needs Gateway support for real SSE
2. **Multi-Agent Communication:** Phase 4 feature (agents talking to each other)
3. **Task Auto-Claiming:** Phase 4 feature (agents autonomously claim tasks)
4. **Deliverable Viewing:** Currently shows list, needs viewer implementation

---

## Testing Recommendations

### Manual Testing

1. **Task Flow:**
   - Create new task → Should appear in Planning column
   - Complete planning → Should move to Inbox
   - Spawn agent → Should move to Assigned
   - Agent completes → Should move to Review
   - Approve → Should move to Done

2. **Drag-Drop:**
   - Drag task between columns
   - Verify status updates
   - Check database persistence

3. **Agent Management:**
   - Spawn agent from task detail
   - Monitor agent in AgentMonitorView
   - Stop agent and verify cleanup

4. **Gateway Connection:**
   - Start with gateway running → Green status
   - Stop gateway → Red status
   - Restart gateway → Auto-reconnect

### Automated Testing

```swift
// Recommended test cases
func testTaskCreation()
func testTaskStatusTransitions()
func testAgentSpawning()
func testPlanningWorkflow()
func testDatabasePersistence()
func testGatewayConnection()
```

---

## File Summary

| File | Lines | Description |
|------|-------|-------------|
| MissionControlView.swift | ~200 | Main Kanban board |
| TaskCard.swift | ~120 | Draggable task card |
| TaskDetailView.swift | ~300 | Full task info |
| AgentMonitorView.swift | ~350 | Agent list + status |
| PlanningView.swift | ~200 | Planning Q&A |
| MissionDatabase.swift | ~180 | JSON persistence |
| MissionTask.swift | ~180 | Task model |
| MissionAgent.swift | ~220 | Agent model |
| MissionControlViewModel.swift | ~450 | State management |
| OpenClawGateway.swift | ~380 | Gateway API client |
| **Total** | **~2,580** | |

---

## Ready for QA?

**YES** ✅

The Mission Control feature is feature-complete for MVP and ready for QA testing. All core functionality works:

- Task creation, editing, deletion
- Kanban drag-and-drop
- Planning workflow
- Agent spawning (with Gateway)
- Agent monitoring
- Persistent storage
- Gateway connection status

---

## Next Steps (Phase 3+)

1. **Deliverable Viewer:** View/download agent outputs
2. **Agent Chat:** Send messages to running agents
3. **Multi-Agent Orchestration:** Agents communicate and coordinate
4. **Task Templates:** Pre-configured task types
5. **Performance Metrics:** Track agent success rates
6. **Voice Control:** Create tasks via voice

---

*Last updated: February 10, 2026*
