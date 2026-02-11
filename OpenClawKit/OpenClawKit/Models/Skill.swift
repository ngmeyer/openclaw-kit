import Foundation

// MARK: - Skill Model
struct Skill: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let shortDescription: String
    let author: String
    let version: String
    let category: SkillCategory
    let icon: String
    let rating: Double?
    let reviewCount: Int
    let downloads: Int
    let repository: String?
    let homepage: String?
    let screenshots: [String]
    let installationInstructions: String
    let tags: [String]
    let dependencies: [String]
    let isInstalled: Bool
    let installedVersion: String?
    let hasUpdate: Bool
    let publishedAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, author, version, category, icon, rating
        case reviewCount = "review_count"
        case downloads, repository, homepage, screenshots, tags, dependencies
        case installationInstructions = "installation_instructions"
        case shortDescription = "short_description"
        case isInstalled = "is_installed"
        case installedVersion = "installed_version"
        case hasUpdate = "has_update"
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
    }
    
    // Computed property for display
    var formattedDownloads: String {
        if downloads >= 1000000 {
            return String(format: "%.1fM", Double(downloads) / 1000000.0)
        } else if downloads >= 1000 {
            return String(format: "%.1fK", Double(downloads) / 1000.0)
        }
        return "\(downloads)"
    }
    
    var ratingStars: String {
        guard let rating = rating else { return "No ratings" }
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        var stars = String(repeating: "★", count: fullStars)
        if hasHalfStar {
            stars += "½"
        }
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        stars += String(repeating: "☆", count: emptyStars)
        return stars
    }
}

// MARK: - Skill Category
enum SkillCategory: String, Codable, CaseIterable, Identifiable {
    case all = "all"
    case productivity = "Productivity"
    case devTools = "Dev Tools"
    case fun = "Fun"
    case social = "Social"
    case utilities = "Utilities"
    case media = "Media"
    case automation = "Automation"
    case integration = "Integration"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All Skills"
        case .productivity: return "Productivity"
        case .devTools: return "Dev Tools"
        case .fun: return "Fun"
        case .social: return "Social"
        case .utilities: return "Utilities"
        case .media: return "Media"
        case .automation: return "Automation"
        case .integration: return "Integration"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .productivity: return "checkmark.circle"
        case .devTools: return "hammer"
        case .fun: return "party.popper"
        case .social: return "bubble.left.and.bubble.right"
        case .utilities: return "wrench.and.screwdriver"
        case .media: return "play.rectangle"
        case .automation: return "gearshape.2"
        case .integration: return "link"
        }
    }
}

// MARK: - Skill Review
struct SkillReview: Identifiable, Codable {
    let id: String
    let skillId: String
    let author: String
    let rating: Int
    let comment: String
    let createdAt: Date
    let helpful: Int
    
    enum CodingKeys: String, CodingKey {
        case id, author, rating, comment, helpful
        case skillId = "skill_id"
        case createdAt = "created_at"
    }
}

// MARK: - Installation Status
enum InstallationStatus: Equatable {
    case notInstalled
    case installing(progress: Double)
    case installed
    case updating(progress: Double)
    case failed(error: String)
    case uninstalling
    
    var isLoading: Bool {
        switch self {
        case .installing, .updating, .uninstalling:
            return true
        default:
            return false
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .notInstalled:
            return "Install"
        case .installing(let progress):
            return "Installing \(Int(progress * 100))%"
        case .installed:
            return "Installed"
        case .updating(let progress):
            return "Updating \(Int(progress * 100))%"
        case .failed:
            return "Retry"
        case .uninstalling:
            return "Uninstalling..."
        }
    }
}

// MARK: - Search Filter
struct SkillSearchFilter {
    var query: String = ""
    var category: SkillCategory = .all
    var sortBy: SortOption = .popular
    var showInstalledOnly: Bool = false
    var showUpdatesOnly: Bool = false
    
    enum SortOption: String, CaseIterable {
        case popular = "Most Popular"
        case newest = "Newest"
        case updated = "Recently Updated"
        case rating = "Highest Rated"
        case name = "Name (A-Z)"
    }
}
