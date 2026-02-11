import Foundation
import Combine

/// OpenClaw Gateway API client for agent management
@MainActor
class OpenClawGateway: ObservableObject {
    static let shared = OpenClawGateway()
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var activeSessions: [SessionInfo] = []
    @Published var error: GatewayError?
    
    // MARK: - Private Properties
    
    private var baseURL: URL
    private var cancellables = Set<AnyCancellable>()
    private var eventSource: URLSessionDataTask?
    private let session: URLSession
    
    // MARK: - Configuration
    
    private struct Config: Codable {
        let gateway: GatewayConfig?
        
        struct GatewayConfig: Codable {
            let port: Int?
            let host: String?
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        // Read config from ~/.openclaw/openclaw.json
        self.baseURL = Self.loadGatewayURL()
        
        Task {
            await checkConnection()
        }
    }
    
    /// Load gateway URL from OpenClaw config
    private static func loadGatewayURL() -> URL {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw/openclaw.json")
        
        if FileManager.default.fileExists(atPath: configPath.path),
           let data = try? Data(contentsOf: configPath),
           let config = try? JSONDecoder().decode(Config.self, from: data),
           let gateway = config.gateway {
            let host = gateway.host ?? "localhost"
            let port = gateway.port ?? 18789
            // Safely construct URL; fall back to default if construction fails
            if let url = URL(string: "http://\(host):\(port)") {
                return url
            }
        }
        
        // Safe fallback URL
        return URL(string: "http://localhost:18789") ?? URL(fileURLWithPath: "/")
    }
    
    // MARK: - Connection Management
    
    /// Check if gateway is running
    func checkConnection() async {
        do {
            let url = baseURL.appendingPathComponent("health")
            let (_, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                isConnected = httpResponse.statusCode == 200
            }
        } catch {
            isConnected = false
            self.error = .connectionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Session Management
    
    /// List all active sessions
    func listSessions(kinds: [String]? = nil, limit: Int = 50) async throws -> [SessionInfo] {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/sessions"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let kinds = kinds {
            for kind in kinds {
                queryItems.append(URLQueryItem(name: "kinds", value: kind))
            }
        }
        
        components.queryItems = queryItems
        
        let (data, response) = try await session.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GatewayError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(SessionListResponse.self, from: data)
        activeSessions = result.sessions
        return result.sessions
    }
    
    /// Spawn a new agent session
    func spawnAgent(config: AgentSpawnRequest) async throws -> SpawnResponse {
        let url = baseURL.appendingPathComponent("v1/sessions/spawn")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GatewayError.spawnFailed
        }
        
        return try JSONDecoder().decode(SpawnResponse.self, from: data)
    }
    
    /// Send a message to an agent session
    func sendMessage(sessionKey: String, message: String) async throws -> MessageResponse {
        let url = baseURL.appendingPathComponent("v1/sessions/\(sessionKey)/messages")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["message": message]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GatewayError.messageFailed
        }
        
        return try JSONDecoder().decode(MessageResponse.self, from: data)
    }
    
    /// Get session history
    func getSessionHistory(sessionKey: String, limit: Int = 50) async throws -> [HistoryMessage] {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/sessions/\(sessionKey)/history"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let (data, response) = try await session.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GatewayError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(HistoryResponse.self, from: data)
        return result.messages
    }
    
