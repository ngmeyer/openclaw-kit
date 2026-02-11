import SwiftUI

struct SkillDetailView: View {
    let skill: Skill
    @Binding var isPresented: Bool
    let installationStatus: InstallationStatus
    let onInstall: () -> Void
    let onUpdate: () -> Void
    let onUninstall: () -> Void
    
    @State private var reviews: [SkillReview] = []
    @State private var isLoadingReviews = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Quick stats
                        statsSection
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Tabs
                        Picker("Tab", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Installation").tag(1)
                            Text("Reviews").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Tab content
                        Group {
                            switch selectedTab {
                            case 0:
                                overviewTab
                            case 1:
                                installationTab
                            case 2:
                                reviewsTab
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
                
                // Bottom action bar
                actionBar
            }
        }
        .task {
            await loadReviews()
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.bluePrimary, .blueLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: skill.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text("by \(skill.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text("v\(skill.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(skill.category.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.bluePrimary)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 32) {
            SkillStatItem(
                icon: "star.fill",
                value: skill.rating.map { String(format: "%.1f", $0) } ?? "N/A",
                label: "\(skill.reviewCount) reviews",
                color: .yellow
            )
            
            SkillStatItem(
                icon: "arrow.down.circle.fill",
                value: skill.formattedDownloads,
                label: "downloads",
                color: .blueLight
            )
            
            if let repo = skill.repository {
                Button(action: {
                    if let url = URL(string: repo) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .foregroundColor(.coralAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("View")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("on GitHub")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(skill.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if !skill.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(skill.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.bluePrimary.opacity(0.3))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            if !skill.dependencies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dependencies")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(skill.dependencies, id: \.self) { dependency in
                        HStack {
                            Image(systemName: "cube.box")
                                .foregroundColor(.coralAccent)
                            Text(dependency)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Installation Tab
    private var installationTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installation Instructions")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(skill.installationInstructions)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if skill.isInstalled, let installedVersion = skill.installedVersion {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Installed version: \(installedVersion)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Reviews Tab
    private var reviewsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingReviews {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if reviews.isEmpty {
                Text("No reviews yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 16) {
            if skill.isInstalled {
                // Uninstall button
                Button(action: onUninstall) {
                    HStack {
                        if installationStatus == .uninstalling {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        }
                        Text(installationStatus == .uninstalling ? "Uninstalling..." : "Uninstall")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(installationStatus.isLoading)
                
                if skill.hasUpdate {
                    // Update button
                    Button(action: onUpdate) {
                        HStack {
                            if case .updating = installationStatus {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            }
                            Text(installationStatus.buttonTitle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.coralAccent, .coralDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(installationStatus.isLoading)
                }
            } else {
                // Install button
                Button(action: onInstall) {
                    HStack {
                        if case .installing = installationStatus {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        }
                        Text(installationStatus.buttonTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.coralAccent, .coralDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(installationStatus.isLoading)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Methods
    private func loadReviews() async {
        isLoadingReviews = true
        do {
            reviews = try await ClawHubAPIClient.shared.fetchReviews(for: skill.id)
        } catch {
            print("Failed to load reviews: \(error)")
        }
        isLoadingReviews = false
    }
}

// MARK: - Skill Stat Item
struct SkillStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let review: SkillReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.author)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(review.comment)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(review.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup")
                        .font(.caption)
                    Text("\(review.helpful)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
