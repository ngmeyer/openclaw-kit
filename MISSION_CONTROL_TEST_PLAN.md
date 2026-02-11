# Mission Control Test Plan

## Testing Strategy

### Phase 1: Manual UI Testing (Week 1-2)
Test all UI interactions without OpenClaw integration

### Phase 2: Integration Testing (Week 2-3)
Test with OpenClaw Gateway and real agents

### Phase 3: Load Testing (Week 3)
Test with 10+ concurrent agents and 50+ tasks

## Test Cases

### 1. Task Management

#### TC-001: Create Task
**Steps:**
1. Click "+" button in header
2. Enter title: "Test Task 1"
3. Enter description: "This is a test"
4. Select priority: High
5. Click "Create Task"

**Expected:**
- Task appears in PLANNING column
- Planning view opens automatically
- Task persists after app restart

**Status:** ⬜ Not Tested

---

#### TC-002: Edit Task
**Steps:**
1. Click on a task card
2. Click edit button (pencil icon)
3. Change title and description
4. Click "Save"

**Expected:**
- Changes are saved
- Updated timestamp updates
- Changes persist after app restart

**Status:** ⬜ Not Tested

---

#### TC-003: Delete Task
**Steps:**
1. Click on a task
2. Scroll to bottom
3. Click "Delete Task"

**Expected:**
- Task is removed from board
- Task is deleted from database
- No error in console

**Status:** ⬜ Not Tested

---

#### TC-004: Drag and Drop Task
**Steps:**
1. Create a task
2. Drag task card from PLANNING column
3. Drop in INBOX column

**Expected:**
- Task moves to new column
- Status updates to INBOX
- Change persists

**Status:** ⬜ Not Tested

---

### 2. Planning Workflow

#### TC-005: Complete Planning
**Steps:**
1. Create a new task
2. Answer all 5 planning questions
3. Click "Complete Planning"

**Expected:**
- All answers are saved to task
- Task moves to INBOX
- Planning view closes
- Task detail view opens

**Status:** ⬜ Not Tested

---

#### TC-006: Skip Planning Questions
**Steps:**
1. Create a new task
2. Click "Skip" for each question

**Expected:**
- Questions marked as "Skipped"
- Planning completes successfully
- Task moves to INBOX

**Status:** ⬜ Not Tested

---

#### TC-007: View Planning History
**Steps:**
1. Create and complete planning for a task
2. Open task detail
3. Scroll to "Planning Q&A" section

**Expected:**
- All questions and answers are visible
- Formatted correctly
- No truncation

**Status:** ⬜ Not Tested

---

### 3. Agent Management

#### TC-008: Spawn Agent (Placeholder)
**Steps:**
1. Create a task with planning complete
2. Open task detail
3. Click "Spawn Agent"

**Expected:**
- Agent is created in database
- Agent appears in Agent Monitor
- Task is assigned to agent
- Task moves to ASSIGNED status

**Status:** ⬜ Not Tested

---

#### TC-009: View Agent Monitor
**Steps:**
1. Create 3 agents
2. Click agent counter in header
3. View Agent Monitor

**Expected:**
- All agents are listed
- Agents grouped by status
- Correct counts displayed
- Stats are accurate

**Status:** ⬜ Not Tested

---

#### TC-010: Stop Agent
**Steps:**
1. Spawn an agent
2. Open Agent Monitor
3. Click "Stop" on active agent

**Expected:**
- Agent status changes to OFFLINE
- Agent's current task is cleared
- Tasks completed count increments

**Status:** ⬜ Not Tested

---

#### TC-011: Delete Agent
**Steps:**
1. Create an agent
2. Open Agent Monitor
3. Click trash icon on agent
4. Confirm deletion

**Expected:**
- Agent is removed from list
- Agent deleted from database
- No orphaned tasks

**Status:** ⬜ Not Tested

---

### 4. Data Persistence

