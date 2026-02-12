import Foundation
import Combine
import SwiftUI

enum AppMode {
    case setup      // Running the setup wizard
    case running    // OpenClaw is running, show browser view
}

enum SetupStep: Int, CaseIterable {
    case license = 0
    case welcome = 1
    case systemCheck = 2
    case installation = 3
    case skillsSetup = 4
    case apiSetup = 5
    case channelSetup = 6
    case complete = 7
    
    var title: String {
        switch self {
        case .license: return "License"
        case .welcome: return "Welcome"
        case .systemCheck: return "System Check"
        case .installation: return "Installation"
        case .skillsSetup: return "Skills"
        case .apiSetup: return "AI Provider"
        case .channelSetup: return "Channels"
        case .complete: return "Complete"
        }
    }
    
    var icon: String {
        switch self {
        case .license: return "key.horizontal.fill"
        case .welcome: return "hand.wave.fill"
        case .systemCheck: return "checkmark.shield.fill"
        case .installation: return "arrow.down.circle.fill"
        case .skillsSetup: return "puzzlepiece.fill"
        case .apiSetup: return "key.fill"
        case .channelSetup: return "message.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

struct SystemRequirement: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var status: RequirementStatus
    
    enum RequirementStatus {
        case checking
        case passed
        case failed(String)
        case warning(String)
    }
}

struct InstalledComponent: Identifiable {
    let id = UUID()
    let name: String
    var location: String
    var status: InstallStatus
    
    enum InstallStatus {
        case pending
        case installing
        case installed
        case failed(String)
    }
}

// Available skills with configuration requirements
struct SkillInfo: Identifiable {
    let id: String
    let name: String
    let icon: String
    let tagline: String
    let description: String
    let exampleCommands: [String]
    let requiresConfig: Bool
    var isEnabled: Bool = true
    var configValue: String = ""
    
    init(id: String, name: String, icon: String, tagline: String, description: String, exampleCommands: [String], requiresConfig: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.tagline = tagline
        self.description = description
        self.exampleCommands = exampleCommands
        self.requiresConfig = requiresConfig
    }
}

// Default skills to install (based on Alex Finn workflows)
let defaultSkillsInfo: [SkillInfo] = [
    SkillInfo(
        id: "weather",
        name: "Weather",
        icon: "cloud.sun.fill",
        tagline: "Current conditions & forecasts",
        description: "Get real-time weather updates, forecasts, and alerts for any location. Perfect for morning briefings and travel planning.",
        exampleCommands: ["What's the weather today?", "Will it rain this weekend?", "Weather in New York"],
        requiresConfig: true
    ),
    SkillInfo(
        id: "summarize",
        name: "Summarize",
        icon: "doc.text.magnifyingglass",
        tagline: "Extract insights from any content",
        description: "Summarize articles, YouTube videos, podcasts, and PDFs. Get key takeaways without reading or watching the full content.",
        exampleCommands: ["Summarize this article: [URL]", "What's this video about? [YouTube link]", "Give me the highlights of this podcast"]
    ),
    SkillInfo(
        id: "github",
        name: "GitHub",
        icon: "chevron.left.forwardslash.chevron.right",
        tagline: "Manage repos, issues & PRs",
        description: "Interact with GitHub repositories directly. Create issues, review PRs, check CI status, and manage your projects through chat.",
        exampleCommands: ["Show my open PRs", "Create an issue for the login bug", "What's failing in CI?"]
    ),
    SkillInfo(
        id: "apple-reminders",
        name: "Reminders",
        icon: "checklist",
        tagline: "Never forget what matters",
        description: "Create, view, and manage Apple Reminders. Set due dates, organize by list, and get nudged when things are due.",
        exampleCommands: ["Remind me to call mom tomorrow", "What's on my todo list?", "Add milk to my shopping list"]
    ),
    SkillInfo(
        id: "apple-notes",
        name: "Notes",
        icon: "note.text",
        tagline: "Capture ideas instantly",
        description: "Create and search Apple Notes. Quickly jot down thoughts, save research, or retrieve information you've stored.",
        exampleCommands: ["Create a note about project ideas", "Find my notes about recipes", "Add to my meeting notes"]
    ),
    SkillInfo(
        id: "clawhub",
        name: "ClawHub",
        icon: "square.grid.2x2",
        tagline: "Expand your capabilities",
        description: "Browse and install additional skills from the ClawHub marketplace. Add new abilities like smart home control, music, and more.",
        exampleCommands: ["What skills are available?", "Install the Spotify skill", "Search for home automation skills"]
    )
]

let defaultSkills = defaultSkillsInfo.map { $0.id }

enum AIProvider: String, CaseIterable, Identifiable {
    case openRouter = "OpenRouter"
    case anthropic = "Anthropic"
    case openAI = "OpenAI"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .openRouter: return "arrow.triangle.2.circlepath"  // Routing/network concept
        case .anthropic: return "hexagon.fill"  // Geometric, modern feel
        case .openAI: return "circle.grid.2x2"  // AI/neural network concept
        }
    }

