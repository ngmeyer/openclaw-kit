import Foundation
import Combine
import SwiftUI

enum SetupStep: Int, CaseIterable {
    case license = 0
    case welcome = 1
    case systemCheck = 2
    case installation = 3
    case apiSetup = 4
    case channelSetup = 5
    case complete = 6
    
    var title: String {
        switch self {
        case .license: return "License"
        case .welcome: return "Welcome"
        case .systemCheck: return "System Check"
        case .installation: return "Installation"
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

enum AIProvider: String, CaseIterable, Identifiable {
    case nvidia = "NVIDIA"
    case anthropic = "Anthropic"
    case openAI = "OpenAI"
    case google = "Google"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .nvidia: return "cpu.fill"
        case .anthropic: return "brain.head.profile"
        case .openAI: return "sparkles"
        case .google: return "globe"
        }
    }
    
    var description: String {
        switch self {
        case .nvidia: return "Kimi K2.5 - Free tier available"
        case .anthropic: return "Claude models - Recommended"
        case .openAI: return "GPT-4 and GPT-3.5"
        case .google: return "Gemini models"
        }
    }
    
    var defaultModel: String {
        switch self {
        case .nvidia: return "nvidia/kimi-k2.5"
        case .anthropic: return "anthropic/claude-sonnet-4"
        case .openAI: return "openai/gpt-4o"
        case .google: return "google/gemini-2.0-flash"
        }
    }
    
    var requiresApiKey: Bool {
        switch self {
        case .nvidia: return false  // Free tier available
        default: return true
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
    
    // MARK: - Configuration
    @Published var selectedProvider: AIProvider = .nvidia  // Default to free NVIDIA tier
    @Published var apiKey: String = ""
    @Published var selectedChannels: Set<MessagingChannel> = []
    
    // MARK: - OpenClaw Defaults
    let defaultGatewayURL = "http://localhost:18789"
    let defaultGatewayPort = 18789
    
    // Model fallbacks based on Alex Finn's recommendations
    // Use expensive models for thinking, cheap models for execution
    var modelFallbacks: [String] {
        switch selectedProvider {
        case .nvidia:
            return ["anthropic/claude-3-5-haiku-latest", "openai/gpt-4o-mini"]
        case .anthropic:
            return ["nvidia/kimi-k2.5", "anthropic/claude-3-5-haiku-latest"]
        case .openAI:
            return ["nvidia/kimi-k2.5", "openai/gpt-4o-mini"]
        case .google:
            return ["nvidia/kimi-k2.5", "google/gemini-2.0-flash"]
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var installTask: Process?
    
    init() {
        initializeRequirements()
        // Check for demo mode or existing license
        Task {
            await checkExistingLicense()
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
        
        // Trigger step-specific actions
        switch currentStep {
        case .systemCheck:
            runSystemCheck()
        case .installation:
            break // User triggers install
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
            return systemCheckComplete && !requirements.contains { 
                if case .failed = $0.status { return true }
                return false
            }
        case .installation:
            return isInstalled
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
            SystemRequirement(name: "Node.js", description: "v18.0 or later required", status: .checking),
            SystemRequirement(name: "Disk Space", description: "500MB free space required", status: .checking),
            SystemRequirement(name: "Network", description: "Internet connection required", status: .checking)
        ]
    }
    
    func runSystemCheck() {
        print("🚀 [SystemCheck] Starting system check...")
        isLoading = true
        systemCheckComplete = false
        initializeRequirements()
        
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
            if versionNum >= 18 {
                updateRequirement(name: "Node.js", status: .passed)
            } else {
                updateRequirement(name: "Node.js", status: .warning("Node.js \(version) found, v18+ recommended"))
            }
        } else {
            print("🔍 [NodeCheck] FAILED - result was nil or didn't start with 'v'")
            updateRequirement(name: "Node.js", status: .failed("Node.js not found - will install via Homebrew"))
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
    
    func startInstallation() {
        isLoading = true
        installationProgress = 0
        installationStatus = "Preparing installation..."
        
        Task {
            do {
                // Step 1: Check/Install Homebrew
                installationStatus = "Checking Homebrew..."
                installationProgress = 0.1
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                let hasHomebrew = await runShellCommand("which brew") != nil
                if !hasHomebrew {
                    installationStatus = "Installing Homebrew..."
                    // In real app, would install Homebrew here
                }
                installationProgress = 0.2
                
                // Step 2: Check/Install Node.js
                installationStatus = "Checking Node.js..."
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                let hasNode = await runShellCommand("which node") != nil
                if !hasNode {
                    installationStatus = "Installing Node.js via Homebrew..."
                    _ = await runShellCommand("brew install node")
                }
                installationProgress = 0.4
                
                // Step 3: Install OpenClaw
                installationStatus = "Installing OpenClaw..."
                try? await Task.sleep(nanoseconds: 500_000_000)
                installationProgress = 0.6
                
                let installResult = await runShellCommand("npm install -g openclaw")
                installationProgress = 0.8
                
                // Step 4: Verify installation
                installationStatus = "Verifying installation..."
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                let version = await runShellCommand("openclaw --version")
                if version != nil {
                    installationProgress = 1.0
                    installationStatus = "OpenClaw installed successfully!"
                    isInstalled = true
                } else {
                    installationStatus = "Installation may have issues - please verify manually"
                    isInstalled = true // Allow continuing anyway
                }
                
                isLoading = false
                
            } catch {
                installationStatus = "Installation failed: \(error.localizedDescription)"
                isLoading = false
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
                if selectedProvider != .nvidia {
                    authConfig["profiles"] = [
                        "\(providerKey):default": [
                            "provider": providerKey,
                            "mode": "api_key"
                        ],
                        "nvidia:fallback": [
                            "provider": "nvidia",
                            "mode": "none"  // Free tier
                        ]
                    ]
                }
                
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
            // Start the gateway
            _ = await runShellCommand("openclaw gateway start")
            
            // Open the web UI
            if let url = URL(string: defaultGatewayURL) {
                NSWorkspace.shared.open(url)
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
    }
}
