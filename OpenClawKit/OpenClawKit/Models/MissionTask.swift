import Foundation

/// Represents a task in the Mission Control system
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
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        status: TaskStatus = .planning,
        assignedAgent: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        planningQA: [QAPair] = [],
        deliverables: [Deliverable] = [],
        priority: TaskPriority = .medium,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.assignedAgent = assignedAgent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.planningQA = planningQA
        self.deliverables = deliverables
        self.priority = priority
        self.tags = tags
    }
    
    /// Update the task's timestamp
    mutating func touch() {
        updatedAt = Date()
    }
    
    /// Move task to a new status
    mutating func moveTo(status: TaskStatus) {
        self.status = status
        touch()
    }
    
    /// Assign task to an agent
    mutating func assign(to agentName: String) {
        self.assignedAgent = agentName
        self.status = .assigned
        touch()
    }
    
    /// Add a planning Q&A pair
    mutating func addQA(_ qa: QAPair) {
        planningQA.append(qa)
        touch()
    }
    
    /// Add a deliverable
    mutating func addDeliverable(_ deliverable: Deliverable) {
        deliverables.append(deliverable)
        touch()
    }
    
    /// Computed property for display color
    var statusColor: String {
        status.color
    }
    
    /// Computed property for priority icon
    var priorityIcon: String {
        priority.icon
    }
}

// MARK: - Task Status

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case planning = "PLANNING"
    case inbox = "INBOX"
    case assigned = "ASSIGNED"
    case inProgress = "IN_PROGRESS"
    case testing = "TESTING"
    case review = "REVIEW"
    case done = "DONE"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .inbox: return "Inbox"
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .testing: return "Testing"
        case .review: return "Review"
        case .done: return "Done"
        }
    }
    
    var color: String {
        switch self {
        case .planning: return "#9333EA"      // Purple
        case .inbox: return "#3B82F6"         // Blue
        case .assigned: return "#F59E0B"      // Amber
        case .inProgress: return "#10B981"    // Green
        case .testing: return "#F97316"       // Orange
        case .review: return "#8B5CF6"        // Violet
        case .done: return "#6B7280"          // Gray
        }
    }
    
    var icon: String {
        switch self {
        case .planning: return "brain"
        case .inbox: return "tray"
        case .assigned: return "person.badge.plus"
        case .inProgress: return "gearshape.2"
        case .testing: return "checkmark.seal"
        case .review: return "eye"
        case .done: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Task Priority

enum TaskPriority: String, Codable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case urgent = "URGENT"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#6B7280"       // Gray
        case .medium: return "#3B82F6"    // Blue
        case .high: return "#F59E0B"      // Amber
        case .urgent: return "#EF4444"    // Red
        }
    }
}

// MARK: - Q&A Pair

struct QAPair: Identifiable, Codable, Equatable {
    let id: UUID
    let question: String
    var answer: String
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        question: String,
        answer: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.timestamp = timestamp
    }
    
    var isAnswered: Bool {
        !answer.isEmpty
    }
}

// MARK: - Deliverable

struct Deliverable: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: DeliverableType
    var content: String
    var filePath: String?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        type: DeliverableType,
        content: String = "",
        filePath: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.content = content
        self.filePath = filePath
        self.createdAt = createdAt
    }
}

enum DeliverableType: String, Codable, CaseIterable {
    case document = "DOCUMENT"
    case code = "CODE"
    case report = "REPORT"
    case data = "DATA"
    case image = "IMAGE"
    case other = "OTHER"
    
    var icon: String {
        switch self {
        case .document: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .report: return "chart.bar.doc.horizontal"
        case .data: return "tablecells"
        case .image: return "photo"
        case .other: return "paperclip"
        }
    }
}
