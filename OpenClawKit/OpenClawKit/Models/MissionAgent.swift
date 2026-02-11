import Foundation

/// Represents an AI agent in the Mission Control system
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
    
    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        sessionKey: String? = nil,
        status: AgentStatus = .idle,
        currentTask: UUID? = nil,
        capabilities: [String] = [],
        createdAt: Date = Date(),
        lastActivity: Date = Date(),
        model: String = "sonnet",
        totalTasksCompleted: Int = 0
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.sessionKey = sessionKey
        self.status = status
        self.currentTask = currentTask
        self.capabilities = capabilities
        self.createdAt = createdAt
        self.lastActivity = lastActivity
        self.model = model
        self.totalTasksCompleted = totalTasksCompleted
    }
    
    /// Update last activity timestamp
    mutating func touch() {
        lastActivity = Date()
    }
    
    /// Update agent status
    mutating func updateStatus(_ newStatus: AgentStatus) {
        status = newStatus
        touch()
    }
    
    /// Assign a task to this agent
    mutating func assignTask(_ taskId: UUID) {
        currentTask = taskId
        status = .working
        touch()
    }
    
    /// Complete the current task
    mutating func completeTask() {
        currentTask = nil
        status = .idle
        totalTasksCompleted += 1
        touch()
    }
    
    /// Computed property for status color
    var statusColor: String {
        status.color
    }
    
    /// Computed property for role icon
    var roleIcon: String {
        role.icon
    }
    
    /// Check if agent is available for new tasks
    var isAvailable: Bool {
        status == .idle && currentTask == nil
    }
    
    /// Human-readable activity description
    var activityDescription: String {
        switch status {
        case .idle:
            return "Waiting for tasks"
        case .working:
            return "Working on task"
        case .waiting:
            return "Waiting for input"
        case .error:
            return "Encountered an error"
        case .offline:
            return "Offline"
        }
    }
}

// MARK: - Agent Status

enum AgentStatus: String, Codable, CaseIterable {
    case idle = "IDLE"
    case working = "WORKING"
    case waiting = "WAITING"
    case error = "ERROR"
    case offline = "OFFLINE"
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .working: return "Working"
        case .waiting: return "Waiting"
        case .error: return "Error"
        case .offline: return "Offline"
        }
    }
    
    var color: String {
        switch self {
        case .idle: return "#6B7280"      // Gray
        case .working: return "#10B981"   // Green
        case .waiting: return "#F59E0B"   // Amber
        case .error: return "#EF4444"     // Red
        case .offline: return "#374151"   // Dark Gray
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .working: return "circle.fill"
        case .waiting: return "clock"
        case .error: return "exclamationmark.triangle"
        case .offline: return "moon.fill"
        }
    }
}

// MARK: - Agent Role Icons

extension String {
    var icon: String {
        // Role-based icon mapping
        let lowercased = self.lowercased()
        
        if lowercased.contains("research") {
            return "magnifyingglass"
        } else if lowercased.contains("code") || lowercased.contains("developer") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lowercased.contains("writ") {
            return "pencil"
        } else if lowercased.contains("design") {
            return "paintbrush"
        } else if lowercased.contains("data") || lowercased.contains("analyst") {
            return "chart.bar"
        } else if lowercased.contains("test") || lowercased.contains("qa") {
            return "checkmark.seal"
        } else if lowercased.contains("coordinat") || lowercased.contains("manager") {
            return "person.2"
        } else {
            return "cpu"
        }
    }
}

// MARK: - Agent Message

struct AgentMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let fromAgent: UUID
    let toAgent: UUID?
    var message: String
    let timestamp: Date
    var messageType: MessageType
    
    init(
        id: UUID = UUID(),
        fromAgent: UUID,
        toAgent: UUID? = nil,
        message: String,
        timestamp: Date = Date(),
        messageType: MessageType = .communication
    ) {
        self.id = id
        self.fromAgent = fromAgent
        self.toAgent = toAgent
        self.message = message
        self.timestamp = timestamp
        self.messageType = messageType
    }
    
    enum MessageType: String, Codable {
        case communication = "COMMUNICATION"
        case taskClaim = "TASK_CLAIM"
        case taskHandoff = "TASK_HANDOFF"
        case agreement = "AGREEMENT"
        case refutation = "REFUTATION"
        case praise = "PRAISE"
        case question = "QUESTION"
        case update = "UPDATE"
        
        var icon: String {
            switch self {
            case .communication: return "message"
            case .taskClaim: return "hand.raised"
            case .taskHandoff: return "arrow.triangle.2.circlepath"
            case .agreement: return "checkmark.circle"
            case .refutation: return "xmark.circle"
            case .praise: return "star.fill"
            case .question: return "questionmark.circle"
            case .update: return "info.circle"
            }
        }
        
        var color: String {
            switch self {
            case .communication: return "#3B82F6"  // Blue
            case .taskClaim: return "#F59E0B"      // Amber
            case .taskHandoff: return "#8B5CF6"    // Violet
            case .agreement: return "#10B981"      // Green
            case .refutation: return "#EF4444"     // Red
            case .praise: return "#FBBF24"         // Yellow
            case .question: return "#06B6D4"       // Cyan
            case .update: return "#6B7280"         // Gray
            }
        }
    }
}

// MARK: - Agent Spawn Configuration

struct AgentSpawnConfig {
    let name: String
    let role: String
    let model: String
    let capabilities: [String]
    let taskDescription: String
    let planningContext: [QAPair]
    
    init(
        name: String,
        role: String,
        model: String = "sonnet",
        capabilities: [String] = [],
        taskDescription: String,
        planningContext: [QAPair] = []
    ) {
        self.name = name
        self.role = role
        self.model = model
        self.capabilities = capabilities
        self.taskDescription = taskDescription
        self.planningContext = planningContext
    }
    
    /// Generate the agent's initial prompt
    func generatePrompt() -> String {
        var prompt = """
        You are \(name), a specialized AI agent with the role: \(role).
        
        Your task:
        \(taskDescription)
        
        """
        
        if !planningContext.isEmpty {
            prompt += "\nPlanning Context:\n"
            for qa in planningContext {
                prompt += "Q: \(qa.question)\n"
                prompt += "A: \(qa.answer)\n\n"
            }
        }
        
        if !capabilities.isEmpty {
            prompt += "\nYour capabilities:\n"
            for capability in capabilities {
                prompt += "- \(capability)\n"
            }
        }
        
        prompt += """
        
        Please work autonomously and report your progress. When complete, provide a clear deliverable.
        """
        
        return prompt
    }
}
