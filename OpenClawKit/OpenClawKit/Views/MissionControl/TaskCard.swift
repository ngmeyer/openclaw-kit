import SwiftUI

/// Individual task card in Kanban board
struct TaskCard: View {
    let task: MissionTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with priority
            HStack {
                Image(systemName: task.priorityIcon)
                    .foregroundColor(Color(hex: task.priority.color))
                    .font(.system(size: 14))
                
                Spacer()
                
                if let agent = task.assignedAgent {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 10))
                        Text(agent)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                }
            }
            
            // Title
            Text(task.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(3)
            
            // Description preview
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            // Footer
            HStack(spacing: 12) {
                // Planning Q&A indicator
                if !task.planningQA.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.system(size: 10))
                        Text("\(task.planningQA.count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.purple)
                }
                
                // Deliverables indicator
                if !task.deliverables.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                        Text("\(task.deliverables.count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.green)
                }
                
                Spacer()
                
                // Updated time
                Text(task.updatedAt.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            // Tags
            if !task.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(task.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: task.statusColor).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Date Extension

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskCard(task: MissionTask(
            title: "Research Coffee Machines",
            description: "Find the best coffee machines under $200 with good reviews on Amazon.",
            status: .inProgress,
            assignedAgent: "Researcher-01",
            priority: .high,
            tags: ["research", "product"]
        ))
        
        TaskCard(task: MissionTask(
            title: "Build Pricing Scraper",
            description: "Create Python script to scrape pricing data from e-commerce sites.",
            status: .assigned,
            priority: .medium
        ))
    }
    .padding()
    .frame(width: 280)
    .background(Color(hex: "#0A0A0F"))
}
