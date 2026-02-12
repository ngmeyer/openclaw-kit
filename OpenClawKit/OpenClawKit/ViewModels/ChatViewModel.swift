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
    private let gateway = OpenClawGateway.shared
    private var gatewayURL: String = "http://localhost:18789"
    private var authToken: String = ""
    private var chatSessionKey: String?
    
    // MARK: - Active Task Tracking
    private var streamingTask: Task<Void, Never>?
    private var eventSubscription: AnyCancellable?
    
    // MARK: - First Use Tracking
    private let hasSeenWelcomeKey = "openclawkit.chat.hasSeenWelcome"
    
    init() {
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
        
        // Add welcome message only on first use
        if messages.isEmpty && !hasSeenWelcome() {
            addWelcomeMessage()
            markWelcomeSeen()
        }
    }
    
    // MARK: - First Use Tracking
    
    private func hasSeenWelcome() -> Bool {
        UserDefaults.standard.bool(forKey: hasSeenWelcomeKey)
    }
    
    private func markWelcomeSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenWelcomeKey)
    }
    
    // MARK: - Message Sending
    
    /// Send a user message and stream the assistant's response
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, isConnected else { return }
        
        // Ensure we have a chat session
        if chatSessionKey == nil {
            do {
                let response = try await gateway.spawnAgent(config: AgentSpawnRequest(
                    task: "OpenClawKit Chat Session",
                    agentId: "main",
                    model: nil,
                    label: "OpenClawKit Chat",
                    capabilities: nil,
                    systemPrompt: nil
                ))
                chatSessionKey = response.sessionKey
                print("✅ Spawned chat session: \(response.sessionKey)")
            } catch {
                self.error = "Failed to start chat session: \(error.localizedDescription)"
                print("❌ Failed to spawn chat session: \(error)")
                return
            }
        }
        
        guard let sessionKey = chatSessionKey else {
            self.error = "No active chat session"
            return
        }
        
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
        
        // Start streaming response using Gateway
        streamingTask = Task {
            do {
                // Send message via Gateway
                _ = try await gateway.sendMessage(sessionKey: sessionKey, message: text)
                
                // Use the Gateway's chat method which handles streaming properly
                await withCheckedContinuation { continuation in
                    var accumulatedText = ""
                    
                    gateway.chat(
                        message: text,
                        model: nil,
                        sessionId: sessionKey,
                        onChunk: { [weak self] delta in
                            guard let self = self else { return }
                            accumulatedText += delta
                            Task { @MainActor in
                                if let index = self.messages.firstIndex(where: { $0.id == assistantMessageID }) {
                                    self.messages[index].content = accumulatedText
                                }
                            }
                        },
                        onComplete: { [weak self] in
                            guard let self = self else {
                                continuation.resume()
                                return
                            }
                            Task { @MainActor in
                                if let index = self.messages.firstIndex(where: { $0.id == assistantMessageID }) {
                                    self.messages[index].isStreaming = false
                                }
                                self.saveHistory()
                                self.isTyping = false
                                continuation.resume()
                            }
                        },
                        onError: { [weak self] error in
                            guard let self = self else {
                                continuation.resume()
                                return
                            }
                            Task { @MainActor in
                                self.error = error.localizedDescription
                                if let index = self.messages.firstIndex(where: { $0.id == assistantMessageID }) {
                                    self.messages[index].isStreaming = false
                                    self.messages[index].content += "\n\n[Error: \(error.localizedDescription)]"
                                }
                                self.isTyping = false
                                continuation.resume()
                            }
                        }
                    )
                }
                
            } catch {
                // Handle errors
                self.error = error.localizedDescription
                print("❌ Streaming error: \(error)")
                
                // Mark message as failed but keep it
                if let index = messages.firstIndex(where: { $0.id == assistantMessageID }) {
                    messages[index].isStreaming = false
                    messages[index].content += "\n\n[Error: Failed to get response]"
                }
                isTyping = false
            }
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
        // Reset welcome flag so it shows again after clear
        UserDefaults.standard.set(false, forKey: hasSeenWelcomeKey)
        addWelcomeMessage()
        markWelcomeSeen()
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