    /// Stop an agent session
    func stopSession(sessionKey: String) async throws {
        let url = baseURL.appendingPathComponent("v1/sessions/\(sessionKey)/stop")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GatewayError.stopFailed
        }
    }
    
    // MARK: - Streaming (SSE)
    
    /// Subscribe to session events via Server-Sent Events
    func subscribeToEvents(sessionKey: String, onEvent: @escaping @Sendable (SessionEvent) -> Void) {
        let url = baseURL.appendingPathComponent("v1/sessions/\(sessionKey)/events")
        
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = TimeInterval.infinity
        
        eventSource = session.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            
            // Parse SSE data
            if let eventString = String(data: data, encoding: .utf8) {
                Self.parseSSEEventStatic(eventString, onEvent: onEvent)
            }
        }
        
        eventSource?.resume()
    }
    
    /// Stop event subscription
    func unsubscribeFromEvents() {
        eventSource?.cancel()
        eventSource = nil
    }
    
    private static func parseSSEEventStatic(_ eventString: String, onEvent: @escaping @Sendable (SessionEvent) -> Void) {
        let lines = eventString.components(separatedBy: "\n")
        var eventType = "message"
        var eventData = ""
        
        for line in lines {
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                eventData = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        if !eventData.isEmpty {
            let event = SessionEvent(type: eventType, data: eventData)
            DispatchQueue.main.async {
                onEvent(event)
            }
        }
    }
    
    // MARK: - Chat API
    
    /// Send a chat message and stream the response
    func chat(
        message: String,
        model: String? = nil,
        sessionId: String? = nil,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        let url = baseURL.appendingPathComponent("v1/responses")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        var body: [String: Any] = [
            "input": message,
            "stream": true
        ]
        
        if let model = model {
            body["model"] = model
        }
        
        if let sessionId = sessionId {
            body["session_id"] = sessionId
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    onError(error)
                }
                return
            }
            
            guard let data = data,
                  let responseString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    onComplete()
                }
                return
            }
            
            // Parse SSE response
            let lines = responseString.components(separatedBy: "\n")
            for line in lines {
                if line.hasPrefix("data:") {
                    let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    if jsonString == "[DONE]" {
                        DispatchQueue.main.async {
                            onComplete()
                        }
                        return
                    }
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let delta = json["delta"] as? String {
                        DispatchQueue.main.async {
                            onChunk(delta)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                onComplete()
            }
        }
        
        task.resume()
    }
}

// MARK: - API Types

struct SessionInfo: Identifiable, Codable {
    let id: String
    let key: String
    let kind: String
    let label: String?
    let model: String?
    let createdAt: Date?
    let lastActivity: Date?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id, key, kind, label, model, status
        case createdAt = "created_at"
        case lastActivity = "last_activity"
    }
}

struct SessionListResponse: Codable {
    let sessions: [SessionInfo]
}

struct AgentSpawnRequest: Codable {
    let task: String
    let agentId: String?
    let model: String?
    let label: String?
    let capabilities: [String]?
    let systemPrompt: String?
    
    enum CodingKeys: String, CodingKey {
        case task
        case agentId = "agent_id"
        case model, label, capabilities
        case systemPrompt = "system_prompt"
    }
    
    init(
        task: String,
        agentId: String? = nil,
        model: String? = "sonnet",
        label: String? = nil,
        capabilities: [String]? = nil,
        systemPrompt: String? = nil
    ) {
        self.task = task
        self.agentId = agentId
        self.model = model
        self.label = label
        self.capabilities = capabilities
        self.systemPrompt = systemPrompt
    }
}

struct SpawnResponse: Codable {
    let sessionKey: String
    let sessionId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case sessionKey = "session_key"
        case sessionId = "session_id"
        case status
    }
}

struct MessageResponse: Codable {
    let success: Bool
    let messageId: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case messageId = "message_id"
    }
}

struct HistoryMessage: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date?
}

struct HistoryResponse: Codable {
    let messages: [HistoryMessage]
}

struct SessionEvent: Identifiable {
    let id = UUID()
    let type: String
    let data: String
    let timestamp = Date()
}

// MARK: - Errors

enum GatewayError: LocalizedError {
    case connectionFailed(String)
    case invalidResponse
    case spawnFailed
    case messageFailed
    case stopFailed
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .invalidResponse: return "Invalid response from gateway"
        case .spawnFailed: return "Failed to spawn agent"
        case .messageFailed: return "Failed to send message"
        case .stopFailed: return "Failed to stop session"
        case .notConnected: return "Not connected to gateway"
        }
    }
}
