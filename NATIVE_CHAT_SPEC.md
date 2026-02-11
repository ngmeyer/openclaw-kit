# OpenClawKit: Native Chat Interface
## Architecture (Feb 10, 2026)

### Current Flow (Browser-based)
1. Setup wizard completes
2. App opens `http://localhost:18789` in Safari
3. User chats in browser

### New Flow (Native Chat)
1. Setup wizard completes
2. App shows **native SwiftUI chat interface**
3. User chats directly in OpenClawKit app

---

## Technical Design

### API Integration

**Endpoint:** `POST http://localhost:18789/v1/responses`

**Request:**
```json
{
  "model": "openclaw:main",
  "input": "user message here",
  "user": "openclawkit-user",  // stable session
  "stream": true               // SSE streaming
}
```

**Auth:**
```
Authorization: Bearer <gateway_token>
```

**Response (SSE stream):**
```
event: response.output_text.delta
data: {"delta": "Hello"}

event: response.output_text.delta  
data: {"delta": " there!"}

data: [DONE]
```

---

## SwiftUI Architecture

### New Views

#### 1. **ChatView.swift**
Main chat interface (replaces browser opening)

**Layout:**
```
┌─────────────────────────────────┐
│  [←] OpenClaw Chat    [≡]       │  Header
├─────────────────────────────────┤
│                                 │
│  👤 You:                        │
│  How do I install a skill?      │
│                                 │
│  🤖 Aria:                       │
│  You can install skills using   │
│  the clawhub install command... │
│  ┌───────────────────────┐      │
│  │ Try: Install a skill  │      │  Action button
│  └───────────────────────┘      │
│                                 │
│  Scroll view                    │
├─────────────────────────────────┤
│  [Type message...]        [→]   │  Input
└─────────────────────────────────┘
```

**Features:**
- Message bubbles (user vs assistant)
- Typing indicator while streaming
- Markdown rendering
- Action buttons (from AI suggestions)
- Auto-scroll to bottom
- Message history (persisted)

#### 2. **ChatViewModel.swift**
State management

**Properties:**
```swift
@Published var messages: [ChatMessage] = []
@Published var isTyping: Bool = false
@Published var inputText: String = ""
@Published var error: String? = nil

private var gatewayURL: String = "http://localhost:18789"
private var authToken: String = ""
private var sessionID: String = UUID().uuidString
```

**Methods:**
```swift
func sendMessage(_ text: String) async
func streamResponse(from url: URL) async
func loadHistory()
func saveHistory()
```

#### 3. **ChatMessage.swift**
Data model

```swift
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole  // .user or .assistant
    let content: String
    let timestamp: Date
    var isStreaming: Bool = false
}

enum MessageRole: String, Codable {
    case user
    case assistant
}
```

#### 4. **OpenClawAPIClient.swift**
API service

```swift
class OpenClawAPIClient {
    func sendMessage(
        _ message: String,
        gatewayURL: String,
        authToken: String,
        sessionID: String
    ) -> AsyncThrowingStream<String, Error>
}
```

---

## Implementation Steps

### Phase 1: Basic Chat (Week 1)
**Goal:** Replace browser with native chat

**Tasks:**
1. Create ChatView.swift with basic UI
2. Implement ChatViewModel with sendMessage()
3. Build OpenClawAPIClient with HTTP requests
4. Replace browser opening in CompleteView
5. Add message bubbles styling

**Result:** Users can send/receive messages natively

### Phase 2: Streaming (Week 1)
**Goal:** Real-time response rendering

**Tasks:**
1. Implement SSE parsing
2. Add typing indicator
3. Stream text delta-by-delta
4. Handle stream errors gracefully

**Result:** Responses appear in real-time like ChatGPT

### Phase 3: Polish (Week 2)
**Goal:** Production-ready UX

**Tasks:**
1. Markdown rendering (code blocks, lists, links)
2. Message history persistence (UserDefaults or file)
3. Auto-scroll to new messages
4. Copy message text
5. Error handling UI
6. Keyboard shortcuts (Cmd+Enter to send)

**Result:** Feels like a native macOS app

### Phase 4: Advanced (Week 3-4)
**Goal:** Power features

**Tasks:**
1. Multi-session support (switch between chats)
2. Clear conversation button
3. Model switcher (Haiku/Sonnet/Opus)
4. File/image attachments
5. Voice input (macOS speech recognition)
6. Export conversation

**Result:** Competitive with ChatGPT desktop