#### TC-012: Data Survives App Restart
**Steps:**
1. Create 5 tasks across different columns
2. Create 2 agents
3. Quit app (cmd + Q)
4. Relaunch app
5. Open Mission Control

**Expected:**
- All tasks are still present
- All agents are still present
- No data loss
- Correct statuses

**Status:** ⬜ Not Tested

---

#### TC-013: Data File Location
**Steps:**
1. Create a task
2. Open Finder
3. Navigate to: `~/Library/Application Support/OpenClawKit/MissionControl/`
4. Check for JSON files

**Expected:**
- Directory exists
- `tasks.json` exists and is valid JSON
- `agents.json` exists
- `messages.json` exists

**Status:** ⬜ Not Tested

---

#### TC-014: Corrupted Data Recovery
**Steps:**
1. Create tasks
2. Manually corrupt `tasks.json` (invalid JSON)
3. Restart app

**Expected:**
- App handles gracefully
- Shows empty state or recovers
- No crash
- Logs error to console

**Status:** ⬜ Not Tested

---

### 5. UI/UX

#### TC-015: Kanban Board Layout
**Steps:**
1. Create 3+ tasks per column
2. View full board

**Expected:**
- All 7 columns visible
- Horizontal scrolling works
- Cards don't overlap
- Responsive layout

**Status:** ⬜ Not Tested

---

#### TC-016: Task Card Display
**Steps:**
1. Create task with all fields filled
2. View task card

**Expected:**
- Priority icon shown
- Status color correct
- Agent badge (if assigned)
- Deliverables indicator
- Tags displayed (up to 3)
- Time ago updates

**Status:** ⬜ Not Tested

---

#### TC-017: Dark Theme Consistency
**Steps:**
1. View all screens
2. Check colors and contrast

**Expected:**
- All text readable
- Consistent dark background
- Proper contrast ratios
- Accent colors pop

**Status:** ⬜ Not Tested

---

#### TC-018: Statistics Accuracy
**Steps:**
1. Create 10 tasks across different statuses
2. Create 3 agents
3. Check footer stats

**Expected:**
- Total tasks: 10
- In Progress: correct count
- Completed: correct count
- Active agents: correct count
- Completion rate: correct %

**Status:** ⬜ Not Tested

---

### 6. Edge Cases

#### TC-019: Empty State
**Steps:**
1. Fresh install (no data)
2. Open Mission Control

**Expected:**
- Empty Kanban board
- Helpful empty state message
- "Create Task" button prominent

**Status:** ⬜ Not Tested

---

#### TC-020: Very Long Task Title
**Steps:**
1. Create task with 200+ character title
2. View on board

**Expected:**
- Title truncates with "..."
- Card doesn't break layout
- Full title visible in detail view

**Status:** ⬜ Not Tested

---

#### TC-021: Special Characters in Task
**Steps:**
1. Create task with title: `Test <script>alert('xss')</script>`
2. Add emojis: 🚀🔥💻

**Expected:**
- Special chars displayed correctly
- No XSS or injection
- Emojis render properly

**Status:** ⬜ Not Tested

---

#### TC-022: Many Tasks Performance
**Steps:**
1. Create 50+ tasks
2. Scroll through columns
3. Drag a task

**Expected:**
- UI remains responsive
- Smooth scrolling
- Drag/drop still works
- No lag or freezing

**Status:** ⬜ Not Tested

---

### 7. Integration Tests (Future)

#### TC-023: Spawn Real Agent via OpenClaw
**Prerequisites:** OpenClaw Gateway running

**Steps:**
1. Create task with planning
2. Click "Spawn Agent"
3. Check OpenClaw Gateway logs

**Expected:**
- POST request to `/v1/sessions/spawn`
- Session key returned
- Agent appears in Gateway
- Agent sessionKey saved

**Status:** ⬜ Not Tested (Future)

---

