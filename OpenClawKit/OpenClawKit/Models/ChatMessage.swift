import Foundation

/// Represents a single message in the chat conversation
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        
        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "Aria"
            }
        }
        
        var icon: String {
            switch self {
            case .user: return "person.circle.fill"
            case .assistant: return "sparkles"
            }
        }
    }
}

// MARK: - Message History Persistence

extension ChatMessage {
    /// File URL for persisting chat history
    static var historyFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let openClawDir = appSupport.appendingPathComponent("OpenClawKit", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: openClawDir, withIntermediateDirectories: true)
        
        return openClawDir.appendingPathComponent("chat_history.json")
    }
    
    /// Load message history from disk
    static func loadHistory() -> [ChatMessage] {
        guard let data = try? Data(contentsOf: historyFileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return (try? decoder.decode([ChatMessage].self, from: data)) ?? []
    }
    
    /// Save message history to disk
    static func saveHistory(_ messages: [ChatMessage]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(messages) else {
            print("❌ Failed to encode chat history")
            return
        }
        
        do {
            try data.write(to: historyFileURL)
            print("✅ Saved \(messages.count) messages to disk")
        } catch {
            print("❌ Failed to save chat history: \(error)")
        }
    }
    
    /// Clear all message history
    static func clearHistory() {
        try? FileManager.default.removeItem(at: historyFileURL)
        print("🗑️ Cleared chat history")
    }
}
