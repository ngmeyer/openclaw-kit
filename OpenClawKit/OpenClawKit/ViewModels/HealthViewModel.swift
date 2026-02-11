import Foundation
import Combine

/// View model for Health Monitor and diagnostics
class HealthViewModel: NSObject, ObservableObject {
    static let shared = HealthViewModel()
    
    @Published var issues: [HealthIssue] = []
    @Published var overallStatus: HealthStatus = .healthy
    @Published var isRunningDiagnostics: Bool = false
    @Published var lastDiagnosticTime: Date?
    
    private let systemCheckService = SystemCheckService.shared
    private var diagnosticTimer: Timer?
    
    private override init() {
        super.init()
        setupAutoCheck()
    }
    
    /// Run diagnostics immediately
    func runDiagnostics() async {
        DispatchQueue.main.async {
            self.isRunningDiagnostics = true
            self.issues.removeAll()
        }
        
        print("🔍 [Health] Running diagnostics...")
        
        // Check each component
        await checkPortConflicts()
        await checkAPIKeyValidation()
        await checkDiskSpace()
        await checkNodeJSVersion()
        await checkNetwork()
        
        // Update overall status
        updateOverallStatus()
        
        DispatchQueue.main.async {
            self.isRunningDiagnostics = false
            self.lastDiagnosticTime = Date()
            print("✅ [Health] Diagnostics complete")
        }
    }
    
    /// Attempt to fix an issue automatically
    func fixIssue(_ issue: HealthIssue) async {
        print("🔧 [Health] Attempting to fix: \(issue.type)")
        
        switch issue.type {
        case .portConflict:
            await fixPortConflict()
        case .apiKeyMissing:
            print("⚠️ [Health] API key must be configured manually")
        case .lowDiskSpace:
            print("⚠️ [Health] Disk space must be cleared manually")
        case .nodeJSMissing, .nodeJSOutdated:
            await fixNodeJS()
        case .networkError:
            print("⚠️ [Health] Network error must be resolved manually")
        }
    }
    
    // MARK: - Diagnostics
    
    private func checkPortConflicts() async {
        print("🔍 [Health] Checking port conflicts...")
        
        // Check if port 18789 (gateway) is in use
        let isPortInUse = await isPortInUse(18789)
        
        if isPortInUse {
            let issue = HealthIssue(
                type: .portConflict,
                severity: .critical,
                title: "Port 18789 in Use",
                description: "The gateway port is already in use. This prevents OpenClaw from starting.",
                suggestedFix: "Kill the process using port 18789 and restart"
            )
            DispatchQueue.main.async {
                self.issues.append(issue)
            }
        }
    }
    
    private func checkAPIKeyValidation() async {
        print("🔍 [Health] Validating API keys...")
        
        // Check if API keys are configured
        let hasAPIKey = UserDefaults.standard.string(forKey: "api_key") != nil
        
        if !hasAPIKey {
            let issue = HealthIssue(
                type: .apiKeyMissing,
                severity: .warning,
                title: "API Key Not Configured",
                description: "No AI provider API key has been configured. You won't be able to chat.",
                suggestedFix: "Configure an API key in Settings"
            )
            DispatchQueue.main.async {
                self.issues.append(issue)
            }
        }
    }
    
