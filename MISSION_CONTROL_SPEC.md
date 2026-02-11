# OpenClawKit: Mission Control Integration
## Feature Spec (Feb 10, 2026)

### Overview
Mission Control is a multi-agent orchestration dashboard for managing AI agents working on complex tasks simultaneously.

**Original:** Next.js web app (separate project)  
**Goal:** Native SwiftUI implementation in OpenClawKit

---

## What Is Mission Control?

**Analogy:** Think project management software (Jira, Asana) but for AI agents instead of humans.

### Core Workflow
1. **User creates task:** "Research best coffee machines under $200"
2. **AI asks clarifying questions:**
   - What's the goal?
   - Who's the audience?
   - Any constraints?
3. **System creates specialized agent** based on answers
4. **Agent executes task:**
   - Browses web
   - Writes code
   - Creates files
   - Reports progress
5. **Deliverable returned** to Mission Control
6. **User reviews and approves**

### Multi-Agent Features
- **10+ agents working simultaneously**
- Agents communicate with each other
- Agents can refute incorrect assumptions
- Agents praise good work
- Agents claim tasks autonomously
- Central coordinator (main agent) oversees

---

## Architecture

### Current (Web App)
```
┌────────────────┐     WS      ┌──────────────────┐
│ Mission Control│ ◄────────► │ OpenClaw Gateway │
│   (Next.js)    │             │   (Port 18789)   │
│   Port 3000    │             └──────────────────┘
└────────────────┘                      │
        │                               │
        ▼                               ▼
   ┌─────────┐                    ┌──────────┐
   │ SQLite  │                    │   AI     │
   │Database │                    │Providers │
   └─────────┘                    └──────────┘
```

### Proposed (Native OpenClawKit)
```
┌────────────────────────────────┐
│      OpenClawKit.app           │
│  ┌──────────────────────────┐  │
│  │  Setup Wizard            │  │
│  └──────────────────────────┘  │
│  ┌──────────────────────────┐  │
│  │  Chat Interface          │  │
│  └──────────────────────────┘  │
│  ┌──────────────────────────┐  │
│  │  Mission Control         │  │ ← NEW
│  │  (Multi-Agent Dashboard) │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘
         │
         ▼
  OpenClaw Gateway
   (localhost:18789)
```

---

## UI Design (SwiftUI)

### Main View: Mission Board
```
┌──────────────────────────────────────────────────────┐
│  Mission Control                        [+ New Task] │
├──────────────────────────────────────────────────────┤
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐│
│  │PLANNING │  INBOX  │ASSIGNED │IN PROG. │ REVIEW  ││
│  ├─────────┼─────────┼─────────┼─────────┼─────────┤│
│  │         │         │         │         │         ││
│  │ ┌─────┐ │ ┌─────┐ │ ┌─────┐ │ ┌─────┐ │ ┌─────┐││
│  │ │Task │ │ │Task │ │ │Task │ │ │Task │ │ │Task │││
│  │ │  #1 │ │ │  #3 │ │ │  #5 │ │ │  #7 │ │ │  #9 │││
│  │ └─────┘ │ └─────┘ │ └─────┘ │ └─────┘ │ └─────┘││
│  │         │         │         │         │         ││
│  │ ┌─────┐ │         │ ┌─────┐ │ ┌─────┐ │         ││
│  │ │Task │ │         │ │Task │ │ │Task │ │         ││
│  │ │  #2 │ │         │ │  #6 │ │ │  #8 │ │         ││
│  │ └─────┘ │         │ └─────┘ │ └─────┘ │         ││
│  └─────────┴─────────┴─────────┴─────────┴─────────┘│
│                                                       │
│  Active Agents: 3 | Tasks Completed Today: 7         │
└──────────────────────────────────────────────────────┘
```