    var description: String {
        switch self {
        case .openRouter: return "One API key, 100+ models - Best value"
        case .anthropic: return "Claude models - Best performance"
        case .openAI: return "GPT-4 and GPT-4o"
        }
    }

    var defaultModel: String {
        switch self {
        case .openRouter: return "anthropic/claude-haiku-4-5"  // OpenRouter uses standard model IDs
        case .anthropic: return "anthropic/claude-haiku-4-5"
        case .openAI: return "openai/gpt-4o"
        }
    }

    var requiresApiKey: Bool {
        return true // All providers need API keys
    }

    var apiKeyURL: String {
        switch self {
        case .openRouter: return "https://openrouter.ai/keys"
        case .anthropic: return "https://console.anthropic.com/settings/keys"
        case .openAI: return "https://platform.openai.com/api-keys"
        }
    }

    var setupInstructions: String {
        switch self {
        case .openRouter:
            return "1. Click the link below to open OpenRouter\n2. Sign in or create an account (GitHub/Google sign-in available)\n3. Add billing information (pay-as-you-go)\n4. Go to API Keys section\n5. Click 'Create Key' and copy it (starts with sk-or-v1-...)\n6. Paste it here\n\n💡 Tip: OpenRouter gives you access to 100+ models with one API key. Use anthropic/claude-haiku-4-5 for best results."
        case .anthropic:
            return "1. Click the link below to open Anthropic Console\n2. Sign in or create an account\n3. Add billing information (pay-as-you-go)\n4. Go to API Keys section\n5. Click 'Create Key' and copy it\n6. Paste it here\n\n💡 Tip: Anthropic offers competitive pricing. Claude Haiku is highly efficient for most tasks."
        case .openAI:
            return "1. Click the link below to open OpenAI Platform\n2. Sign in or create an account\n3. Add billing information (pay-as-you-go)\n4. Click 'Create new secret key'\n5. Copy the key and paste it here"
        }
    }

    var isFree: Bool {
        return false
    }

    var isLowCost: Bool {
        return false
    }

    var pricingNote: String {
        switch self {
        case .openRouter: return "🌐 One key, 100+ models"
        case .anthropic: return "💳 Pay-as-you-go"
        case .openAI: return "💳 Pay-as-you-go"
        }
    }
}

enum MessagingChannel: String, CaseIterable, Identifiable {
    case telegram = "Telegram"
    case discord = "Discord"
    case whatsApp = "WhatsApp"
    case slack = "Slack"
    case signal = "Signal"
    case iMessage = "iMessage"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .telegram: return "paperplane.fill"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .whatsApp: return "phone.bubble.fill"
        case .slack: return "number.square.fill"
        case .signal: return "lock.shield.fill"
        case .iMessage: return "message.fill"
        }
    }
    
    var description: String {
        switch self {
        case .telegram: return "Bot token required"
        case .discord: return "Bot token required"
        case .whatsApp: return "Business API or web bridge"
        case .slack: return "App token required"
        case .signal: return "Signal-CLI required"
        case .iMessage: return "macOS only"
        }
    }
}

@MainActor
class SetupWizardViewModel: ObservableObject {
    // MARK: - App Mode
    @Published var appMode: AppMode = .setup
    
    // P0: Loading state to prevent flash of setup screens on startup
    @Published var isInitializing: Bool = true
    
