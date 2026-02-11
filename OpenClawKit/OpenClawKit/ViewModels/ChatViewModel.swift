import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published State
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var inputText: String = ""
    @Published var error: String? = nil
    @Published var isConnected: Bool = false
    
    // MARK: - Configuration
    private let apiClient = OpenClawAPIClient()
    private var gatewayURL: String = "http://localhost:18789"
    private var authToken: String = ""
    private let sessionID: String
    
    // MARK: - Active Task Tracking
    private var streamingTask: Task<Void, Never>?
    
    init() {
        // Generate unique session ID for this chat instance
        self.sessionID = "openclawkit-\(UUID().uuidString)"
        
        // Load gateway configuration
        if let config = OpenClawAPIClient.loadGatewayConfig() {
            self.gatewayURL = config.url
            self.authToken = config.token
            self.isConnected = true
            print("✅ Chat initialized with gateway: \(gatewayURL)")
        } else {
            self.error = "Could not load gateway configuration. Please complete setup."
            print("❌ Failed to initialize chat - no gateway config")
        }
        
        // Load message history
        loadHistory()
        
        // Add welcome message if this is a new conversation
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }
    
    // MARK: - Message Sending
    
    /// Send a user message and stream the assistant's response
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, isConnected else { return }
        
        // Clear input immediately for better UX
        inputText = ""
        error = nil
        
        // Add user message
        let userMessage = ChatMessage(
            role: .user,
            content: text
        )
        messages.append(userMessage)
        
        // Create placeholder for assistant response
        let assistantMessageID = UUID()
        let assistantMessage = ChatMessage(
            id: assistantMessageID,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        messages.append(assistantMessage)
        
        // Show typing indicator
        isTyping = true
        
        // Cancel any existing streaming task
        streamingTask?.cancel()
        
        // Start streaming response
        streamingTask = Task {
            do {
                let stream = apiClient.sendMessage(
                    text,
                    gatewayURL: gatewayURL,
                    authToken: authToken,
                    sessionID: sessionID
                )
                
                // Accumulate response text
                for try await delta in stream {
                    // Check for cancellation
                    guard !Task.isCancelled else {
                        print("⚠️ Streaming task cancelled")
                        break
                    }
                    
                    // Update the assistant message with new text
                    if let index = messages.firstIndex(where: { $0.id == assistantMessageID }) {
                        messages[index].content += delta
                    }
                }
                
                // Mark streaming as complete
                if let index = messages.firstIndex(where: { $0.id == assistantMessageID }) {
                    messages[index].isStreaming = false
                }
                
                // Save to history
                saveHistory()
                
            } catch {
                // Handle errors
                self.error = error.localizedDescription
                print("❌ Streaming error: \(error)")
                
                // Remove failed assistant message
                messages.removeAll { $0.id == assistantMessageID }
            }
            
            isTyping = false
        }
    }
    
    /// Send a message with Cmd+Enter keyboard shortcut
    func sendMessageWithShortcut() {
        Task {
            await sendMessage()
        }
    }
    
    // MARK: - History Management
    
    /// Load message history from disk
    func loadHistory() {
        messages = ChatMessage.loadHistory()
        print("📚 Loaded \(messages.count) messages from history")
    }
    
    /// Save message history to disk
    func saveHistory() {
        ChatMessage.saveHistory(messages)
    }
    
    /// Clear all messages and start fresh
    func clearConversation() {
        messages.removeAll()
        ChatMessage.clearHistory()
        addWelcomeMessage()
        error = nil
        print("🗑️ Conversation cleared")
    }
    
    /// Add welcome message for new conversations
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            role: .assistant,
            content: """
            👋 **Welcome to OpenClaw!**
            
            I'm Aria, your AI assistant. I can help you with:
            
            • Installing and managing skills
            • Configuring channels (Discord, Telegram, etc.)
            • Answering questions about OpenClaw
            • Troubleshooting issues
            
            What would you like to know?
            """
        )
        messages.append(welcomeMessage)
    }
    
    // MARK: - Error Handling
    
    /// Clear the current error message
    func clearError() {
        error = nil
    }
    
    // MARK: - Connection Status
    
    /// Check if gateway is reachable
    func checkConnection() async {
        // Simple ping to gateway status endpoint
        guard let url = URL(string: "\(gatewayURL)/health") else {
            isConnected = false
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                isConnected = (200...299).contains(httpResponse.statusCode)
            }
        } catch {
            isConnected = false
            print("⚠️ Gateway unreachable: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Cancel any active streaming
        streamingTask?.cancel()
    }
}

// MARK: - Message Actions

extension ChatViewModel {
    /// Copy message content to clipboard
    func copyMessage(_ message: ChatMessage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message.content, forType: .string)
        print("📋 Copied message to clipboard")
    }
    
    /// Retry sending the last user message (if assistant response failed)
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
            return
        }
        
        // Remove failed assistant message if present
        if let lastMessage = messages.last, lastMessage.role == .assistant {
            messages.removeLast()
        }
        
        // Resend
        inputText = lastUserMessage.content
        Task {
            await sendMessage()
        }
    }
}
