import SwiftUI
import UniformTypeIdentifiers

/// Main Mission Control dashboard view with Kanban board
struct MissionControlView: View {
    @StateObject private var viewModel = MissionControlViewModel()
    @State private var draggedTask: MissionTask?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Kanban Board
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(TaskStatus.allCases) { status in
                        KanbanColumn(
                            status: status,
                            tasks: viewModel.tasks(for: status),
                            draggedTask: $draggedTask,
                            onTaskTap: { task in
                                viewModel.selectedTask = task
                                viewModel.showingTaskDetail = true
                            },
                            onDrop: { task in
                                viewModel.moveTask(task, to: status)
                            }
                        )
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer Stats
            footer
        }
        .background(Color(hex: "#0A0A0F"))
        .sheet(isPresented: $viewModel.showingTaskDetail) {
            if let task = viewModel.selectedTask {
                TaskDetailView(task: task, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showingPlanningView) {
            if let task = viewModel.planningTask {
                PlanningView(task: task, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showingAgentMonitor) {
            AgentMonitorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingNewTaskSheet) {
            NewTaskSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Mission Control")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Agent Monitor Button
            Button(action: {
                viewModel.showingAgentMonitor = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .foregroundColor(.green)
                    Text("\(viewModel.stats.activeAgents)")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    Text("Active")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // New Task Button
            Button(action: {
                viewModel.showingNewTaskSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Task")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#3B82F6"))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 24) {
            // Gateway status
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isGatewayConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isGatewayConnected ? "Gateway Connected" : "Gateway Offline")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.isGatewayConnected ? .green : .red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            
            Divider()
                .frame(height: 24)
            
            StatItem(label: "Total Tasks", value: "\(viewModel.stats.total)")
            StatItem(label: "In Progress", value: "\(viewModel.stats.inProgress)")
            StatItem(label: "Completed Today", value: "\(viewModel.stats.done)")
            
            Spacer()
            
            // Completion Rate
            HStack(spacing: 8) {
                ProgressView(value: viewModel.stats.completionRate)
                    .frame(width: 100)
                Text("\(Int(viewModel.stats.completionRate * 100))%")
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
            }
        }
        .padding(16)
    }
}

// MARK: - Kanban Column

struct KanbanColumn: View {
    let status: TaskStatus
    let tasks: [MissionTask]
    @Binding var draggedTask: MissionTask?
    let onTaskTap: (MissionTask) -> Void
    let onDrop: (MissionTask) -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack {
                Image(systemName: status.icon)
                    .foregroundColor(Color(hex: status.color))
                Text(status.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Tasks
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tasks) { task in
                        TaskCard(task: task)
                            .onTapGesture {
                                onTaskTap(task)
                            }
                            .onDrag {
                                self.draggedTask = task
                                return NSItemProvider(object: task.id.uuidString as NSString)
                            }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 280)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isTargeted ? 0.08 : 0.05))
        )
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            guard let draggedTask = draggedTask else { return false }
            onDrop(draggedTask)
            self.draggedTask = nil
            return true
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - New Task Sheet

struct NewTaskSheet: View {
    @ObservedObject var viewModel: MissionControlViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Create New Task")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
            }
            
            // Form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    TextField("Enter task title...", text: $title)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    TextEditor(text: $description)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            HStack {
                                Image(systemName: p.icon)
                                Text(p.displayName)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                
                Spacer()
                
                Button("Create Task") {
                    viewModel.createTask(
                        title: title,
                        description: description,
                        priority: priority
                    )
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#3B82F6"))
                .cornerRadius(8)
                .disabled(title.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500, height: 450)
        .background(Color(hex: "#0A0A0F"))
    }
}

#Preview {
    MissionControlView()
}