### Task Detail View
```
┌──────────────────────────────────────────┐
│  ← Back to Board                     [⋮] │
├──────────────────────────────────────────┤
│  Research Coffee Machines               │
│  Created: 2 hours ago | Assigned to: AI-3│
├──────────────────────────────────────────┤
│                                          │
│  Description:                            │
│  Find the best coffee machines under    │
│  $200 with good reviews on Amazon.       │
│                                          │
│  Planning Q&A:                           │
│  • Goal: Research for blog post          │
│  • Audience: Coffee enthusiasts          │
│  • Constraints: Budget $200              │
│                                          │
│  Agent Progress:                         │
│  ├─ ✅ Searched Amazon                   │
│  ├─ ✅ Read 47 reviews                   │
│  ├─ 🔄 Compiling comparison table        │
│  └─ ⏸️ Waiting: Write summary            │
│                                          │
│  [View Deliverables]  [Mark as Done]     │
└──────────────────────────────────────────┘
```

### Agent Monitor View
```
┌──────────────────────────────────────────┐
│  Active Agents                       [+] │
├──────────────────────────────────────────┤
│  🟢 Jarvis (Main Coordinator)            │
│     Managing 3 tasks, orchestrating team │
│                                          │
│  🟢 Researcher-01                        │
│     Task: Coffee machine research        │
│     Status: Browsing web (Amazon)        │
│                                          │
│  🟡 Coder-02                             │
│     Task: Build pricing scraper          │
│     Status: Writing Python script        │
│                                          │
│  🔴 Writer-03                            │
│     Status: Idle (waiting for tasks)     │
│                                          │
│  [Spawn New Agent]                       │
└──────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Basic Task Board (Week 1)
**Goal:** Kanban board for tracking tasks

**Features:**
- Create tasks (title + description)
- Drag-and-drop between columns
- Task detail view
- SQLite storage

**UI Components:**
- `MissionControlView.swift` (main board)
- `TaskCard.swift` (draggable card)
- `TaskDetailView.swift` (modal)
- `MissionControlViewModel.swift` (state)

**No AI yet** - just task management

---

### Phase 2: AI Planning (Week 2)
**Goal:** AI asks questions and creates agents

**Features:**
- Click task → AI asks clarifying questions
- User answers via UI (not chat)
- AI generates agent specification
- Agent created and assigned to task

**UI Components:**
- `PlanningView.swift` (Q&A interface)
- `QuestionCard.swift` (single question + answer input)

**API Integration:**
- POST `/v1/responses` with planning prompt
- Parse AI questions
- Collect answers
- Generate agent config

---

### Phase 3: Agent Execution (Week 3)
**Goal:** Agents work on tasks

**Features:**
- Spawn agent via OpenClaw API
- Monitor agent progress
- Show real-time updates
- Receive deliverables

**UI Components:**
- `AgentMonitorView.swift` (list of active agents)
- `AgentDetailView.swift` (single agent activity)
- `DeliverableViewer.swift` (show results)

**API Integration:**
- `sessions_spawn` to create agents
- `sessions_list` to monitor
- `sessions_history` to get results

---

### Phase 4: Multi-Agent Orchestration (Week 4)
**Goal:** Agents communicate & coordinate

**Features:**
- Main agent (Jarvis) coordinates team
- Agents can message each other
- Agents claim tasks autonomously
- Conflict resolution (agents refute/agree)

**UI Components:**
- `AgentChatView.swift` (inter-agent messages)
- `CoordinationLog.swift` (event timeline)

**Architecture:**
- Main agent has special role
- Sub-agents spawned for tasks
- Communication via OpenClaw sessions

---

## Data Model

### Task
```swift
struct MissionTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var status: TaskStatus
    var assignedAgent: String?
    var createdAt: Date
    var updatedAt: Date
    var planningQA: [QAPair]?
    var deliverables: [String]?
}

enum TaskStatus: String, Codable {
    case planning
    case inbox
    case assigned
    case inProgress
    case testing
    case review
    case done
}

struct QAPair: Codable {
    let question: String
    let answer: String
}
```

### Agent
```swift
struct MissionAgent: Identifiable, Codable {
    let id: UUID
    var name: String
    var role: String
    var sessionKey: String
    var status: AgentStatus
    var currentTask: UUID?
    var capabilities: [String]
    var createdAt: Date
}

