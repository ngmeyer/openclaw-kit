import Foundation
import Combine

/// View model for Mission Control dashboard
@MainActor
class MissionControlViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var tasks: [MissionTask] = []
    @Published var agents: [MissionAgent] = []
    @Published var recentMessages: [AgentMessage] = []
    
    @Published var selectedTask: MissionTask?
    @Published var selectedAgent: MissionAgent?
    
    @Published var isLoading = false
    @Published var error: MissionError?
    
    @Published var showingTaskDetail = false
    @Published var showingPlanningView = false
    @Published var showingAgentMonitor = false
    @Published var showingNewTaskSheet = false
    
    // Gateway connection
    @Published var isGatewayConnected = false
    @Published var gatewayError: String?
    
    // Planning state
    @Published var planningTask: MissionTask?
    @Published var currentQuestion: String = ""
    @Published var currentAnswer: String = ""
    @Published var planningQuestions: [QAPair] = []
    @Published var isPlanningComplete = false
    
    // Statistics
    @Published var stats = TaskStatistics()
    
    // MARK: - Private Properties
    
    private let database = MissionDatabase.shared
    private let gateway = OpenClawGateway.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadData()
        setupAutoRefresh()
        setupGatewayObserver()
    }
    
    /// Setup gateway connection observer
    private func setupGatewayObserver() {
        gateway.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isGatewayConnected)
        
        gateway.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.gatewayError = error?.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    /// Load all data from database
    func loadData() {
        isLoading = true
        
        do {
            tasks = try database.loadTasks()
            agents = try database.loadAgents()
            recentMessages = try database.loadRecentMessages(limit: 100)
            
            updateStatistics()
            
            print("✅ Loaded \(tasks.count) tasks, \(agents.count) agents")
        } catch {
            self.error = .loadFailed(error.localizedDescription)
            print("❌ Failed to load data: \(error)")
        }
        
        isLoading = false
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        // Refresh data every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshAgentStatus()
            }
            .store(in: &cancellables)
    }
    
    /// Refresh agent status from OpenClaw Gateway
    private func refreshAgentStatus() {
        Task {
            do {
                // First check gateway connection
                await gateway.checkConnection()
                
                // Get active sessions from gateway
                let sessions = try await gateway.listSessions(kinds: ["isolated", "subagent"])
                
                // Collect all updates first (non-mutating)
                var updatedAgents = agents
                
                // Apply status updates based on gateway sessions
                for session in sessions {
                    if let agentIndex = updatedAgents.firstIndex(where: { $0.sessionKey == session.key }) {
                        updatedAgents[agentIndex].updateStatus(session.status == "active" ? .working : .idle)
                        updatedAgents[agentIndex].touch()
                    }
                }
                
                // Reload from database as well
                let dbAgents = try database.loadAgents()
                
                // Merge: preserve runtime status from gateway
                for dbAgent in dbAgents {
                    if !updatedAgents.contains(where: { $0.id == dbAgent.id }) {
                        updatedAgents.append(dbAgent)
                    }
                }
                
                // Apply all changes atomically (single assignment)
                self.agents = updatedAgents
                updateStatistics()
            } catch {
                print("❌ Failed to refresh agents: \(error)")
            }
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        stats = TaskStatistics(
            total: tasks.count,
            planning: tasks.filter { $0.status == .planning }.count,
            inbox: tasks.filter { $0.status == .inbox }.count,
            assigned: tasks.filter { $0.status == .assigned }.count,
            inProgress: tasks.filter { $0.status == .inProgress }.count,
            testing: tasks.filter { $0.status == .testing }.count,
            review: tasks.filter { $0.status == .review }.count,
            done: tasks.filter { $0.status == .done }.count,
            activeAgents: agents.filter { $0.status == .working }.count,
            totalAgents: agents.count
        )
    }
    
    // MARK: - Task Operations
    
    /// Create a new task
    func createTask(title: String, description: String, priority: TaskPriority = .medium) {
        let task = MissionTask(
            title: title,
            description: description,
            status: .planning,
            priority: priority
        )
        
        do {
            try database.saveTask(task)
            tasks.append(task)
            updateStatistics()
            
            // Start planning flow
            startPlanning(for: task)
            
            print("✅ Created task: \(title)")
        } catch {
            self.error = .saveFailed(error.localizedDescription)
            print("❌ Failed to create task: \(error)")
        }
    }
    
    /// Update an existing task
    func updateTask(_ task: MissionTask) {
        var updatedTask = task
        updatedTask.touch()
        
        do {
            try database.saveTask(updatedTask)
            
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
            
            updateStatistics()
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }
    
    /// Delete a task
    func deleteTask(_ task: MissionTask) {
        do {
            try database.deleteTask(task.id)
            tasks.removeAll { $0.id == task.id }
            updateStatistics()
            
            print("✅ Deleted task: \(task.title)")
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
        }
    }
    
    /// Move task to a new status
    func moveTask(_ task: MissionTask, to status: TaskStatus) {
        var updatedTask = task
        updatedTask.moveTo(status: status)
        updateTask(updatedTask)
    }
    
    /// Assign task to an agent
    func assignTask(_ task: MissionTask, to agent: MissionAgent) {
        var updatedTask = task
        updatedTask.assign(to: agent.name)
        
        var updatedAgent = agent
        updatedAgent.assignTask(task.id)
        
        do {
            try database.saveTask(updatedTask)
            try database.saveAgent(updatedAgent)
            
            if let taskIndex = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[taskIndex] = updatedTask
            }
            
            if let agentIndex = agents.firstIndex(where: { $0.id == agent.id }) {
                agents[agentIndex] = updatedAgent
            }
            
            updateStatistics()
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Planning Flow
    
    /// Start planning flow for a task
    func startPlanning(for task: MissionTask) {
        planningTask = task
        planningQuestions = []
        isPlanningComplete = false
        
        // Generate initial questions
        generatePlanningQuestions()
        
        showingPlanningView = true
    }
    
    /// Generate planning questions using AI
    private func generatePlanningQuestions() {
        // Default questions for MVP
        let defaultQuestions = [
            "What is the primary goal of this task?",
            "Who is the target audience or beneficiary?",
            "What are the key requirements or constraints?",
            "What deliverables are expected?",
            "What skills or capabilities are needed?"
        ]
        
        planningQuestions = defaultQuestions.map { question in
            QAPair(question: question, answer: "")
        }
        
        if let first = planningQuestions.first {
            currentQuestion = first.question
        }
    }
    
    /// Answer current planning question
    func answerPlanningQuestion(_ answer: String) {
        guard let index = planningQuestions.firstIndex(where: { $0.question == currentQuestion }) else {
            return
        }
        
        planningQuestions[index] = QAPair(
            id: planningQuestions[index].id,
            question: currentQuestion,
            answer: answer,
            timestamp: Date()
        )
        
        // Move to next question
        if index + 1 < planningQuestions.count {
            currentQuestion = planningQuestions[index + 1].question
            currentAnswer = ""
        } else {
            completePlanning()
        }
    }
    
    /// Complete planning and create agent
    private func completePlanning() {
        isPlanningComplete = true
        
        guard var task = planningTask else { return }
        
        // Save planning Q&A to task
        task.planningQA = planningQuestions
        task.moveTo(status: .inbox)
        
        do {
            try database.saveTask(task)
            
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
            
            updateStatistics()
            
            print("✅ Planning complete for: \(task.title)")
            
            // Show option to spawn agent
            selectedTask = task
            showingPlanningView = false
            showingTaskDetail = true
            
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Agent Operations
    
    /// Spawn a new agent for a task
    func spawnAgent(for task: MissionTask, config: AgentSpawnConfig) async {
        isLoading = true
        
        do {
            // Create agent spawn request for gateway
            let spawnRequest = AgentSpawnRequest(
                task: config.generatePrompt(),
                agentId: config.name,
                model: config.model,
                label: "mission-control:\(task.id.uuidString.prefix(8))",
                capabilities: config.capabilities,
                systemPrompt: """
                You are \(config.name), a specialized AI agent with the role: \(config.role).
                You are working autonomously on a task for Mission Control.
                Report your progress clearly and provide deliverables when complete.
                """
            )
            
            // Spawn via OpenClaw Gateway
            let response = try await gateway.spawnAgent(config: spawnRequest)
            
            // Create local agent record
            let agent = MissionAgent(
                name: config.name,
                role: config.role,
                sessionKey: response.sessionKey,
                status: .working,
                currentTask: task.id,
                capabilities: config.capabilities,
                model: config.model
            )
            
            // Save to database
            try database.saveAgent(agent)
            agents.append(agent)
            
            // Assign task to agent
            assignTask(task, to: agent)
            
            // Subscribe to agent events for real-time updates
            subscribeToAgentEvents(agent: agent)
            
            print("✅ Spawned agent: \(config.name) with session: \(response.sessionKey)")
            
        } catch {
            self.error = .agentSpawnFailed(error.localizedDescription)
            print("❌ Failed to spawn agent: \(error)")
        }
        
        isLoading = false
    }
    
    /// Subscribe to real-time events from an agent
    private func subscribeToAgentEvents(agent: MissionAgent) {
        guard let sessionKey = agent.sessionKey else { return }
        
        gateway.subscribeToEvents(sessionKey: sessionKey) { [weak self] event in
            Task { @MainActor in
                self?.handleAgentEvent(agent: agent, event: event)
            }
        }
    }
    
    /// Handle incoming agent event
    private func handleAgentEvent(agent: MissionAgent, event: SessionEvent) {
        Task { @MainActor in
            // Parse event and update agent/task status
            switch event.type {
            case "progress":
                // Agent reported progress
                if let data = event.data.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    sendMessage(from: agent.id, to: nil, message: message, type: .update)
                }
                
            case "complete":
                // Agent completed task
                if var agentToUpdate = agents.first(where: { $0.id == agent.id }) {
                    agentToUpdate.completeTask()
                    try? database.saveAgent(agentToUpdate)
                    
                    if let index = agents.firstIndex(where: { $0.id == agent.id }) {
                        agents[index] = agentToUpdate
                    }
                    
                    // Move task to review
                    if let taskId = agent.currentTask,
                       var task = tasks.first(where: { $0.id == taskId }) {
                        task.moveTo(status: .review)
                        try? database.saveTask(task)
                        
                        if let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) {
                            tasks[taskIndex] = task
                        }
                    }
                }
                
                updateStatistics()
                
            case "error":
                // Agent encountered error
                if var agentToUpdate = agents.first(where: { $0.id == agent.id }) {
                    agentToUpdate.updateStatus(.error)
                    try? database.saveAgent(agentToUpdate)
                    
                    if let index = agents.firstIndex(where: { $0.id == agent.id }) {
                        agents[index] = agentToUpdate
                    }
                }
                
            default:
                break
            }
        }
    }
    
    /// Create agent spawn configuration from task
    func createAgentConfig(for task: MissionTask) -> AgentSpawnConfig {
        // Determine role based on task
        let role = determineAgentRole(for: task)
        let name = "\(role)-\(String(task.id.uuidString.prefix(8)))"
        
        return AgentSpawnConfig(
            name: name,
            role: role,
            model: "sonnet",
            capabilities: ["web_search", "web_fetch", "read", "write"],
            taskDescription: task.description,
            planningContext: task.planningQA
        )
    }
    
    /// Determine appropriate agent role for a task
    private func determineAgentRole(for task: MissionTask) -> String {
        let description = task.description.lowercased()
        
        if description.contains("research") || description.contains("find") {
            return "Researcher"
        } else if description.contains("code") || description.contains("develop") {
            return "Developer"
        } else if description.contains("write") || description.contains("document") {
            return "Writer"
        } else if description.contains("design") {
            return "Designer"
        } else if description.contains("test") || description.contains("qa") {
            return "Tester"
        } else {
            return "Generalist"
        }
    }
    
    /// Stop an agent
    func stopAgent(_ agent: MissionAgent) {
        Task {
            isLoading = true
            
            // Stop via gateway if session exists
            if let sessionKey = agent.sessionKey {
                do {
                    try await gateway.stopSession(sessionKey: sessionKey)
                    gateway.unsubscribeFromEvents()
                } catch {
                    print("⚠️ Failed to stop gateway session: \(error)")
                    // Continue with local cleanup
                }
            }
            
            var updatedAgent = agent
            updatedAgent.updateStatus(.offline)
            updatedAgent.completeTask()
            
            do {
                try database.saveAgent(updatedAgent)
                
                if let index = agents.firstIndex(where: { $0.id == agent.id }) {
                    agents[index] = updatedAgent
                }
                
                updateStatistics()
                print("✅ Stopped agent: \(agent.name)")
                
            } catch {
                self.error = .saveFailed(error.localizedDescription)
            }
            
            isLoading = false
        }
    }
    
    /// Delete an agent
    func deleteAgent(_ agent: MissionAgent) {
        do {
            try database.deleteAgent(agent.id)
            agents.removeAll { $0.id == agent.id }
            updateStatistics()
            
            print("✅ Deleted agent: \(agent.name)")
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Message Operations
    
    /// Send a message between agents
    func sendMessage(from: UUID, to: UUID?, message: String, type: AgentMessage.MessageType = .communication) {
        let agentMessage = AgentMessage(
            fromAgent: from,
            toAgent: to,
            message: message,
            messageType: type
        )
        
        do {
            try database.saveMessage(agentMessage)
            recentMessages.insert(agentMessage, at: 0)
            
            // Keep only last 100 in memory
            if recentMessages.count > 100 {
                recentMessages = Array(recentMessages.prefix(100))
            }
        } catch {
            print("❌ Failed to save message: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get tasks by status
    func tasks(for status: TaskStatus) -> [MissionTask] {
        tasks.filter { $0.status == status }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// Get available agents
    var availableAgents: [MissionAgent] {
        agents.filter { $0.isAvailable }
    }
    
    /// Get working agents
    var workingAgents: [MissionAgent] {
        agents.filter { $0.status == .working }
    }
}

// MARK: - Supporting Types

struct TaskStatistics {
    var total: Int = 0
    var planning: Int = 0
    var inbox: Int = 0
    var assigned: Int = 0
    var inProgress: Int = 0
    var testing: Int = 0
    var review: Int = 0
    var done: Int = 0
    var activeAgents: Int = 0
    var totalAgents: Int = 0
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(done) / Double(total)
    }
}

enum MissionError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case agentSpawnFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let msg): return "Failed to load data: \(msg)"
        case .saveFailed(let msg): return "Failed to save: \(msg)"
        case .deleteFailed(let msg): return "Failed to delete: \(msg)"
        case .agentSpawnFailed(let msg): return "Failed to spawn agent: \(msg)"
        }
    }
}