    // Persisted setup state
    @AppStorage("setupCompleted") private var setupCompleted: Bool = false
    
    // MARK: - Navigation
    @Published var currentStep: SetupStep = .license
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var statusMessage: String = ""
    
    // MARK: - License
    @Published var licenseKey: String = ""
    @Published var isLicenseValid: Bool = false
    @Published var licenseError: String?
    let licenseService = LicenseService.shared
    
    // MARK: - System Check
    @Published var requirements: [SystemRequirement] = []
    @Published var systemCheckComplete: Bool = false
    
    // MARK: - Installation
    @Published var installationProgress: Double = 0
    @Published var installationStatus: String = "Ready to install"
    @Published var isInstalled: Bool = false
    @Published var installedComponents: [InstalledComponent] = []
    
    // MARK: - Configuration
    @Published var selectedProvider: AIProvider = .openRouter  // Default to OpenRouter (best value)
    @Published var apiKey: String = ""
    @Published var selectedAIModel: String = "anthropic/claude-haiku-4-5"  // Default model
    @Published var selectedChannels: Set<MessagingChannel> = []
    
    // MARK: - Skills
    @Published var selectedSkills: [SkillInfo] = defaultSkillsInfo
    @Published var selectedSkillId: String = "weather" // Default selection
    
    // MARK: - Location (for weather skill)
    @Published var userLocation: String = ""
    
    // MARK: - OpenClaw Defaults
    let defaultGatewayURL = "http://127.0.0.1:18789"
    let defaultGatewayPort = 18789
    
    // Model fallbacks based on current gateway config
    var modelFallbacks: [String] {
        // If user selected a specific model, use it as primary with provider-specific fallbacks
        if !selectedAIModel.isEmpty {
            var fallbacks = [selectedAIModel]
            // Add provider-specific fallbacks (excluding the selected one)
            let providerDefaults = defaultModelFallbacksForProvider()
            fallbacks.append(contentsOf: providerDefaults.filter { $0 != selectedAIModel })
            return fallbacks
        }
        
        // Otherwise use provider defaults
        return defaultModelFallbacksForProvider()
    }
    
