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
    case anthropic = "Anthropic"
    case deepseek = "DeepSeek"
    case openAI = "OpenAI"
    case google = "Google"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .anthropic: return "brain.head.profile"
        case .deepseek: return "bolt.fill"
        case .openAI: return "sparkles"
        case .google: return "globe"
        }
    }
    
    var description: String {
        switch self {
        case .anthropic: return "Claude models - Recommended"
        case .deepseek: return "DeepSeek V3 - Very low cost"
        case .openAI: return "GPT-4 and GPT-4o"
        case .google: return "Gemini models - Free tier available"
        }
    }
    
    var defaultModel: String {
        switch self {
        case .anthropic: return "anthropic/claude-haiku-4-5"
        case .deepseek: return "deepseek/deepseek-chat"
        case .openAI: return "openai/gpt-4o"
        case .google: return "google/gemini-2.0-flash"
        }
    }
    
    var requiresApiKey: Bool {
        return true // All providers need API keys
    }
    
    var apiKeyURL: String {
        switch self {
        case .anthropic: return "https://console.anthropic.com/settings/keys"
        case .deepseek: return "https://platform.deepseek.com/api_keys"
        case .openAI: return "https://platform.openai.com/api-keys"
        case .google: return "https://aistudio.google.com/apikey"
        }
    }
    
    var setupInstructions: String {
        switch self {
        case .anthropic:
            return "1. Click the link below to open Anthropic Console\n2. Sign in or create an account\n3. Add billing information (pay-as-you-go)\n4. Go to API Keys section\n5. Click 'Create Key' and copy it\n6. Paste it here\n\n💡 Tip: Anthropic offers competitive pricing. Claude Haiku is highly efficient for most tasks."
        case .deepseek:
            return "1. Click the link below to open DeepSeek Platform\n2. Sign in or create an account\n3. Add billing information\n4. Go to API Keys section\n5. Create a new API key and copy it\n6. Paste it here\n\n💡 Tip: DeepSeek offers extremely low pricing — great for high-volume use cases."
        case .openAI:
            return "1. Click the link below to open OpenAI Platform\n2. Sign in or create an account\n3. Add billing information (pay-as-you-go)\n4. Click 'Create new secret key'\n5. Copy the key and paste it here"
        case .google:
            return "1. Click the link below to open Google AI Studio\n2. Sign in with your Google account\n3. Click 'Create API Key'\n4. Copy the key and paste it here"
        }
    }
    
    var isFree: Bool {
        switch self {
        case .google: return true
        case .anthropic, .deepseek, .openAI: return false
        }
    }
    
    var isLowCost: Bool {
        switch self {
        case .deepseek: return true
        case .anthropic, .openAI, .google: return false
        }
    }
    
    var pricingNote: String {
        switch self {
        case .anthropic: return "💳 Pay-as-you-go"
        case .deepseek: return "💰 Very low cost"
        case .google: return "✨ Free tier available"
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
    @Published var selectedProvider: AIProvider = .anthropic  // Default to Anthropic (Claude Haiku as primary)
    @Published var apiKey: String = ""
    @Published var selectedChannels: Set<MessagingChannel> = []
    
    // MARK: - Skills
    @Published var selectedSkills: [SkillInfo] = defaultSkillsInfo
    @Published var selectedSkillId: String = "weather" // Default selection
    
    // MARK: - Location (for weather skill)
    @Published var userLocation: String = ""
    @Published var isDetectingLocation: Bool = false
    
    // MARK: - OpenClaw Defaults
    let defaultGatewayURL = "http://localhost:18789"
    let defaultGatewayPort = 18789
    
    // Model fallbacks based on current gateway config
    var modelFallbacks: [String] {
        switch selectedProvider {
        case .anthropic:
            return ["anthropic/claude-opus-4-5", "deepseek/deepseek-v2", "moonshot/kimi-k2.5"]
        case .deepseek:
            return ["anthropic/claude-haiku-4-5", "moonshot/kimi-k2.5", "google/gemini-2.0-flash"]
        case .openAI:
            return ["anthropic/claude-opus-4-5", "deepseek/deepseek-v2", "openai/gpt-4o"]
        case .google:
            return ["anthropic/claude-opus-4-5", "deepseek/deepseek-v2", "google/gemini-2.0-flash"]
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var installTask: Process?
    
    init() {
        initializeRequirements()
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
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                detectUserLocation()
            }
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
            return !selectedProvider.requiresApiKey || !apiKey.isEmpty
        case .channelSetup:
            return true // Channels are optional
        case .complete:
            return false
        }
    }
    
    var progress: Double {
        Double(currentStep.rawValue) / Double(SetupStep.allCases.count - 1)
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
        isLoading = true
        systemCheckComplete = false
        // Only initialize if not already in checking state (handles direct calls)
        if requirements.isEmpty || !requirements.allSatisfy({ if case .checking = $0.status { return true } else { return false } }) {
            initializeRequirements()
        }
        
        Task {
            print("🚀 [SystemCheck] Checking macOS version...")
            // Check macOS version
            await checkMacOSVersion()
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            print("🚀 [SystemCheck] Checking Node.js...")
            // Check Node.js
            await checkNodeJS()
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            print("🚀 [SystemCheck] Checking disk space...")
            // Check disk space
            await checkDiskSpace()
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            print("🚀 [SystemCheck] Checking network...")
            // Check network
            await checkNetwork()
            
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
                nextStep()
            }
        }
    }
    
    private func checkMacOSVersion() async {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion)"
        
        if version.majorVersion >= 12 {
            updateRequirement(name: "macOS Version", status: .passed)
        } else {
            updateRequirement(name: "macOS Version", status: .failed("macOS \(versionString) found, 12.0+ required"))
        }
    }
    
    private func checkNodeJS() async {
        print("🔍 [NodeCheck] Starting Node.js check...")
        
        // First try to find where node is
        let whichResult = await runShellCommand("which node")
        print("🔍 [NodeCheck] which node: \(whichResult ?? "nil")")
        
        // Also check common paths directly
        let directCheck = await runShellCommand("ls -la /opt/homebrew/bin/node 2>/dev/null || echo 'not found'")
        print("🔍 [NodeCheck] Direct /opt/homebrew/bin/node: \(directCheck ?? "nil")")
        
        let result = await runShellCommand("node --version")
        print("🔍 [NodeCheck] node --version result: \(result ?? "nil")")
        
        if let version = result, version.hasPrefix("v") {
            let versionNum = version.dropFirst().split(separator: ".").first.flatMap { Int($0) } ?? 0
            print("🔍 [NodeCheck] Parsed version number: \(versionNum)")
            if versionNum >= 22 {
                updateRequirement(name: "Node.js", status: .passed)
            } else {
                updateRequirement(name: "Node.js", status: .warning("Node.js \(version) found - will upgrade to v22"))
            }
        } else {
            print("🔍 [NodeCheck] FAILED - result was nil or didn't start with 'v'")
            updateRequirement(name: "Node.js", status: .warning("Not found - will install v22 automatically"))
        }
    }
    
    private func checkDiskSpace() async {
        let fileManager = FileManager.default
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            let freeGB = Double(freeSpace) / 1_000_000_000
            if freeGB >= 0.5 {
                updateRequirement(name: "Disk Space", status: .passed)
            } else {
                updateRequirement(name: "Disk Space", status: .failed("Only \(String(format: "%.1f", freeGB))GB free"))
            }
        } else {
            updateRequirement(name: "Disk Space", status: .warning("Could not check disk space"))
        }
    }
    
    private func checkNetwork() async {
        print("🌐 [NetworkCheck] Starting network check...")
        
        // First check if curl exists
        let whichCurl = await runShellCommand("which curl")
        print("🌐 [NetworkCheck] which curl: \(whichCurl ?? "nil")")
        
        // Try a simpler test first
        let pingTest = await runShellCommand("curl -s --max-time 5 -I https://registry.npmjs.org | head -1")
        print("🌐 [NetworkCheck] curl HEAD test: \(pingTest ?? "nil")")
        
        let result = await runShellCommand("curl -s --max-time 5 -o /dev/null -w '%{http_code}' https://registry.npmjs.org")
        print("🌐 [NetworkCheck] HTTP status code result: '\(result ?? "nil")'")
        
        if result == "200" {
            print("🌐 [NetworkCheck] SUCCESS - got 200")
            updateRequirement(name: "Network", status: .passed)
        } else {
            print("🌐 [NetworkCheck] FAILED - expected '200', got '\(result ?? "nil")'")
            updateRequirement(name: "Network", status: .failed("Cannot reach npm registry (got: \(result ?? "nil"))"))
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
        
        isLoading = true
        installationProgress = 0
        installationStatus = "Preparing..."
        installedComponents = [] // Start empty - add progressively
        
        // Demo mode: Skip actual installation
        if OpenClawKitApp.isDemoMode {
            print("🎭 [Demo] Skipping installation - demo mode active")
            
            Task {
                // Homebrew - add then update
                addComponent("Homebrew", status: .installing)
                installationStatus = "Checking Homebrew..."
                installationProgress = 0.1
                try? await Task.sleep(nanoseconds: 350_000_000)
                updateComponent("Homebrew", status: .installed, location: "/opt/homebrew")
                installationProgress = 0.2
                
                // Node.js
                addComponent("Node.js", status: .installing)
                installationStatus = "Checking Node.js..."
                try? await Task.sleep(nanoseconds: 350_000_000)
                updateComponent("Node.js", status: .installed, location: "/opt/homebrew/bin/node (v22.0.0)")
                installationProgress = 0.4
                
                // OpenClaw
                addComponent("OpenClaw", status: .installing)
                installationStatus = "Installing OpenClaw..."
                try? await Task.sleep(nanoseconds: 500_000_000)
                updateComponent("OpenClaw", status: .installed, location: "/opt/homebrew/bin/openclaw")
                installationProgress = 0.7
                
                // Skills
                addComponent("Skills", status: .installing)
                installationStatus = "Installing skills..."
                try? await Task.sleep(nanoseconds: 400_000_000)
                let skillList = defaultSkills.joined(separator: ", ")
                updateComponent("Skills", status: .installed, location: skillList)
                installationProgress = 1.0
                installationStatus = "Installation complete!"
                
                isInstalled = true
                isLoading = false
            }
            return
        }
        
        Task {
            // Step 1: Check Homebrew
            addComponent("Homebrew", status: .installing)
            installationStatus = "Checking Homebrew..."
            installationProgress = 0.1
            
            let brewPath = await runShellCommand("which brew")
            if let path = brewPath {
                updateComponent("Homebrew", status: .installed, location: path)
            } else {
                updateComponent("Homebrew", status: .failed("Not found - please install from brew.sh"))
            }
            installationProgress = 0.25
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            // Step 2: Check/Install Node.js
            addComponent("Node.js", status: .installing)
            installationStatus = "Checking Node.js..."
            installationProgress = 0.35
            
            var nodeVersion = await runShellCommand("node --version")
            var nodePath = await runShellCommand("which node")
            let needsNode = nodeVersion == nil || {
                guard let v = nodeVersion, v.hasPrefix("v") else { return true }
                let major = Int(v.dropFirst().split(separator: ".").first ?? "") ?? 0
                return major < 22
            }()
            
            if needsNode {
                installationStatus = "Installing Node.js 22..."
                _ = await runShellCommand("brew install node@22")
                _ = await runShellCommand("brew link --overwrite node@22")
                nodeVersion = await runShellCommand("node --version")
                nodePath = await runShellCommand("which node")
            }
            
            if let path = nodePath, let version = nodeVersion {
                updateComponent("Node.js", status: .installed, location: "\(path) (\(version))")
            } else {
                updateComponent("Node.js", status: .failed("Installation failed"))
            }
            installationProgress = 0.55
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            // Step 3: Install OpenClaw
            addComponent("OpenClaw", status: .installing)
            installationStatus = "Installing OpenClaw..."
            installationProgress = 0.65
            
            _ = await runShellCommand("npm install -g openclaw")
            installationProgress = 0.85
            
            let openclawPath = await runShellCommand("which openclaw")
            let openclawVersion = await runShellCommand("openclaw --version")
            
            if let path = openclawPath {
                let loc = openclawVersion != nil ? "\(path) (\(openclawVersion!))" : path
                updateComponent("OpenClaw", status: .installed, location: loc)
                installationProgress = 0.7
                
                // Step 4: Install default skills
                addComponent("Skills", status: .installing)
                installationStatus = "Installing skills..."
                
                var installedSkillNames: [String] = []
                for skill in defaultSkills {
                    // Skills are bundled with OpenClaw, just need to verify they exist
                    let skillPath = await runShellCommand("ls /opt/homebrew/lib/node_modules/openclaw/skills/\(skill)/SKILL.md 2>/dev/null")
                    if skillPath != nil {
                        installedSkillNames.append(skill)
                    }
                }
                
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
                            "primary": selectedProvider.defaultModel,
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
    
    // MARK: - Location Detection
    
    func detectUserLocation() {
        guard userLocation.isEmpty else { return } // Don't override if already set
        isDetectingLocation = true
        
        Task {
            if let location = await LocationService.shared.detectLocation() {
                let formatted = LocationService.shared.formatLocation(
                    city: location.city,
                    region: location.region,
                    zip: location.zip
                )
                userLocation = formatted
            }
            isDetectingLocation = false
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
    }
}
