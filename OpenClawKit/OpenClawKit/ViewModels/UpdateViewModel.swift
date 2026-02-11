import Foundation
import Combine
import AppKit

/// View model for managing update notifications and actions
class UpdateViewModel: NSObject, ObservableObject {
    static let shared = UpdateViewModel()
    
    @Published var showUpdateNotification = false
    @Published var availableVersion: String?
    @Published var changelog: String = ""
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    
    private let updateCheckService = UpdateCheckService.shared
    private let updateInstallerService = UpdateInstallerService.shared
    private var cancellables = Set<AnyCancellable>()
    private var notificationWindowController: NSWindowController?
    
    override private init() {
        super.init()
        setupObservers()
    }
    
    /// Setup observers for update notifications
    private func setupObservers() {
        updateCheckService.$availableVersion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] version in
                if let version = version {
                    self?.availableVersion = version
                    self?.changelog = self?.updateCheckService.changelog ?? ""
                    
                    // Only show if not already dismissed
                    if !(self?.updateCheckService.hasDismissedUpdate() ?? false) {
                        self?.showNotification()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Show update notification
    private func showNotification() {
        showUpdateNotification = true
        print("📢 [Update] Showing update notification for version \(availableVersion ?? "?")")
    }
    
    /// Download and install update
    func downloadAndInstall() {
        guard let version = availableVersion else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        
        print("⬇️  [Update] Starting download for version \(version)...")
        
        Task {
            do {
                // Create backup first
                try updateInstallerService.createBackup(currentVersion: "1.0.0")
                
                // Download update
                let dmgURL = try await updateInstallerService.downloadUpdate(
                    version: version,
                    progress: { progress in
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                        }
                    }
                )
                
                // Install update
                try updateInstallerService.installUpdate(from: dmgURL)
                
                // Show success notification
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.showSuccessNotification()
                    
                    // Schedule restart
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        NSApp.terminate(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    print("❌ [Update] Installation failed: \(error)")
                }
            }
        }
    }
    
    /// Remind later
    func remindLater() {
        updateCheckService.dismissUpdate()
        showUpdateNotification = false
        print("⏰ [Update] User chose 'Remind Later'")
    }
    
    /// Skip this version
    func skipVersion() {
        updateCheckService.dismissUpdate()
        showUpdateNotification = false
        print("⏭️  [Update] User skipped this version")
    }
    
    /// Rollback to previous version
    func rollbackToPreviousVersion() {
        Task {
            do {
                try updateInstallerService.rollback(to: "1.0.0")
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            } catch {
                print("❌ [Update] Rollback failed: \(error)")
            }
        }
    }
    
    /// Show success notification
    private func showSuccessNotification() {
        let notification = NSUserNotification()
        notification.title = "Update Installed"
        notification.subtitle = "OpenClawKit will restart to apply the update"
        notification.hasActionButton = false
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
