import SwiftUI

/// Monitor view for active agents
struct AgentMonitorView: View {
    @ObservedObject var viewModel: MissionControlViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Agents list
            if viewModel.agents.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Working agents
                        if !viewModel.workingAgents.isEmpty {
                            agentSection(
                                title: "Active Agents",
                                agents: viewModel.workingAgents,
                                icon: "cpu",
                                color: .green
                            )
                        }
                        
                        // Available agents
                        if !viewModel.availableAgents.isEmpty {
                            agentSection(
                                title: "Available Agents",
                                agents: viewModel.availableAgents,
                                icon: "circle",
                                color: .gray
                            )
                        }
                        
                        // Other agents
                        let otherAgents = viewModel.agents.filter {
                            !viewModel.workingAgents.contains($0) &&
                            !viewModel.availableAgents.contains($0)
                        }
                        
                        if !otherAgents.isEmpty {
                            agentSection(
                                title: "Other Agents",
                                agents: otherAgents,
                                icon: "moon.fill",
                                color: .gray
                            )
                        }
                    }
                    .padding(20)
                }
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 600, height: 700)
        .background(Color(hex: "#0A0A0F"))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Agent Monitor")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(viewModel.stats.activeAgents) active • \(viewModel.stats.totalAgents) total")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    // MARK: - Agent Section
    
    private func agentSection(
        title: String,
        agents: [MissionAgent],
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(agents.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
            
            ForEach(agents) { agent in
                AgentCard(agent: agent, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Agents Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Create a task and spawn an agent to get started")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 16) {
            // Statistics
            HStack(spacing: 24) {
                StatBadge(
                    label: "Working",
                    value: "\(viewModel.stats.activeAgents)",
                    color: .green
                )
                
                StatBadge(
                    label: "Available",
                    value: "\(viewModel.availableAgents.count)",
                    color: .blue
                )
                
                StatBadge(
                    label: "Total Tasks",
                    value: "\(viewModel.agents.reduce(0) { $0 + $1.totalTasksCompleted })",
                    color: .purple
                )
            }
            
            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Agent Card

struct AgentCard: View {
    let agent: MissionAgent
    @ObservedObject var viewModel: MissionControlViewModel
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(Color(hex: agent.statusColor))
                    .frame(width: 10, height: 10)
                
                // Agent info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: agent.roleIcon)
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        
                        Text(agent.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(agent.role)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Model badge
                Text(agent.model)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
            }
            
            // Status
            Text(agent.activityDescription)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            
            // Current task
            if let taskId = agent.currentTask,
               let task = viewModel.tasks.first(where: { $0.id == taskId }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.green)
                        .font(.system(size: 11))
                    
                    Text(task.title)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
            }
            
            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 11))
                    Text("\(agent.totalTasksCompleted) completed")
                        .font(.system(size: 11))
                }
                .foregroundColor(.gray)
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text("Last activity: \(agent.lastActivity.timeAgo)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Details") {
                    showingDetails = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.blue)
                
                if agent.status == .working {
                    Button("Stop") {
                        viewModel.stopAgent(agent)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.deleteAgent(agent)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: agent.statusColor).opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingDetails) {
            AgentDetailView(agent: agent, viewModel: viewModel)
        }
    }
}

// MARK: - Agent Detail View

struct AgentDetailView: View {
    let agent: MissionAgent
    @ObservedObject var viewModel: MissionControlViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(agent.name)
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
            
            Divider()
            
            // Agent info
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(label: "Role", value: agent.role)
                InfoRow(label: "Status", value: agent.status.displayName)
                InfoRow(label: "Model", value: agent.model)
                InfoRow(label: "Tasks Completed", value: "\(agent.totalTasksCompleted)")
                InfoRow(label: "Created", value: agent.createdAt.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Last Activity", value: agent.lastActivity.formatted(date: .abbreviated, time: .shortened))
            }
            
            if !agent.capabilities.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Capabilities")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ForEach(agent.capabilities, id: \.self) { capability in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text(capability)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 550)
        .background(Color(hex: "#0A0A0F"))
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    AgentMonitorView(viewModel: MissionControlViewModel())
}
