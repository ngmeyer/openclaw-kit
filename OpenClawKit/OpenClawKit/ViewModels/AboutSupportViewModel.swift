import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - About/Support ViewModel
// Manages the About/Support dialog state and actions

@MainActor
class AboutSupportViewModel: ObservableObject {
    // MARK: - Tab Selection
    enum Tab: String, CaseIterable {
        case about = "About"
        case license = "License"
        case support = "Support"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .about: return "info.circle.fill"
            case .license: return "key.fill"
            case .support: return "questionmark.circle.fill"
            case .advanced: return "gearshape.fill"
            }
        }
    }
    
    @Published var selectedTab: Tab = .about
    
    // MARK: - App Info
    var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "OpenClawKit"
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var copyrightText: String {
        "© 2025 Gearu LLC. All rights reserved."
    }
    
    let supportEmail = "support@openclawkit.ai"
    let websiteURL = "https://openclawkit.ai"
    
    // MARK: - License State
    @Published var licenseService = LicenseService.shared
    @Published var showLicenseKey: Bool = false
    @Published var isProcessingLicense: Bool = false
    @Published var licenseMessage: String?
    @Published var licenseMessageIsError: Bool = false
    @Published var newLicenseKey: String = ""
    @Published var showChangeLicenseSheet: Bool = false
    
    var maskedLicenseKey: String {
        guard let key = KeychainHelper.get("license_key") else { return "Not activated" }
        if showLicenseKey { return key }
        
        let components = key.split(separator: "-")
        if components.count >= 4 {
            return "\(components[0])-****-****-\(components.last ?? "****")"
        }
        return String(key.prefix(8)) + "..." + String(key.suffix(4))
    }
    
    var activationDate: String? {
        guard let dateString = KeychainHelper.get("activation_date"),
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var licenseStatusText: String {
        switch licenseService.licenseStatus {
        case .unknown: return "Not activated"
        case .checking: return "Checking..."
        case .valid: return "Active"
        case .expired: return "Expired"
        case .invalid: return "Invalid"
        case .activationLimitReached: return "Activation limit reached"
        case .error(let msg): return "Error: \(msg)"
        }
    }
    
    var licenseStatusColor: Color {
        switch licenseService.licenseStatus {
        case .valid: return .green
        case .expired, .invalid, .activationLimitReached: return .red
        case .error: return .orange
        default: return .white.opacity(0.6)
        }
    }
    
    // MARK: - Support State
    @Published var systemInfo: LogCollectorService.SystemInfo?
    @Published var recentLogs: [LogCollectorService.LogEntry] = []
    @Published var isLoadingInfo: Bool = false
    @Published var isCopying: Bool = false
    @Published var isExporting: Bool = false
    @Published var exportSuccess: Bool = false
    
    // MARK: - Advanced/Reset State
    @Published var showResetPrefsConfirm: Bool = false
    @Published var showClearLicenseConfirm: Bool = false
    @Published var showResetAllConfirm: Bool = false
    @Published var showUninstallConfirm: Bool = false
    @Published var isResetting: Bool = false
    @Published var resetMessage: String?
    
    // MARK: - Uninstall State
    @Published var uninstallService = UninstallService.shared
    @Published var showUninstallProgress: Bool = false
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadSupportInfo()
        }
    }
    
    // MARK: - About Actions
    
    func openWebsite() {
        if let url = URL(string: websiteURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openSupportEmail() {
        let subject = "OpenClawKit Support - v\(appVersion)"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - License Actions
    
    func deactivateLicense() async {
        isProcessingLicense = true
        licenseMessage = nil
        
        let success = await licenseService.deactivate()
        
        if success {
            licenseMessage = "License deactivated successfully"
            licenseMessageIsError = false
        } else {
            licenseMessage = "Failed to deactivate license"
            licenseMessageIsError = true
        }
        
        isProcessingLicense = false
    }
    
    func activateNewLicense() async {
        guard !newLicenseKey.isEmpty else {
            licenseMessage = "Please enter a license key"
            licenseMessageIsError = true
            return
        }
        
        isProcessingLicense = true
        licenseMessage = nil
        
        let result = await licenseService.activate(licenseKey: newLicenseKey)
        
        switch result {
        case .success:
            licenseMessage = "License activated successfully!"
            licenseMessageIsError = false
            showChangeLicenseSheet = false
            newLicenseKey = ""
        case .failure(let error):
            licenseMessage = error.localizedDescription
            licenseMessageIsError = true
        }
        
        isProcessingLicense = false
    }
    
    func validateLicense() async {
        isProcessingLicense = true
        licenseMessage = nil
        
        let isValid = await licenseService.validate()
        
        if isValid {
            licenseMessage = "License is valid"
            licenseMessageIsError = false
        } else {
            licenseMessage = "License validation failed"
            licenseMessageIsError = true
        }
        
        isProcessingLicense = false
    }
    
    // MARK: - Support Actions
    
    func loadSupportInfo() async {
        isLoadingInfo = true
        
        let logCollector = LogCollectorService.shared
        systemInfo = await logCollector.collectSystemInfo()
        await logCollector.collectRecentLogs(limit: 30)
        recentLogs = logCollector.recentLogs
        
        isLoadingInfo = false
    }
    
    func refreshGatewayStatus() async {
        let status = await LogCollectorService.shared.checkGatewayStatus()
        systemInfo = await LogCollectorService.shared.collectSystemInfo()
    }
    
    func copyDebugInfo() async {
        isCopying = true
        await LogCollectorService.shared.copyDebugInfoToClipboard()
        
        // Brief visual feedback
        try? await Task.sleep(nanoseconds: 500_000_000)
        isCopying = false
    }
    
    func exportLogs() async {
        isExporting = true
        exportSuccess = false
        
        if let url = await LogCollectorService.shared.exportLogs() {
            // Show in Finder
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            exportSuccess = true
        }
        
        isExporting = false
    }
    
    func startGateway() async {
        _ = await runShellCommand("openclaw gateway start")
        await refreshGatewayStatus()
    }
    
    func stopGateway() async {
        _ = await runShellCommand("openclaw gateway stop")
        await refreshGatewayStatus()
    }
    
    func restartGateway() async {
        _ = await runShellCommand("openclaw gateway restart")
        await refreshGatewayStatus()
    }
    
    // MARK: - Reset Actions
    
    func resetPreferences() {
        isResetting = true
        
        // Get all keys for our app's UserDefaults
        let domain = Bundle.main.bundleIdentifier ?? "com.gearu.OpenClawKit"
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        resetMessage = "Preferences reset successfully"
        isResetting = false
        showResetPrefsConfirm = false
    }
    
    func clearLicense() async {
        isResetting = true
        
        // Deactivate on server first (best effort)
        _ = await licenseService.deactivate()
        
        // Clear local license data
        licenseService.clearLicense()
        
        resetMessage = "License cleared successfully"
        isResetting = false
        showClearLicenseConfirm = false
    }
    
    func resetToFirstLaunch() async {
        isResetting = true
        
        // Clear preferences
        let domain = Bundle.main.bundleIdentifier ?? "com.gearu.OpenClawKit"
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Clear license (best effort deactivation)
        _ = await licenseService.deactivate()
        licenseService.clearLicense()
        
        resetMessage = "Reset complete. Please restart the app."
        isResetting = false
        showResetAllConfirm = false
    }
    
    // MARK: - Uninstall Actions
    
    func startUninstall() async {
        showUninstallProgress = true
        showUninstallConfirm = false
        
        let success = await uninstallService.uninstall()
        
        if success && uninstallService.completedSteps.contains(where: { $0.name == "Remove App" }) {
            // Show final message and quit
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    // MARK: - Helper
    
    private func runShellCommand(_ command: String) async -> String? {
        await withCheckedContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-l", "-c", command]
            task.launchPath = "/bin/zsh"
            
            var env = ProcessInfo.processInfo.environment
            let homebrewPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin"
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(homebrewPaths):\(existingPath)"
            }
            task.environment = env
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                continuation.resume(returning: task.terminationStatus == 0 ? output : nil)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
