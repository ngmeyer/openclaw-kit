import Foundation

/// Mission Control database service using JSON file storage
class MissionDatabase {
    static let shared = MissionDatabase()
    
    private let fileManager = FileManager.default
    
    private init() {
        setupStorage()
    }
    
    /// Storage directory location
    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let missionDir = appSupport.appendingPathComponent("OpenClawKit/MissionControl", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: missionDir, withIntermediateDirectories: true)
        
        return missionDir
    }
    
    private var tasksFileURL: URL {
        storageDirectory.appendingPathComponent("tasks.json")
    }
    
    private var agentsFileURL: URL {
        storageDirectory.appendingPathComponent("agents.json")
    }
    
    private var messagesFileURL: URL {
        storageDirectory.appendingPathComponent("messages.json")
    }
    
    /// Setup storage directory
    private func setupStorage() {
        do {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
            print("✅ Mission Control storage ready at: \(storageDirectory.path)")
        } catch {
            print("❌ Failed to setup storage: \(error)")
        }
    }
    
    // MARK: - Task Operations
    
    /// Save or update a task
    func saveTask(_ task: MissionTask) throws {
        var tasks = try loadTasks()
        
        // Remove existing task with same ID
        tasks.removeAll { $0.id == task.id }
        
        // Add updated task
        tasks.append(task)
        
        // Save to file
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(tasks)
        try data.write(to: tasksFileURL)
        
        print("✅ Saved task: \(task.title)")
    }
    
    /// Load all tasks
    func loadTasks() throws -> [MissionTask] {
        guard fileManager.fileExists(atPath: tasksFileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: tasksFileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([MissionTask].self, from: data)
    }
    
    /// Delete a task
    func deleteTask(_ taskId: UUID) throws {
        var tasks = try loadTasks()
        tasks.removeAll { $0.id == taskId }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(tasks)
        try data.write(to: tasksFileURL)
        
        print("✅ Deleted task: \(taskId)")
    }
    
    // MARK: - Agent Operations
    
    /// Save or update an agent
    func saveAgent(_ agent: MissionAgent) throws {
        var agents = try loadAgents()
        
        // Remove existing agent with same ID
        agents.removeAll { $0.id == agent.id }
        
        // Add updated agent
        agents.append(agent)
        
        // Save to file
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(agents)
        try data.write(to: agentsFileURL)
        
        print("✅ Saved agent: \(agent.name)")
    }
    
    /// Load all agents
    func loadAgents() throws -> [MissionAgent] {
        guard fileManager.fileExists(atPath: agentsFileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: agentsFileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([MissionAgent].self, from: data)
    }
    
    /// Delete an agent
    func deleteAgent(_ agentId: UUID) throws {
        var agents = try loadAgents()
        agents.removeAll { $0.id == agentId }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(agents)
        try data.write(to: agentsFileURL)
        
        print("✅ Deleted agent: \(agentId)")
    }
    
    // MARK: - Agent Message Operations
    
    /// Save an agent message
    func saveMessage(_ message: AgentMessage) throws {
        var messages = try loadRecentMessages(limit: 1000)
        messages.insert(message, at: 0)
        
        // Keep only last 1000 messages
        if messages.count > 1000 {
            messages = Array(messages.prefix(1000))
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(messages)
        try data.write(to: messagesFileURL)
    }
    
    /// Load messages for a specific agent
    func loadMessages(forAgent agentId: UUID, limit: Int = 50) throws -> [AgentMessage] {
        let allMessages = try loadRecentMessages(limit: 1000)
        
        return Array(allMessages
            .filter { $0.fromAgent == agentId || $0.toAgent == agentId }
            .prefix(limit))
    }
    
    /// Load all recent messages
    func loadRecentMessages(limit: Int = 100) throws -> [AgentMessage] {
        guard fileManager.fileExists(atPath: messagesFileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: messagesFileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let messages = try decoder.decode([AgentMessage].self, from: data)
        return Array(messages.prefix(limit))
    }
    
    // MARK: - Database Management
    
    /// Clear all data (for testing)
    func clearAllData() throws {
        try? fileManager.removeItem(at: tasksFileURL)
        try? fileManager.removeItem(at: agentsFileURL)
        try? fileManager.removeItem(at: messagesFileURL)
        
        print("✅ Cleared all Mission Control data")
    }
    
    /// Get database statistics
    func getStatistics() throws -> DatabaseStatistics {
        let tasks = try loadTasks()
        let agents = try loadAgents()
        let messages = try loadRecentMessages(limit: 10000)
        
        return DatabaseStatistics(
            totalTasks: tasks.count,
            totalAgents: agents.count,
            totalMessages: messages.count
        )
    }
}

// MARK: - Supporting Types

enum DatabaseError: Error {
    case invalidData
}

struct DatabaseStatistics {
    let totalTasks: Int
    let totalAgents: Int
    let totalMessages: Int
}
