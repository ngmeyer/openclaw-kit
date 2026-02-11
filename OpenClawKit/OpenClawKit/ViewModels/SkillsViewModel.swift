import Foundation
import Combine
import SwiftUI

@MainActor
class SkillsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allSkills: [Skill] = []
    @Published var filteredSkills: [Skill] = []
    @Published var installedSkills: [Skill] = []
    @Published var updatableSkills: [Skill] = []
    @Published var filter = SkillSearchFilter()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSkill: Skill?
    @Published var installationStatuses: [String: InstallationStatus] = [:]
    
    // MARK: - Private Properties
    private let apiClient = ClawHubAPIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupFilterObserver()
    }
    
    // MARK: - Public Methods
    
    func loadSkills() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let skills = try await apiClient.fetchSkills()
            allSkills = skills
            installedSkills = skills.filter { $0.isInstalled }
            updatableSkills = skills.filter { $0.hasUpdate }
            applyFilters()
        } catch {
            errorMessage = "Failed to load skills: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func searchSkills() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let skills = try await apiClient.searchSkills(
                query: filter.query,
                category: filter.category,
                sortBy: filter.sortBy
            )
            filteredSkills = skills
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func installSkill(_ skill: Skill) async {
        installationStatuses[skill.id] = .installing(progress: 0)
        
        do {
            try await apiClient.installSkill(id: skill.id) { [weak self] progress in
                Task { @MainActor in
                    self?.installationStatuses[skill.id] = .installing(progress: progress)
                }
            }
            
            installationStatuses[skill.id] = .installed
            
            // Update skill in all lists
            if let index = allSkills.firstIndex(where: { $0.id == skill.id }) {
                var updatedSkill = allSkills[index]
                updatedSkill = Skill(
                    id: updatedSkill.id,
                    name: updatedSkill.name,
                    description: updatedSkill.description,
                    shortDescription: updatedSkill.shortDescription,
                    author: updatedSkill.author,
                    version: updatedSkill.version,
                    category: updatedSkill.category,
                    icon: updatedSkill.icon,
                    rating: updatedSkill.rating,
                    reviewCount: updatedSkill.reviewCount,
                    downloads: updatedSkill.downloads,
                    repository: updatedSkill.repository,
                    homepage: updatedSkill.homepage,
                    screenshots: updatedSkill.screenshots,
                    installationInstructions: updatedSkill.installationInstructions,
                    tags: updatedSkill.tags,
                    dependencies: updatedSkill.dependencies,
                    isInstalled: true,
                    installedVersion: updatedSkill.version,
                    hasUpdate: false,
                    publishedAt: updatedSkill.publishedAt,
                    updatedAt: updatedSkill.updatedAt
                )
                allSkills[index] = updatedSkill
                installedSkills.append(updatedSkill)
                applyFilters()
            }
            
            // Auto-dismiss after success
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            installationStatuses[skill.id] = nil
            
        } catch {
            installationStatuses[skill.id] = .failed(error: error.localizedDescription)
            errorMessage = "Failed to install \(skill.name): \(error.localizedDescription)"
        }
    }
    
    func updateSkill(_ skill: Skill) async {
        installationStatuses[skill.id] = .updating(progress: 0)
        
        do {
            try await apiClient.updateSkill(id: skill.id) { [weak self] progress in
                Task { @MainActor in
                    self?.installationStatuses[skill.id] = .updating(progress: progress)
                }
            }
            
            installationStatuses[skill.id] = .installed
            
            // Update skill version
            if let index = allSkills.firstIndex(where: { $0.id == skill.id }) {
                var updatedSkill = allSkills[index]
                updatedSkill = Skill(
                    id: updatedSkill.id,
                    name: updatedSkill.name,
                    description: updatedSkill.description,
                    shortDescription: updatedSkill.shortDescription,
                    author: updatedSkill.author,
                    version: updatedSkill.version,
                    category: updatedSkill.category,
                    icon: updatedSkill.icon,
                    rating: updatedSkill.rating,
                    reviewCount: updatedSkill.reviewCount,
                    downloads: updatedSkill.downloads,
                    repository: updatedSkill.repository,
                    homepage: updatedSkill.homepage,
                    screenshots: updatedSkill.screenshots,
                    installationInstructions: updatedSkill.installationInstructions,
                    tags: updatedSkill.tags,
                    dependencies: updatedSkill.dependencies,
                    isInstalled: true,
                    installedVersion: updatedSkill.version,
                    hasUpdate: false,
                    publishedAt: updatedSkill.publishedAt,
                    updatedAt: updatedSkill.updatedAt
                )
                allSkills[index] = updatedSkill
                
                // Remove from updatable list
                updatableSkills.removeAll { $0.id == skill.id }
                applyFilters()
            }
            
            // Auto-dismiss after success
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            installationStatuses[skill.id] = nil
            
        } catch {
            installationStatuses[skill.id] = .failed(error: error.localizedDescription)
            errorMessage = "Failed to update \(skill.name): \(error.localizedDescription)"
        }
    }
    
    func uninstallSkill(_ skill: Skill) async {
        installationStatuses[skill.id] = .uninstalling
        
        do {
            try await apiClient.uninstallSkill(id: skill.id)
            installationStatuses[skill.id] = .notInstalled
            
            // Update skill in all lists
            if let index = allSkills.firstIndex(where: { $0.id == skill.id }) {
                var updatedSkill = allSkills[index]
                updatedSkill = Skill(
                    id: updatedSkill.id,
                    name: updatedSkill.name,
                    description: updatedSkill.description,
                    shortDescription: updatedSkill.shortDescription,
                    author: updatedSkill.author,
                    version: updatedSkill.version,
                    category: updatedSkill.category,
                    icon: updatedSkill.icon,
                    rating: updatedSkill.rating,
                    reviewCount: updatedSkill.reviewCount,
                    downloads: updatedSkill.downloads,
                    repository: updatedSkill.repository,
                    homepage: updatedSkill.homepage,
                    screenshots: updatedSkill.screenshots,
                    installationInstructions: updatedSkill.installationInstructions,
                    tags: updatedSkill.tags,
                    dependencies: updatedSkill.dependencies,
                    isInstalled: false,
                    installedVersion: nil,
                    hasUpdate: false,
                    publishedAt: updatedSkill.publishedAt,
                    updatedAt: updatedSkill.updatedAt
                )
                allSkills[index] = updatedSkill
                installedSkills.removeAll { $0.id == skill.id }
                applyFilters()
            }
            
            // Auto-dismiss after success
            try? await Task.sleep(nanoseconds: 500_000_000)
            installationStatuses[skill.id] = nil
            
        } catch {
            installationStatuses[skill.id] = .failed(error: error.localizedDescription)
            errorMessage = "Failed to uninstall \(skill.name): \(error.localizedDescription)"
        }
    }
    
    func checkForUpdates() async {
        do {
            let updates = try await apiClient.checkForUpdates()
            updatableSkills = updates
        } catch {
            errorMessage = "Failed to check for updates: \(error.localizedDescription)"
        }
    }
    
    func getInstallationStatus(for skill: Skill) -> InstallationStatus {
        if let status = installationStatuses[skill.id] {
            return status
        }
        return skill.isInstalled ? .installed : .notInstalled
    }
    
    // MARK: - Private Methods
    
    private func setupFilterObserver() {
        $filter
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var skills = allSkills
        
        // Filter by category
        if filter.category != .all {
            skills = skills.filter { $0.category == filter.category }
        }
        
        // Filter by search query
        if !filter.query.isEmpty {
            skills = skills.filter { skill in
                skill.name.localizedCaseInsensitiveContains(filter.query) ||
                skill.description.localizedCaseInsensitiveContains(filter.query) ||
                skill.tags.contains(where: { $0.localizedCaseInsensitiveContains(filter.query) })
            }
        }
        
        // Filter by installed only
        if filter.showInstalledOnly {
            skills = skills.filter { $0.isInstalled }
        }
        
        // Filter by updates only
        if filter.showUpdatesOnly {
            skills = skills.filter { $0.hasUpdate }
        }
        
        // Sort
        switch filter.sortBy {
        case .popular:
            skills.sort { $0.downloads > $1.downloads }
        case .newest:
            skills.sort { $0.publishedAt > $1.publishedAt }
        case .updated:
            skills.sort { $0.updatedAt > $1.updatedAt }
        case .rating:
            skills.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .name:
            skills.sort { $0.name < $1.name }
        }
        
        filteredSkills = skills
    }
}