---

## Code Skeleton

### ChatView.swift
```swift
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeaderView(
                onBack: { presentationMode.wrappedValue.dismiss() }
            )
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageBubble(message: message)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Auto-scroll to bottom
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input
            ChatInputView(
                text: $viewModel.inputText,
                onSend: {
                    Task {
                        await viewModel.sendMessage(viewModel.inputText)
                    }
                }
            )
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .onAppear {
            viewModel.loadHistory()
        }
    }
}
```

### ChatViewModel.swift
```swift
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var inputText: String = ""
    @Published var error: String? = nil
    
    private let apiClient = OpenClawAPIClient()
    private let gatewayURL = "http://localhost:18789"
    private var authToken: String = ""
    private let sessionID = "openclawkit-\(UUID().uuidString)"
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID(),
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)
        inputText = ""
        
        // Show typing indicator
        isTyping = true
        
        // Create assistant message placeholder
        let assistantMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "",
            timestamp: Date(),
            isStreaming: true
        )
        messages.append(assistantMessage)
        
        do {
            // Stream response
            let stream = try await apiClient.sendMessage(
                text,
                gatewayURL: gatewayURL,
                authToken: authToken,
                sessionID: sessionID
            )
            
            for try await delta in stream {
                // Update last message with new text
                if let index = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                    messages[index].content += delta
                }
            }
            
            // Mark streaming complete
            if let index = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                messages[index].isStreaming = false
            }
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isTyping = false
        saveHistory()
    }
    
    func loadHistory() {
        // Load from UserDefaults or file
    }
    
    func saveHistory() {
        // Save to UserDefaults or file
    }
}
```

### OpenClawAPIClient.swift
```swift
import Foundation

class OpenClawAPIClient {
    func sendMessage(
        _ message: String,
        gatewayURL: String,
        authToken: String,
        sessionID: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let url = URL(string: "\(gatewayURL)/v1/responses")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "model": "openclaw:main",
                    "input": message,
                    "user": sessionID,
                    "stream": true
                ]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let (bytes, _) = try await URLSession.shared.bytes(for: request)
                
                for try await line in bytes.lines {
                    if line.hasPrefix("data: ") {
                        let data = String(line.dropFirst(6))
                        if data == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        
                        if let json = try? JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String: Any],
                           let delta = json["delta"] as? String {
                            continuation.yield(delta)
                        }
                    }
                }
            }
        }
    }
}
```

---

## Integration Plan

### Step 1: Add to OpenClawKit
1. Create `Views/Chat/` folder
2. Add ChatView.swift, ChatViewModel.swift
3. Add Services/OpenClawAPIClient.swift
4. Add Models/ChatMessage.swift

### Step 2: Update Complete Flow
Replace browser opening in CompleteView:

**Before:**
```swift
NSWorkspace.shared.open(url)  // Opens browser
```

**After:**
```swift
viewModel.showChat = true  // Shows native chat
```

### Step 3: Navigation
Add to SetupWizardView:

```swift
.sheet(isPresented: $viewModel.showChat) {
    ChatView()
}
```

---

## Auth Token Handling

**Problem:** Chat needs gateway auth token

**Solution:** Read from config file

```swift
func loadGatewayToken() -> String {
    let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".openclaw/openclaw.json")
    
    guard let data = try? Data(contentsOf: configPath),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let gateway = json["gateway"] as? [String: Any],
          let auth = gateway["auth"] as? [String: Any],
          let token = auth["token"] as? String else {
        return ""
    }
    
    return token
}
```

---

## MVP Scope (2 weeks)

**Must Have:**
- ✅ Send/receive messages
- ✅ SSE streaming
- ✅ Message bubbles (user/assistant styling)
- ✅ Typing indicator
- ✅ Auto-scroll
- ✅ Basic markdown (bold, italic, code)

**Nice to Have:**
- Message history persistence
- Multi-line input
- Copy message text
- Clear conversation

**Later:**
- File attachments
- Voice input
- Multi-session
- Model switcher

---

## Success Metrics

### User Experience
- **Setup to first message:** < 30 seconds
- **Response latency:** < 2 seconds to first token
- **Streaming FPS:** 30+ characters/sec
- **Crash rate:** < 0.1%

### Technical
- **API success rate:** > 99%
- **SSE reconnect:** Automatic on disconnect
- **Memory usage:** < 100MB idle

---

Last updated: Feb 10, 2026  
Next: Build ChatView.swift skeleton
