import Foundation
import Combine

// MARK: - ClawHub API Client
class ClawHubAPIClient: ObservableObject {
    static let shared = ClawHubAPIClient()
    
    private let baseURL = "https://clawhub.com/api/v1"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Fetch all available skills
    func fetchSkills() async throws -> [Skill] {
        // For now, return mock data until ClawHub API is available
        // TODO: Replace with actual API call when backend is ready
        return try await fetchMockSkills()
    }
    
    /// Search skills with filters
    func searchSkills(query: String, category: SkillCategory, sortBy: SkillSearchFilter.SortOption) async throws -> [Skill] {
        var skills = try await fetchSkills()
        
        // Filter by category
        if category != .all {
            skills = skills.filter { $0.category == category }
        }
        
        // Filter by search query
        if !query.isEmpty {
            skills = skills.filter { skill in
                skill.name.localizedCaseInsensitiveContains(query) ||
                skill.description.localizedCaseInsensitiveContains(query) ||
                skill.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
        }
        
        // Sort
        switch sortBy {
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
        
        return skills
    }
    
    /// Get skill details
    func fetchSkillDetails(id: String) async throws -> Skill {
        let skills = try await fetchSkills()
        guard let skill = skills.first(where: { $0.id == id }) else {
            throw ClawHubError.skillNotFound
        }
        return skill
    }
    
    /// Fetch reviews for a skill
    func fetchReviews(for skillId: String) async throws -> [SkillReview] {
        // Mock reviews for now
        return [
            SkillReview(
                id: "review-1",
                skillId: skillId,
                author: "john_dev",
                rating: 5,
                comment: "Absolutely essential! This skill has saved me hours of work.",
                createdAt: Date().addingTimeInterval(-86400 * 7),
                helpful: 42
            ),
            SkillReview(
                id: "review-2",
                skillId: skillId,
                author: "sarah_pm",
                rating: 4,
                comment: "Great functionality, but could use better documentation.",
                createdAt: Date().addingTimeInterval(-86400 * 14),
                helpful: 18
            ),
            SkillReview(
                id: "review-3",
                skillId: skillId,
                author: "mike_designer",
                rating: 5,
                comment: "Works perfectly out of the box. Highly recommended!",
                createdAt: Date().addingTimeInterval(-86400 * 21),
                helpful: 31
            )
        ]
    }
    
    /// Install a skill
    func installSkill(id: String, progressHandler: @escaping (Double) -> Void) async throws {
        // Simulate installation progress
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            progressHandler(Double(i) / 10.0)
        }
        
        // TODO: Actual installation via `openclaw skills install <id>`
        // This will call: exec("openclaw", ["skills", "install", id])
    }
    
    /// Update a skill
    func updateSkill(id: String, progressHandler: @escaping (Double) -> Void) async throws {
        // Simulate update progress
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            progressHandler(Double(i) / 10.0)
        }
        
        // TODO: Actual update via `openclaw skills update <id>`
    }
    
    /// Uninstall a skill
    func uninstallSkill(id: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // TODO: Actual uninstall via `openclaw skills uninstall <id>`
    }
    
    /// Check for updates
    func checkForUpdates() async throws -> [Skill] {
        let skills = try await fetchSkills()
        return skills.filter { $0.hasUpdate }
    }
    
    /// Get installed skills
    func getInstalledSkills() async throws -> [Skill] {
        let skills = try await fetchSkills()
        return skills.filter { $0.isInstalled }
    }
    
    // MARK: - Private Methods
    