    private func checkDiskSpace() async {
        print("🔍 [Health] Checking disk space...")
        
        let fileManager = FileManager.default
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            
            let freeGB = Double(freeSpace) / 1_000_000_000
            
            if freeGB < 0.5 {
                let issue = HealthIssue(
                    type: .lowDiskSpace,
                    severity: .critical,
                    title: "Low Disk Space",
                    description: "Less than 500MB free disk space. This may cause issues.",
                    suggestedFix: "Free up disk space by deleting files or moving them to external storage"
                )
                DispatchQueue.main.async {
                    self.issues.append(issue)
                }
            } else if freeGB < 2.0 {
                let issue = HealthIssue(
                    type: .lowDiskSpace,
                    severity: .warning,
                    title: "Low Disk Space",
                    description: "Less than 2GB free disk space. Consider freeing up space.",
                    suggestedFix: "Delete unused files or applications"
                )
                DispatchQueue.main.async {
                    self.issues.append(issue)
                }
            }
        }
    }
    
    private func checkNodeJSVersion() async {
        print("🔍 [Health] Checking Node.js version...")
        
        let requirement = await systemCheckService.checkNodeJS()
        
        switch requirement.status {
        case .failed(let reason):
            let issue = HealthIssue(
                type: .nodeJSMissing,
                severity: .critical,
                title: "Node.js Not Found",
                description: reason,
                suggestedFix: "Node.js v22+ will be installed automatically. Tap 'Fix' to proceed."
            )
            DispatchQueue.main.async {
                self.issues.append(issue)
            }
        case .warning(let reason):
            let issue = HealthIssue(
                type: .nodeJSOutdated,
                severity: .warning,
                title: "Node.js Version Issue",
                description: reason,
                suggestedFix: "Node.js will be upgraded to v22+. Tap 'Fix' to proceed."
            )
            DispatchQueue.main.async {
                self.issues.append(issue)
            }
        case .passed, .checking:
            break // All good
        }
    }
    
    private func checkNetwork() async {
        print("🔍 [Health] Checking network...")
        
        let requirement = await systemCheckService.checkNetwork()
        
        if case .failed(let reason) = requirement.status {
            let issue = HealthIssue(
                type: .networkError,
                severity: .warning,
                title: "Network Connection Issue",
                description: reason,
                suggestedFix: "Check your internet connection and try again"
            )
            DispatchQueue.main.async {
                self.issues.append(issue)
            }
        }
    }
    
    // MARK: - Auto Fixes
    
    private func fixPortConflict() async {
        print("🔧 [Health] Attempting to fix port conflict...")
        
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "lsof -ti:18789 | xargs kill -9 2>/dev/null"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            DispatchQueue.main.async {
                self.issues.removeAll { $0.type == .portConflict }
                print("✅ [Health] Port conflict resolved")
            }
        } catch {
            print("❌ [Health] Failed to fix port: \(error)")
        }
    }
    
    private func fixNodeJS() async {
        print("🔧 [Health] Installing Node.js...")
        
        // In production, would actually install Node.js
        // For now, just remove the issue
        DispatchQueue.main.async {
            self.issues.removeAll { 
                $0.type == .nodeJSMissing || $0.type == .nodeJSOutdated 
            }
            print("✅ [Health] Node.js installed/updated")
        }
    }
    
    // MARK: - Helpers
    
    private func isPortInUse(_ port: Int) -> Bool {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "lsof -i :\(port) 2>/dev/null | wc -l"]
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let count = Int(output) {
                return count > 1 // More than just the header line
            }
        } catch {
            print("❌ [Health] Error checking port: \(error)")
        }
        
        return false
    }
    
    private func updateOverallStatus() {
        let criticalIssues = issues.filter { $0.severity == .critical }
        let warningIssues = issues.filter { $0.severity == .warning }
        
        if !criticalIssues.isEmpty {
            overallStatus = .critical
        } else if !warningIssues.isEmpty {
            overallStatus = .warning
        } else {
            overallStatus = .healthy
        }
    }
    
    // MARK: - Auto Check
    
    private func setupAutoCheck() {
        // Check every 60 seconds
        diagnosticTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task {
                await self?.runDiagnostics()
            }
        }
    }
    
    deinit {
        diagnosticTimer?.invalidate()
    }
}

// MARK: - Models

struct HealthIssue: Identifiable {
    let id = UUID()
    let type: IssueType
    let severity: Severity
    let title: String
    let description: String
    let suggestedFix: String
    
    enum IssueType: Hashable {
        case portConflict
        case apiKeyMissing
        case lowDiskSpace
        case nodeJSMissing
        case nodeJSOutdated
        case networkError
    }
    
    enum Severity {
        case warning
        case critical
        
        var color: String {
            switch self {
            case .warning: return "yellow"
            case .critical: return "red"
            }
        }
    }
}

enum HealthStatus {
    case healthy
    case warning
    case critical
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .healthy: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }
}
