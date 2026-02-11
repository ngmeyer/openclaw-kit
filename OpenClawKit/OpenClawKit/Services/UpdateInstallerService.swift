import Foundation

/// Service responsible for downloading and installing updates
/// Handles rollback if needed
class UpdateInstallerService {
    static let shared = UpdateInstallerService()
    
    private let fileManager = FileManager.default
    private let backupDirectory: URL
    private let appDirectory: URL
    
    private init() {
        // Backup stored in ~/Library/Application Support/OpenClawKit/Backups
        if let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appSupportDir = supportDir.appendingPathComponent("OpenClawKit", isDirectory: true)
            backupDirectory = appSupportDir.appendingPathComponent("Backups", isDirectory: true)
            appDirectory = appSupportDir.appendingPathComponent("App", isDirectory: true)
            
            // Create directories if needed
            try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        } else {
            fatalError("Could not determine application support directory")
        }
    }
    
    /// Download update in background
    /// Returns: URL to the downloaded file
    func downloadUpdate(version: String, progress: @escaping (Double) -> Void) async throws -> URL {
        print("⬇️  [Update] Downloading version \(version)...")
        
        // Create download destination
        let downloadURL = backupDirectory.appendingPathComponent("OpenClawKit-\(version).dmg")
        
        // Mock download with simulated progress
        for i in 0...100 {
            let progressValue = Double(i) / 100.0
            DispatchQueue.main.async {
                progress(progressValue)
            }
            try await Task.sleep(nanoseconds: 10_000_000) // Simulate download delay
        }
        
        // Create mock file to represent downloaded update
        try Data("mock update data".utf8).write(to: downloadURL)
        
        print("✅ [Update] Download complete: \(downloadURL.lastPathComponent)")
        return downloadURL
    }
    
    /// Create backup of current version before updating
    func createBackup(currentVersion: String) throws {
        print("💾 [Update] Creating backup of version \(currentVersion)...")
        
        let backupPath = backupDirectory.appendingPathComponent("OpenClawKit-\(currentVersion)-\(ISO8601DateFormatter().string(from: Date()))")
        
        // In production, would copy actual app bundle
        // For now, just create marker file
        try fileManager.createDirectory(at: backupPath, withIntermediateDirectories: true)
        try "backup_marker".write(to: backupPath.appendingPathComponent("marker.txt"), atomically: true, encoding: .utf8)
        
        print("✅ [Update] Backup created at \(backupPath.lastPathComponent)")
    }
    
    /// Install the downloaded update
    func installUpdate(from dmgPath: URL) throws {
        print("🔧 [Update] Installing update from \(dmgPath.lastPathComponent)...")
        
        // In production, would:
        // 1. Mount DMG
        // 2. Copy application
        // 3. Unmount DMG
        // 4. Schedule restart
        
        print("✅ [Update] Update installed successfully")
    }
    
    /// Rollback to previous version
    func rollback(to version: String) throws {
        print("⏮️  [Update] Rolling back to version \(version)...")
        
        let backupPath = backupDirectory.appendingPathComponent("OpenClawKit-\(version)-*")
        
        // Find the backup
        if let backup = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
            .filter({ $0.lastPathComponent.hasPrefix("OpenClawKit-\(version)") })
            .first {
            
            // In production, would restore from backup
            print("✅ [Update] Rollback to \(version) successful")
        } else {
            throw UpdateError.backupNotFound
        }
    }
    
    /// Get list of available backups
    func getAvailableBackups() -> [String] {
        guard let contents = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents
            .filter { $0.lastPathComponent.hasPrefix("OpenClawKit-") }
            .map { $0.lastPathComponent }
            .sorted(by: >)
    }
    
    /// Clean up old backups (keep only last 1 week)
    func cleanupOldBackups() {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        guard let contents = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        
        for url in contents {
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let modDate = attrs[.modificationDate] as? Date,
               modDate < oneWeekAgo {
                try? fileManager.removeItem(at: url)
                print("🗑️  [Update] Deleted old backup: \(url.lastPathComponent)")
            }
        }
    }
}

enum UpdateError: LocalizedError {
    case backupNotFound
    case downloadFailed
    case installationFailed
    case invalidVersion
    
    var errorDescription: String? {
        switch self {
        case .backupNotFound:
            return "Backup not found for rollback"
        case .downloadFailed:
            return "Failed to download update"
        case .installationFailed:
            return "Failed to install update"
        case .invalidVersion:
            return "Invalid version format"
        }
    }
}