    private func fetchMockSkills() async throws -> [Skill] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return [
            Skill(
                id: "twitter-real",
                name: "Twitter/X",
                description: "Post tweets, read timeline, manage mentions, search, and interact with Twitter/X via the official API. Full authentication support with API keys.",
                shortDescription: "Official Twitter/X integration with full API support",
                author: "OpenClaw Team",
                version: "1.0.1",
                category: .social,
                icon: "bird",
                rating: 4.8,
                reviewCount: 234,
                downloads: 12453,
                repository: "https://github.com/openclaw/twitter-skill",
                homepage: "https://clawhub.com/skills/twitter-real",
                screenshots: [
                    "twitter-1.png",
                    "twitter-2.png"
                ],
                installationInstructions: "Requires Twitter API credentials. Set TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, and TWITTER_ACCESS_TOKEN_SECRET environment variables.",
                tags: ["social", "twitter", "x", "api"],
                dependencies: [],
                isInstalled: true,
                installedVersion: "1.0.1",
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400 * 5)
            ),
            Skill(
                id: "github",
                name: "GitHub CLI",
                description: "Interact with GitHub repositories, issues, pull requests, and CI/CD workflows using the official GitHub CLI. Create issues, review PRs, and manage projects.",
                shortDescription: "GitHub integration via official CLI",
                author: "OpenClaw Team",
                version: "2.1.0",
                category: .devTools,
                icon: "chevron.left.forwardslash.chevron.right",
                rating: 4.9,
                reviewCount: 567,
                downloads: 45678,
                repository: "https://github.com/openclaw/github-skill",
                homepage: "https://clawhub.com/skills/github",
                screenshots: [],
                installationInstructions: "Requires GitHub CLI (gh) to be installed. Run: brew install gh",
                tags: ["github", "git", "development", "ci/cd"],
                dependencies: ["gh"],
                isInstalled: true,
                installedVersion: "2.0.5",
                hasUpdate: true,
                publishedAt: Date().addingTimeInterval(-86400 * 90),
                updatedAt: Date().addingTimeInterval(-86400 * 2)
            ),
            Skill(
                id: "apple-notes",
                name: "Apple Notes",
                description: "Create, read, edit, and search Apple Notes directly from OpenClaw. Full integration with the native Notes app on macOS.",
                shortDescription: "Native Apple Notes integration",
                author: "OpenClaw Team",
                version: "1.2.0",
                category: .productivity,
                icon: "note.text",
                rating: 4.7,
                reviewCount: 189,
                downloads: 8942,
                repository: "https://github.com/openclaw/apple-notes-skill",
                homepage: "https://clawhub.com/skills/apple-notes",
                screenshots: [],
                installationInstructions: "Requires memo CLI: brew install memo",
                tags: ["notes", "apple", "productivity", "macos"],
                dependencies: ["memo"],
                isInstalled: true,
                installedVersion: "1.2.0",
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 60),
                updatedAt: Date().addingTimeInterval(-86400 * 10)
            ),
            Skill(
                id: "spotify",
                name: "Spotify Control",
                description: "Control Spotify playback, search tracks, create playlists, and get recommendations. Full integration with Spotify API.",
                shortDescription: "Control Spotify from OpenClaw",
                author: "Community",
                version: "1.5.2",
                category: .media,
                icon: "music.note",
                rating: 4.6,
                reviewCount: 423,
                downloads: 15234,
                repository: "https://github.com/community/spotify-skill",
                homepage: "https://clawhub.com/skills/spotify",
                screenshots: [],
                installationInstructions: "Requires Spotify API credentials. Register at https://developer.spotify.com",
                tags: ["spotify", "music", "media", "playback"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 120),
                updatedAt: Date().addingTimeInterval(-86400 * 15)
            ),
            Skill(
                id: "slack",
                name: "Slack Integration",
                description: "Send messages, read channels, manage workspace, and automate workflows in Slack. Perfect for team collaboration.",
                shortDescription: "Full Slack workspace integration",
                author: "Community",
                version: "2.0.0",
                category: .social,
                icon: "message",
                rating: 4.5,
                reviewCount: 312,
                downloads: 9876,
                repository: "https://github.com/community/slack-skill",
                homepage: "https://clawhub.com/skills/slack",
                screenshots: [],
                installationInstructions: "Requires Slack API token. Create one at https://api.slack.com/apps",
                tags: ["slack", "team", "communication", "automation"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 180),
                updatedAt: Date().addingTimeInterval(-86400 * 30)
            ),
            Skill(
                id: "home-assistant",
                name: "Home Assistant",
                description: "Control your smart home devices through Home Assistant. Turn on lights, adjust thermostats, and automate your home.",
                shortDescription: "Smart home control via Home Assistant",
                author: "Community",
                version: "1.0.0",
                category: .utilities,
                icon: "house",
                rating: 4.8,
                reviewCount: 156,
                downloads: 5432,
                repository: "https://github.com/community/home-assistant-skill",
                homepage: "https://clawhub.com/skills/home-assistant",
                screenshots: [],
                installationInstructions: "Requires Home Assistant instance and API token.",
                tags: ["smart-home", "automation", "iot", "home-assistant"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 45),
                updatedAt: Date().addingTimeInterval(-86400 * 8)
            ),
            Skill(
                id: "figma",
                name: "Figma API",
                description: "Access Figma files, export designs, and manage team projects. Perfect for designers and developers.",
                shortDescription: "Figma design file integration",
                author: "Community",
                version: "1.3.0",
                category: .devTools,
                icon: "paintbrush",
                rating: 4.4,
                reviewCount: 89,
                downloads: 3421,
                repository: "https://github.com/community/figma-skill",
                homepage: "https://clawhub.com/skills/figma",
                screenshots: [],
                installationInstructions: "Requires Figma API token. Get one from your Figma account settings.",
                tags: ["figma", "design", "ui", "ux"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 75),
                updatedAt: Date().addingTimeInterval(-86400 * 20)
            ),
            Skill(
                id: "weather",
                name: "Weather Forecast",
                description: "Get current weather conditions and forecasts for any location. Supports multiple weather providers.",
                shortDescription: "Weather forecasts and conditions",
                author: "OpenClaw Team",
                version: "1.1.0",
                category: .utilities,
                icon: "cloud.sun",
                rating: 4.3,
                reviewCount: 234,
                downloads: 8765,
                repository: "https://github.com/openclaw/weather-skill",
                homepage: "https://clawhub.com/skills/weather",
                screenshots: [],
                installationInstructions: "No setup required. Optionally set WEATHER_API_KEY for enhanced features.",
                tags: ["weather", "forecast", "utility"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 150),
                updatedAt: Date().addingTimeInterval(-86400 * 40)
            ),
            Skill(
                id: "notion",
                name: "Notion Integration",
                description: "Create pages, update databases, and search your Notion workspace. Full API integration.",
                shortDescription: "Notion workspace integration",
                author: "Community",
                version: "2.2.0",
                category: .productivity,
                icon: "doc.text",
                rating: 4.7,
                reviewCount: 445,
                downloads: 12098,
                repository: "https://github.com/community/notion-skill",
                homepage: "https://clawhub.com/skills/notion",
                screenshots: [],
                installationInstructions: "Requires Notion API token. Create an integration at https://notion.so/my-integrations",
                tags: ["notion", "notes", "productivity", "database"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 200),
                updatedAt: Date().addingTimeInterval(-86400 * 12)
            ),
            Skill(
                id: "meme-generator",
                name: "Meme Generator",
                description: "Create hilarious memes on demand. Choose from popular templates or create custom ones.",
                shortDescription: "Generate memes with AI",
                author: "Community",
                version: "1.0.3",
                category: .fun,
                icon: "face.smiling",
                rating: 4.9,
                reviewCount: 678,
                downloads: 23456,
                repository: "https://github.com/community/meme-skill",
                homepage: "https://clawhub.com/skills/meme-generator",
                screenshots: [],
                installationInstructions: "No setup required. Just ask for a meme!",
                tags: ["fun", "memes", "images", "humor"],
                dependencies: [],
                isInstalled: false,
                installedVersion: nil,
                hasUpdate: false,
                publishedAt: Date().addingTimeInterval(-86400 * 90),
                updatedAt: Date().addingTimeInterval(-86400 * 18)
            )
        ]
    }
}

// MARK: - Errors
enum ClawHubError: LocalizedError {
    case skillNotFound
    case networkError
    case installationFailed(String)
    case updateFailed(String)
    case uninstallFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .skillNotFound:
            return "Skill not found"
        case .networkError:
            return "Network error. Please check your connection."
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .uninstallFailed(let message):
            return "Uninstall failed: \(message)"
        }
    }
}