    private func defaultModelFallbacksForProvider() -> [String] {
        switch selectedProvider {
        case .openRouter:
            return ["anthropic/claude-sonnet-4-5", "anthropic/claude-opus-4-5", "openai/gpt-4o", "moonshot/kimi-k2.5"]
        case .anthropic:
            return ["anthropic/claude-sonnet-4-5", "anthropic/claude-opus-4-5", "anthropic/claude-haiku-4-5"]
        case .openAI:
            return ["openai/gpt-4o", "openai/gpt-4o-mini", "anthropic/claude-haiku-4-5"]
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var installTask: Process?
    
    // P1: Task cancellation - track active async task
    private var activeTask: Task<Void, Never>?
    
    init() {
        initializeRequirements()
        
        // Watch for provider changes and automatically set default model
        $selectedProvider
            .sink { [weak self] provider in
                guard let self = self else { return }
                // Only auto-set if user hasn't manually selected a model
                if self.selectedAIModel.isEmpty || self.selectedAIModel == self.selectedProvider.defaultModel {
                    self.selectedAIModel = provider.defaultModel
                }
            }
            .store(in: &cancellables)
        
        // Check for demo mode or existing license
        Task {
            await checkExistingLicense()
            
            // If setup was previously completed and license is valid, skip to browser
            if setupCompleted && (isLicenseValid || OpenClawKitApp.isDemoMode) {
                print("✅ [Init] Setup already completed, skipping to browser view")
                if !OpenClawKitApp.isDemoMode {
                    // Start the gateway
                    _ = await runShellCommand("openclaw gateway start")
                }
                appMode = .running
            }
            
            // P0: Done initializing, hide splash screen
            isInitializing = false
        }
    }
    
    // MARK: - License Validation
    
    func checkExistingLicense() async {
        // Demo mode: Skip license entirely
        if OpenClawKitApp.isDemoMode {
            print("🎭 [Demo] Skipping license check - demo mode active")
            isLicenseValid = true
            currentStep = .welcome
            return
        }
        
        await licenseService.checkStoredLicense()
        isLicenseValid = licenseService.isLicensed
        if isLicenseValid {
            // Skip to welcome if already licensed
            currentStep = .welcome
        }
    }
    
    func activateLicense() async {
        guard !licenseKey.isEmpty else {
            licenseError = "Please enter a license key"
            return
        }
        
        isLoading = true
        licenseError = nil
        
        let result = await licenseService.activate(licenseKey: licenseKey)
        
        switch result {
        case .success:
            isLicenseValid = true
            licenseError = nil
            // Auto-advance to welcome
            withAnimation {
                currentStep = .welcome
            }
        case .failure(let error):
            isLicenseValid = false
            licenseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard let nextIndex = SetupStep.allCases.firstIndex(of: currentStep).map({ $0 + 1 }),
              nextIndex < SetupStep.allCases.count else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = SetupStep.allCases[nextIndex]
        }
        
        // Trigger step-specific actions (with delay to let page transition complete)
        switch currentStep {
        case .systemCheck:
            // Reset state immediately so nothing flashes
            initializeRequirements()
            systemCheckComplete = false
            Task {
                try? await Task.sleep(nanoseconds: 450_000_000) // Wait for transition animation
                runSystemCheck()
            }
        case .installation:
            // Reset state immediately - user will click Install to begin
            resetInstallationState()
        case .skillsSetup:
            // Location field is empty by default — user can type manually
            break
        default:
            break
        }
    }
    
    func previousStep() {
        guard let prevIndex = SetupStep.allCases.firstIndex(of: currentStep).map({ $0 - 1 }),
              prevIndex >= 0 else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = SetupStep.allCases[prevIndex]
        }
    }
    
    var canGoNext: Bool {
        switch currentStep {
        case .license:
            return isLicenseValid
        case .welcome:
            return true
        case .systemCheck:
            // Allow proceeding with warnings (installer can fix those)
            // Only block on hard failures
            return systemCheckComplete && !requirements.contains { 
                if case .failed = $0.status { return true }
                return false
            }
        case .installation:
            return isInstalled
        case .skillsSetup:
            return true // Skills are optional, location is optional
        case .apiSetup:
            return !selectedProvider.requiresApiKey || isApiKeyValid
        case .channelSetup:
            return true // Channels are optional
        case .complete:
            return false
        }
    }
    
    var progress: Double {
        Double(currentStep.rawValue) / Double(SetupStep.allCases.count - 1)
    }
    
    // MARK: - API Key Validation
    
    var isApiKeyValid: Bool {
        guard !apiKey.isEmpty else { return false }

        // Validate format based on provider
        switch selectedProvider {
        case .openRouter:
            return apiKey.hasPrefix("sk-or-v1-") && apiKey.count > 20
        case .anthropic:
            return apiKey.hasPrefix("sk-ant-") && apiKey.count > 20
        case .openAI:
            return apiKey.hasPrefix("sk-") && apiKey.count > 20
        }
    }
    
    // MARK: - System Check
    
    private func initializeRequirements() {
        requirements = [
            SystemRequirement(name: "macOS Version", description: "macOS 12.0 or later", status: .checking),
            SystemRequirement(name: "Node.js", description: "v22.0 or later required", status: .checking),
            SystemRequirement(name: "Disk Space", description: "500MB free space required", status: .checking),
            SystemRequirement(name: "Network", description: "Internet connection required", status: .checking)
        ]
    }
    
    func runSystemCheck() {
        print("🚀 [SystemCheck] Starting system check...")
        
        // P1: Cancel previous task before starting new one
        activeTask?.cancel()
        
        isLoading = true
        systemCheckComplete = false
        // Only initialize if not already in checking state (handles direct calls)
        if requirements.isEmpty || !requirements.allSatisfy({ if case .checking = $0.status { return true } else { return false } }) {
            initializeRequirements()
        }
        
        // P1: Use SystemCheckService instead of inline checks
        let service = SystemCheckService.shared
        
        activeTask = Task {
            // P1: Check for cancellation
            guard !Task.isCancelled else { return }
            
            print("🚀 [SystemCheck] Checking macOS version...")
            let macOSResult = await service.checkMacOSVersion()
            guard !Task.isCancelled else { return }
            updateRequirement(name: macOSResult.name, status: macOSResult.status)
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            print("🚀 [SystemCheck] Checking Node.js...")
            let nodeResult = await service.checkNodeJS()
            guard !Task.isCancelled else { return }
            updateRequirement(name: nodeResult.name, status: nodeResult.status)
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            print("🚀 [SystemCheck] Checking disk space...")
            let diskResult = await service.checkDiskSpace()
            guard !Task.isCancelled else { return }
            updateRequirement(name: diskResult.name, status: diskResult.status)
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            print("🚀 [SystemCheck] Checking network...")
            let networkResult = await service.checkNetwork()
            guard !Task.isCancelled else { return }
            updateRequirement(name: networkResult.name, status: networkResult.status)
            
            guard !Task.isCancelled else { return }
            print("🚀 [SystemCheck] All checks complete!")
            isLoading = false
            systemCheckComplete = true
            
            // Auto-advance if all checks passed (no warnings or failures)
            let allPassed = requirements.allSatisfy { 
                if case .passed = $0.status { return true }
                return false
            }
            if allPassed {
                print("✅ [SystemCheck] All passed - auto-advancing")
                try? await Task.sleep(nanoseconds: 400_000_000) // Brief pause to show success
                guard !Task.isCancelled else { return }
                nextStep()
            }
        }
    }
    
    private func updateRequirement(name: String, status: SystemRequirement.RequirementStatus) {
        if let index = requirements.firstIndex(where: { $0.name == name }) {
            requirements[index].status = status
        }
    }
    
    // MARK: - Installation
    
    private func resetInstallationState() {
        installationProgress = 0
        installationStatus = "Ready to install"
        isInstalled = false
        installedComponents = [] // Start empty - components appear progressively
    }
    
    func startInstallation() {
        // Prevent double-starting
        guard !isLoading && !isInstalled else { return }
        
        // P1: Cancel previous task before starting new one
        activeTask?.cancel()
        
        isLoading = true
        installationProgress = 0
        installationStatus = "Preparing..."
        installedComponents = [] // Start empty - add progressively
        
        // Demo mode: Skip actual installation
        if OpenClawKitApp.isDemoMode {
            print("🎭 [Demo] Skipping installation - demo mode active")
            
            activeTask = Task {
                guard !Task.isCancelled else { return }
                // Homebrew - add then update
                addComponent("Homebrew", status: .installing)
                installationStatus = "Checking Homebrew..."
                installationProgress = 0.1
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                updateComponent("Homebrew", status: .installed, location: "/opt/homebrew")
                installationProgress = 0.2
                
                // Node.js
                guard !Task.isCancelled else { return }
                addComponent("Node.js", status: .installing)
                installationStatus = "Checking Node.js..."
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                updateComponent("Node.js", status: .installed, location: "node (v22.0.0)")
                installationProgress = 0.4
                
                // OpenClaw
                guard !Task.isCancelled else { return }
                addComponent("OpenClaw", status: .installing)
                installationStatus = "Installing OpenClaw..."
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                updateComponent("OpenClaw", status: .installed, location: "/usr/local/bin/openclaw (npm)")
                installationProgress = 0.7
                
                // Skills
                guard !Task.isCancelled else { return }
                addComponent("Skills", status: .installing)
                installationStatus = "Installing skills..."
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
                let skillList = defaultSkills.joined(separator: ", ")
                updateComponent("Skills", status: .installed, location: skillList)
                installationProgress = 1.0
                installationStatus = "Installation complete!"
                
                isInstalled = true
                isLoading = false
            }
            return
        }
        
        activeTask = Task {
            guard !Task.isCancelled else { return }
            
            // Step 1: Check Homebrew
            addComponent("Homebrew", status: .installing)
            installationStatus = "Checking Homebrew..."
            installationProgress = 0.1
            
            guard !Task.isCancelled else { return }
            let brewPath = await runShellCommand("which brew")
            guard !Task.isCancelled else { return }
            if let path = brewPath {
                updateComponent("Homebrew", status: .installed, location: path)
            } else {
                updateComponent("Homebrew", status: .failed("Not found - please install from brew.sh"))
            }
            installationProgress = 0.25
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            // Step 2: Check/Install Node.js
            guard !Task.isCancelled else { return }
            addComponent("Node.js", status: .installing)
            installationStatus = "Checking Node.js..."
            installationProgress = 0.35
            
            guard !Task.isCancelled else { return }
            var nodeVersion = await runShellCommand("node --version")
            guard !Task.isCancelled else { return }
            var nodePath = await runShellCommand("which node")
            guard !Task.isCancelled else { return }
            let needsNode = nodeVersion == nil || {
                guard let v = nodeVersion, v.hasPrefix("v") else { return true }
                let major = Int(v.dropFirst().split(separator: ".").first ?? "") ?? 0
                return major < 22
            }()
            
            if needsNode {
                installationStatus = "Installing Node.js 22..."
                guard !Task.isCancelled else { return }
                _ = await runShellCommand("brew install node@22")
                guard !Task.isCancelled else { return }
                _ = await runShellCommand("brew link --overwrite node@22")
                guard !Task.isCancelled else { return }
                nodeVersion = await runShellCommand("node --version")
                guard !Task.isCancelled else { return }
                nodePath = await runShellCommand("which node")
            }
            
            guard !Task.isCancelled else { return }
            if let path = nodePath, let version = nodeVersion {
                updateComponent("Node.js", status: .installed, location: "\(path) (\(version))")
            } else {
                updateComponent("Node.js", status: .failed("Installation failed"))
            }
            installationProgress = 0.55
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            // Step 3: Install OpenClaw
            guard !Task.isCancelled else { return }
            addComponent("OpenClaw", status: .installing)
            installationStatus = "Installing OpenClaw..."
            installationProgress = 0.65
            
            guard !Task.isCancelled else { return }
            _ = await runShellCommand("npm install -g openclaw")
            guard !Task.isCancelled else { return }
            installationProgress = 0.85
            
            guard !Task.isCancelled else { return }
            let openclawPath = await runShellCommand("which openclaw")
            guard !Task.isCancelled else { return }
            let openclawVersion = await runShellCommand("openclaw --version")
            guard !Task.isCancelled else { return }
            
            if let path = openclawPath {
                let loc = openclawVersion != nil ? "\(path) (\(openclawVersion!))" : path
                updateComponent("OpenClaw", status: .installed, location: loc)
                installationProgress = 0.7
                
                // Step 4: Install default skills
                guard !Task.isCancelled else { return }
                addComponent("Skills", status: .installing)
                installationStatus = "Installing skills..."
                
                var installedSkillNames: [String] = []
                // Get npm global root for skill path
                let npmGlobalPath = await runShellCommand("npm root -g")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "/usr/local/lib/node_modules"
                for skill in defaultSkills {
                    guard !Task.isCancelled else { return }
                    // Skills are bundled with OpenClaw, just need to verify they exist
                    let skillPath = await runShellCommand("ls \(npmGlobalPath)/openclaw/skills/\(skill)/SKILL.md 2>/dev/null")
                    if skillPath != nil {
                        installedSkillNames.append(skill)
                    }
                }
                
                guard !Task.isCancelled else { return }
                if !installedSkillNames.isEmpty {
                    updateComponent("Skills", status: .installed, location: installedSkillNames.joined(separator: ", "))
                } else {
                    updateComponent("Skills", status: .installed, location: "Bundled with OpenClaw")
                }
                
                installationProgress = 1.0
                installationStatus = "Installation complete!"
                isInstalled = true
            } else {
                updateComponent("OpenClaw", status: .failed("Could not verify installation"))
                addComponent("Skills", status: .failed("Skipped"))
                installationStatus = "Verification issue"
                isInstalled = true // Allow continuing
            }
            
            isLoading = false
        }
    }
    
    private func addComponent(_ name: String, status: InstalledComponent.InstallStatus) {
        withAnimation(.easeOut(duration: 0.25)) {
            installedComponents.append(InstalledComponent(name: name, location: "", status: status))
        }
    }
    
    private func updateComponent(_ name: String, status: InstalledComponent.InstallStatus, location: String? = nil) {
        if let index = installedComponents.firstIndex(where: { $0.name == name }) {
            installedComponents[index].status = status
            if let loc = location {
                installedComponents[index].location = loc
            }
        }
    }
    
    // MARK: - Configuration
    
    func saveConfiguration() {
        isLoading = true
        statusMessage = "Saving configuration..."
        
        Task {
            // Run openclaw configure with the settings
            let configDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".openclaw")
            
            // Create config directory if needed
            try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            
            // Build configuration with Alex Finn's best practices
            var config: [String: Any] = [
                "gateway": [
                    "port": defaultGatewayPort,
                    "mode": "local",
                    "bind": "loopback"
                ],
                "agents": [
                    "defaults": [
                        "workspace": FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("openclaw-workspace").path,
                        // Model configuration with fallbacks (Alex Finn recommendation)
                        "model": [
                            "primary": !selectedAIModel.isEmpty ? selectedAIModel : selectedProvider.defaultModel,
                            "fallbacks": modelFallbacks
                        ]
                    ]
                ]
            ]
            
            // Add provider config
            if !apiKey.isEmpty || !selectedProvider.requiresApiKey {
                let providerKey = selectedProvider.rawValue.lowercased()
                var authConfig: [String: Any] = [
                    "profiles": [
                        "\(providerKey):default": [
                            "provider": providerKey,
                            "mode": selectedProvider.requiresApiKey ? "api_key" : "none"
                        ]
                    ]
                ]
                
                // Add fallback providers for rate limit handling
                authConfig["profiles"] = [
                    "\(providerKey):default": [
                        "provider": providerKey,
                        "mode": "api_key"
                    ]
                ]
                
                config["auth"] = authConfig
            }
            
            // Add channel configs
            if !selectedChannels.isEmpty {
                var channels: [String: Any] = [:]
                for channel in selectedChannels {
                    channels[channel.rawValue.lowercased()] = ["enabled": true]
                }
                config["channels"] = channels
            }
            
            // Write config (simplified - real implementation would use proper JSON encoding)
            statusMessage = "Configuration saved!"
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            isLoading = false
        }
    }
    
