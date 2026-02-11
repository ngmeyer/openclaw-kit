import SwiftUI

/// Detailed view of a single task
struct TaskDetailView: View {
    let task: MissionTask
    @ObservedObject var viewModel: MissionControlViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedDescription: String
    
    init(task: MissionTask, viewModel: MissionControlViewModel) {
        self.task = task
        self.viewModel = viewModel
        _editedTitle = State(initialValue: task.title)
        _editedDescription = State(initialValue: task.description)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                header
                
                Divider()
                
                // Task Info
                taskInfo
                
                // Planning Q&A
                if !task.planningQA.isEmpty {
                    Divider()
                    planningSection
                }
                
                // Deliverables
                if !task.deliverables.isEmpty {
                    Divider()
                    deliverablesSection
                }
                
                // Agent Assignment
                Divider()
                agentSection
                
                // Actions
                Divider()
                actionsSection
            }
            .padding(24)
        }
        .frame(width: 600, height: 700)
        .background(Color(hex: "#0A0A0F"))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                if isEditing {
                    TextField("Task title", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(task.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: task.status.icon)
                        Text(task.status.displayName)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: task.statusColor))
                    .cornerRadius(6)
                    
                    // Priority badge
                    HStack(spacing: 4) {
                        Image(systemName: task.priorityIcon)
                        Text(task.priority.displayName)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: task.priority.color).opacity(0.3))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#3B82F6"))
                    .cornerRadius(8)
                    
                    Button("Cancel") {
                        isEditing = false
                        editedTitle = task.title
                        editedDescription = task.description
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.gray)
                } else {
                    Button(action: { isEditing = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Task Info
    
    private var taskInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if isEditing {
                TextEditor(text: $editedDescription)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            } else {
                Text(task.description.isEmpty ? "No description" : task.description)
                    .font(.system(size: 14))
                    .foregroundColor(task.description.isEmpty ? .gray : .white.opacity(0.9))
            }
            
            // Metadata
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Updated")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(task.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Planning Section
    
    private var planningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Planning Q&A")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(task.planningQA) { qa in
                VStack(alignment: .leading, spacing: 8) {
                    Text(qa.question)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.purple.opacity(0.9))
                    
                    Text(qa.answer)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Deliverables Section
    
    private var deliverablesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deliverables")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(task.deliverables) { deliverable in
                HStack(spacing: 12) {
                    Image(systemName: deliverable.type.icon)
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deliverable.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        if let filePath = deliverable.filePath {
                            Text(filePath)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // View deliverable
                    }) {
                        Text("View")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Agent Section
    
    private var agentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agent Assignment")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if let agentName = task.assignedAgent {
                HStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .foregroundColor(.green)
                    
                    Text(agentName)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("View Agent") {
                        viewModel.showingAgentMonitor = true
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            } else if task.status == .inbox || task.status == .planning {
                Button(action: {
                    let config = viewModel.createAgentConfig(for: task)
                    Task {
                        await viewModel.spawnAgent(for: task, config: config)
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Spawn Agent")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#3B82F6"))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else {
                Text("No agent assigned")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Status change buttons
                ForEach([TaskStatus.inProgress, .testing, .review, .done], id: \.self) { status in
                    if task.status != status {
                        Button(action: {
                            viewModel.moveTask(task, to: status)
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: status.icon)
                                Text(status.displayName)
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: status.color).opacity(0.3))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Delete button
            Button(action: {
                viewModel.deleteTask(task)
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete Task")
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.2))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = editedTitle
        updatedTask.description = editedDescription
        
        viewModel.updateTask(updatedTask)
        isEditing = false
    }
}

#Preview {
    TaskDetailView(
        task: MissionTask(
            title: "Research Coffee Machines",
            description: "Find the best coffee machines under $200 with good reviews on Amazon.",
            status: .inProgress,
            assignedAgent: "Researcher-01",
            planningQA: [
                QAPair(question: "What is the goal?", answer: "Research for blog post"),
                QAPair(question: "Who is the audience?", answer: "Coffee enthusiasts")
            ],
            deliverables: [
                Deliverable(name: "Research Report", type: .report, content: "...")
            ],
            priority: .high
        ),
        viewModel: MissionControlViewModel()
    )
}
