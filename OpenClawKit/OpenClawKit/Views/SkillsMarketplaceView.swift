import SwiftUI

struct SkillsMarketplaceView: View {
    @StateObject private var viewModel = SkillsViewModel()
    @State private var selectedTab = 0
    @State private var showDetailSheet = false
    @State private var showFilters = false
    
    var body: some View {
        ZStack {
            // Background
            FloatingOrbsBackground()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Main Content
                TabView(selection: $selectedTab) {
                    // Browse Tab
                    browseTab
                        .tag(0)
                    
                    // Search Tab
                    searchTab
                        .tag(1)
                    
                    // My Skills Tab
                    mySkillsTab
                        .tag(2)
                }
                .tabViewStyle(.automatic)
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let skill = viewModel.selectedSkill {
                SkillDetailView(
                    skill: skill,
                    isPresented: $showDetailSheet,
                    installationStatus: viewModel.getInstallationStatus(for: skill),
                    onInstall: {
                        Task {
                            await viewModel.installSkill(skill)
                        }
                    },
                    onUpdate: {
                        Task {
                            await viewModel.updateSkill(skill)
                        }
                    },
                    onUninstall: {
                        Task {
                            await viewModel.uninstallSkill(skill)
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadSkills()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Text("Skills Marketplace")
                .font(.title.weight(.bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Update notification badge
            if !viewModel.updatableSkills.isEmpty {
                Button(action: { selectedTab = 2 }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.coralAccent)
                        Text("\(viewModel.updatableSkills.count) updates")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.coralAccent.opacity(0.2))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            
            // Refresh button
            Button(action: {
                Task {
                    await viewModel.loadSkills()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Browse Tab
    private var browseTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Category filter
                categoryFilter
                
                // Skills grid
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    }
                    .padding(40)
                } else if viewModel.filteredSkills.isEmpty {
                    emptyState
                } else {
                    skillsGrid(skills: viewModel.filteredSkills)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Search Tab
    private var searchTab: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search skills...", text: $viewModel.filter.query)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                
                if !viewModel.filter.query.isEmpty {
                    Button(action: { viewModel.filter.query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .padding()
            
            // Sort and filter options
            HStack {
                // Sort picker
                Picker("Sort", selection: $viewModel.filter.sortBy) {
                    ForEach(SkillSearchFilter.SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(.white)
                
                Spacer()
                
                // Category filter
                Picker("Category", selection: $viewModel.filter.category) {
                    ForEach(SkillCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)
            
            // Results
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(40)
                    } else if viewModel.filteredSkills.isEmpty {
                        emptyState
                    } else {
                        Text("\(viewModel.filteredSkills.count) skills found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        skillsGrid(skills: viewModel.filteredSkills)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - My Skills Tab
    private var mySkillsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Update all button
                if !viewModel.updatableSkills.isEmpty {
                    Button(action: {
                        Task {
                            for skill in viewModel.updatableSkills {
                                await viewModel.updateSkill(skill)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Update All (\(viewModel.updatableSkills.count))")
                                .font(.headline)
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
                    .padding(.horizontal)
                }
                
                // Updates available section
                if !viewModel.updatableSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Updates Available")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        skillsGrid(skills: viewModel.updatableSkills)
                    }
                }
                
                // Installed skills section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Installed Skills (\(viewModel.installedSkills.count))")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if viewModel.installedSkills.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No skills installed yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Browse the marketplace to discover and install skills")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { selectedTab = 0 }) {
                                Text("Browse Skills")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [.coralAccent, .coralDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        skillsGrid(skills: viewModel.installedSkills)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Components
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SkillCategory.allCases) { category in
                    CategoryChip(
                        category: category,
                        isSelected: viewModel.filter.category == category,
                        action: {
                            viewModel.filter.category = category
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func skillsGrid(skills: [Skill]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(skills) { skill in
                SkillCard(
                    skill: skill,
                    installationStatus: viewModel.getInstallationStatus(for: skill),
                    onInstall: {
                        Task {
                            await viewModel.installSkill(skill)
                        }
                    },
                    onUpdate: {
                        Task {
                            await viewModel.updateSkill(skill)
                        }
                    },
                    onTap: {
                        viewModel.selectedSkill = skill
                        showDetailSheet = true
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No skills found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your filters or search query")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: SkillCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.coralAccent, .coralDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    SkillsMarketplaceView()
        .frame(width: 1000, height: 700)
        .preferredColorScheme(.dark)
}