#### TC-024: Agent Executes Task
**Prerequisites:** OpenClaw integration complete

**Steps:**
1. Spawn agent for a research task
2. Wait for agent to complete
3. Check for deliverables

**Expected:**
- Agent status updates to WORKING
- Task moves to IN_PROGRESS
- Deliverable added when complete
- Task moves to REVIEW

**Status:** ⬜ Not Tested (Future)

---

#### TC-025: Multi-Agent Coordination
**Prerequisites:** OpenClaw integration + Phase 3

**Steps:**
1. Create 5 tasks
2. Spawn 3 agents
3. Let agents claim tasks

**Expected:**
- Agents autonomously claim tasks
- No task claimed by multiple agents
- Agent messages logged
- Coordination visible in UI

**Status:** ⬜ Not Tested (Future)

---

## Test Results Log

### Test Run 1: [Date]
**Tester:** [Name]  
**Build:** [Version]

| Test ID | Status | Notes |
|---------|--------|-------|
| TC-001  | ⬜     |       |
| TC-002  | ⬜     |       |
| ...     | ...    | ...   |

**Summary:**
- Passed: 0
- Failed: 0
- Blocked: 0
- Not Run: 25

---

## Bug Report Template

```
**Bug ID:** BUG-XXX
**Severity:** Critical / High / Medium / Low
**Test Case:** TC-XXX
**Title:** [Short description]

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. ...

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots:**
[If applicable]

**Environment:**
- macOS version:
- OpenClawKit version:
- Mission Control phase:

**Logs:**
```
[Console output]
```
```

---

## Performance Benchmarks

### Target Metrics
- **Task creation:** < 100ms
- **Column drag/drop:** < 50ms
- **Planning Q&A:** < 200ms per question
- **Agent spawn:** < 500ms (UI response, not actual spawn)
- **Data save:** < 100ms
- **Data load:** < 500ms for 100 tasks

### Actual Metrics
| Operation | Target | Actual | Status |
|-----------|--------|--------|--------|
| Create task | <100ms | TBD | ⬜ |
| Drag/drop | <50ms | TBD | ⬜ |
| Planning Q&A | <200ms | TBD | ⬜ |
| Agent spawn UI | <500ms | TBD | ⬜ |
| Data save | <100ms | TBD | ⬜ |
| Data load | <500ms | TBD | ⬜ |

---

## Acceptance Criteria

### MVP Phase 1 (Current)
- [ ] All TC-001 to TC-022 pass
- [ ] No critical bugs
- [ ] Performance targets met
- [ ] Data persistence works
- [ ] UI is polished and responsive

### Phase 2 (OpenClaw Integration)
- [ ] TC-023 to TC-024 pass
- [ ] Real agents spawn and execute
- [ ] Deliverables captured correctly
- [ ] Agent status updates in real-time

### Phase 3 (Multi-Agent)
- [ ] TC-025 passes
- [ ] 10+ concurrent agents stable
- [ ] Agent communication works
- [ ] Task coordination visible

---

## Testing Schedule

### Week 1 (Feb 10-14)
- Manual testing of all UI components
- Data persistence testing
- Edge cases

### Week 2 (Feb 17-21)
- OpenClaw integration testing
- Agent spawning
- Real task execution

### Week 3 (Feb 24-28)
- Multi-agent testing
- Load testing
- Final polish and bug fixes

---

## Test Environment Setup

### Prerequisites
1. OpenClawKit app built and running
2. Mission Control files added to project
3. Clean macOS environment (for fresh install testing)
4. OpenClaw Gateway running (for integration tests)

### Test Data Setup
```bash
# Create sample tasks
# (To be scripted or done manually)
```

### Clean Data Between Tests
```bash
rm -rf ~/Library/Application\ Support/OpenClawKit/MissionControl/
```

---

**Last Updated:** February 10, 2026  
**Test Coverage:** Phase 1 MVP  
**Status:** Ready for Testing