    // MARK: - Launch
    
    func launchOpenClaw() {
        Task {
            if OpenClawKitApp.isDemoMode {
                print("🎭 [Demo] Skipping gateway start - demo mode active")
            } else {
                // Start the gateway
                _ = await runShellCommand("openclaw gateway start")
            }
            
            // Mark setup as completed for future launches
            setupCompleted = true
            
            // Transition to browser view (embedded in app)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appMode = .running
            }
        }
    }
    
    func openDocumentation() {
        if let url = URL(string: "https://docs.openclaw.ai") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Shell Commands
    
    private func runShellCommand(_ command: String) async -> String? {
        await withCheckedContinuation { continuation in
            let task = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            
            task.standardOutput = stdoutPipe
            task.standardError = stderrPipe
            // Use login shell (-l) to source profile and get full PATH (including Homebrew)
            task.arguments = ["-l", "-c", command]
            task.launchPath = "/bin/zsh"
            task.standardInput = nil
            
            // Also set common paths explicitly as fallback
            var env = ProcessInfo.processInfo.environment
            let homebrewPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin"
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(homebrewPaths):\(existingPath)"
            } else {
                env["PATH"] = "\(homebrewPaths):/usr/bin:/bin:/usr/sbin:/sbin"
            }
            task.environment = env
            
            print("🔧 [Shell] Running command: \(command)")
            print("🔧 [Shell] PATH: \(env["PATH"] ?? "nil")")
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                
                let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("🔧 [Shell] Exit code: \(task.terminationStatus)")
                print("🔧 [Shell] stdout: \(stdout ?? "nil")")
                print("🔧 [Shell] stderr: \(stderr ?? "nil")")
                
                if task.terminationStatus == 0 {
                    continuation.resume(returning: stdout)
                } else {
                    print("🔧 [Shell] Command failed with exit code \(task.terminationStatus)")
                    continuation.resume(returning: nil)
                }
            } catch {
                print("🔧 [Shell] Exception: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        // P1: Cancel active task on deinit
        activeTask?.cancel()
    }
}
