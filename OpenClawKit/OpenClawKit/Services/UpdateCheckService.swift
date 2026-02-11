import Foundation
import Combine

/// Service responsible for checking for updates
/// Checks weekly for new versions from GitHub releases
class UpdateCheckService: NSObject, ObservableObject {
    static let shared = UpdateCheckService()
    
    @Published var availableVersion: String?
    @Published var changelog: String = ""
    @Published var isCheckingForUpdates: Bool = false
    @Published var lastCheckDate: Date?
    
    private let currentVersion = "1.0.0" // TODO: Read from Info.plist
    private let userDefaults = UserDefaults.standard
    private let lastCheckKey = "OCK_LastUpdateCheck"
    private let dismissedVersionKey = "OCK_DismissedUpdateVersion"
    
    private override init() {
        super.init()
        // Restore last check date
        if let lastCheck = userDefaults.object(forKey: lastCheckKey) as? Date {
            self.lastCheckDate = lastCheck
        }
    }
    
    /// Check for updates (respects weekly check interval)
    func checkForUpdates(forceCheck: Bool = false) {
        guard !isCheckingForUpdates else { return }
        
        // If not forced, check if we should skip (weekly interval)
        if !forceCheck {
            if let lastCheck = lastCheckDate {
                let daysSinceCheck = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
                if daysSinceCheck < 7 {
                    print("⏭️ [Updates] Skipping check, last check was \(daysSinceCheck) days ago")
                    return
                }
            }
        }
        
        isCheckingForUpdates = true
        print("🔍 [Updates] Checking for updates...")
        
        // Simulate API call (in production, would check GitHub releases)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Mock: Check if there's a newer version available
            let versions = ["1.0.1", "1.0.2", "1.1.0"]
            let randomVersion = versions.randomElement() ?? "1.0.1"
            
            // For demo, 50% chance of finding an update
            if Bool.random() {
                DispatchQueue.main.async {
                    self.availableVersion = randomVersion
                    self.changelog = """
                    OpenClawKit \(randomVersion)
                    
                    ✨ New Features:
                    • Improved chat streaming performance
                    • Better error handling for network issues
                    • New Skills Marketplace integration
                    
                    🐛 Bug Fixes:
                    • Fixed memory leak in message history
                    • Resolved menu bar status display issue
                    • Improved health monitor diagnostics
                    
                    📊 Improvements:
                    • Auto-update system now available
                    • Enhanced token usage tracking
                    • Better cost estimation
                    """
                    self.isCheckingForUpdates = false
                    self.lastCheckDate = Date()
                    self.userDefaults.set(self.lastCheckDate, forKey: self.lastCheckKey)
                    print("✅ [Updates] New version available: \(randomVersion)")
                }
            } else {
                DispatchQueue.main.async {
                    self.isCheckingForUpdates = false
                    self.lastCheckDate = Date()
                    self.userDefaults.set(self.lastCheckDate, forKey: self.lastCheckKey)
                    print("✅ [Updates] App is up to date")
                }
            }
        }
    }
    
    /// Check if there's a dismissed update (shown but user clicked "Remind Later")
    func hasDismissedUpdate() -> Bool {
        if let dismissedVersion = userDefaults.string(forKey: dismissedVersionKey),
           let availableVersion = availableVersion {
            return dismissedVersion == availableVersion
        }
        return false
    }
    
    /// Mark current available version as dismissed
    func dismissUpdate() {
        if let version = availableVersion {
            userDefaults.set(version, forKey: dismissedVersionKey)
        }
    }
    
    /// Clear dismissed version (so we show the notification again)
    func clearDismissed() {
        userDefaults.removeObject(forKey: dismissedVersionKey)
    }
}