enum AgentStatus: String, Codable {
    case idle
    case working
    case waiting
    case error
}
```

---

## Database Schema (SQLite)

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL,
    assigned_agent TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    planning_qa TEXT,  -- JSON
    deliverables TEXT  -- JSON
);

CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    session_key TEXT UNIQUE,
    status TEXT NOT NULL,
    current_task TEXT,
    capabilities TEXT,  -- JSON
    created_at INTEGER NOT NULL,
    FOREIGN KEY (current_task) REFERENCES tasks(id)
);

CREATE TABLE agent_messages (
    id TEXT PRIMARY KEY,
    from_agent TEXT NOT NULL,
    to_agent TEXT,
    message TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (from_agent) REFERENCES agents(id),
    FOREIGN KEY (to_agent) REFERENCES agents(id)
);
```

---

## OpenClaw Integration

### Creating Agents
```swift
// Spawn a specialized agent for a task
await sessions_spawn(
    task: "Research coffee machines under $200",
    agentId: "researcher-01",
    model: "sonnet",
    label: "coffee-research"
)
```

### Monitoring Progress
```swift
// List all active agents
let sessions = await sessions_list(
    kinds: ["isolated"],
    limit: 50
)

// Check specific agent
let history = await sessions_history(
    sessionKey: "agent:main:subagent:abc-123"
)
```

### Agent Communication
```swift
// Main agent sends task to worker agent
await sessions_send(
    sessionKey: "agent:main:subagent:worker-01",
    message: "Please research coffee machines and report back"
)
```

---

## MVP Scope (4 weeks)

### Must Have
- ✅ Kanban task board (drag-and-drop)
- ✅ Create/edit tasks
- ✅ AI planning Q&A
- ✅ Agent creation from planning
- ✅ Task dispatch to agents
- ✅ Agent monitoring
- ✅ Deliverable viewing

### Nice to Have
- Multi-agent communication
- Autonomous task claiming
- Conflict resolution UI
- Agent performance metrics

### Later
- Voice-activated task creation
- Mobile companion app (iOS)
- Team collaboration (multiple users)
- Advanced scheduling/prioritization

---

## Success Metrics

### User Experience
- **Task creation to agent start:** < 2 minutes
- **Agent success rate:** > 80% tasks completed
- **User intervention required:** < 20% of tasks

### Technical
- **Support 10+ concurrent agents**
- **Task update latency:** < 1 second
- **Database queries:** < 100ms
- **UI responsiveness:** 60 FPS

---

## Challenges & Solutions

### Challenge 1: Agent Management Complexity
**Problem:** Coordinating 10+ agents is complex

**Solution:**
- Start with single-agent mode (MVP)
- Add multi-agent in Phase 4
- Main agent acts as coordinator

### Challenge 2: Real-Time Updates
**Problem:** Need to show agent progress live

**Solution:**
- WebSocket to OpenClaw Gateway
- Polling as fallback (every 2 sec)
- Event-driven UI updates

### Challenge 3: Task Planning UX
**Problem:** AI Q&A can be slow/tedious

**Solution:**
- Show estimated questions upfront (3-5)
- Allow skipping questions
- Pre-fill with smart defaults
- "Quick plan" mode (1 question)

---

## Comparison: Web App vs Native App

| Feature | Original (Next.js) | OpenClawKit Native |
|---------|-------------------|-------------------|
| **Platform** | Web browser | macOS native |
| **Performance** | Slower (web) | Faster (Swift) |
| **Offline** | No | Yes (local data) |
| **Integration** | Separate app | Built-in |
| **Distribution** | Manual setup | One-click install |
| **Updates** | Git pull | Auto-update |

---

## Roadmap Integration

### How This Fits with Other Features

**Synergy with Native Chat:**
- Chat = Single conversation with AI
- Mission Control = Multi-agent project management
- Both use same OpenClaw Gateway

**Synergy with Skills Marketplace:**
- Skills can be installed per-agent
- Specialized agents get specialized skills
- "Install skill for all agents" feature

**Synergy with Usage Monitoring:**
- Track token usage per agent
- Pause expensive agents
- Alert when budget exceeded

---

## Next Steps

1. **Review this spec** - Does it match your vision?
2. **Prioritize phases** - Do we build chat first or Mission Control?
3. **Design mockups** - Want detailed UI designs?
4. **Start coding** - Ready to build Phase 1?

---

Last updated: Feb 10, 2026  
Inspiration: @pbteja1998's Mission Control  
GitHub: https://github.com/crshdn/mission-control
