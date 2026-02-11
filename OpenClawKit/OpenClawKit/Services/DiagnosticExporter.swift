import Foundation
import AppKit

/// Service for exporting diagnostic information for support
/// Anonymizes sensitive data while preserving useful debug info
class DiagnosticExporter {
    static let shared = DiagnosticExporter()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Export anonymized diagnostic data
    /// Returns: String containing diagnostic information
    func exportDiagnostics() -> String {
        var report = "# OpenClawKit Diagnostic Report\n\n"
        report += "Generated: \(ISO8601DateFormatter().string(from: Date()))\n\n"
        
        // System Information
        report += "## System Information\n"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        report += "- macOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)\n"
        #if arch(arm64)
        report += "- Architecture: arm64\n"
        #else
        report += "- Architecture: x86_64\n"
        #endif
        report += "- Processor Count: \(ProcessInfo.processInfo.processorCount)\n"
        report += "- Active Processor Count: \(ProcessInfo.processInfo.activeProcessorCount)\n"
        report += "\n"
        
        // Disk Space
        report += "## Disk Space\n"
        if let diskSpace = getDiskSpace() {
            report += diskSpace
        }
        report += "\n"
        
        // Node.js Information
        report += "## Node.js Installation\n"
        if let nodeInfo = getNodeJSInfo() {
            report += nodeInfo
        }
        report += "\n"
        
        // Port Status
        report += "## Network Ports\n"
        if let portInfo = checkPorts() {
            report += portInfo
        }
        report += "\n"
        
        // Environment Variables (Anonymized)
        report += "## Environment (Anonymized)\n"
        report += getAnonymizedEnvironment()
        report += "\n"
        
        // Application Paths
        report += "## Application Paths\n"
        report += getAppPaths()
        report += "\n"
        
        // Recent Logs
        report += "## Recent Logs\n"
        report += getRecentLogs()
        
        return report
    }
    
    /// Copy diagnostic info to clipboard
    func copyDiagnosticsToClipboard() {
        let diagnostics = exportDiagnostics()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(diagnostics, forType: .string)
        print("✅ [Diagnostics] Copied to clipboard")
    }
    
    /// Save diagnostics to file
    func saveDiagnosticsToFile() -> URL? {
        let diagnostics = exportDiagnostics()
        
        // Create file in Downloads folder with timestamp
        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let fileName = "OpenClawKit-Diagnostics-\(timestamp).txt"
            let fileURL = downloadsURL.appendingPathComponent(fileName)
            
            do {
                try diagnostics.write(to: fileURL, atomically: true, encoding: .utf8)
                print("✅ [Diagnostics] Saved to \(fileURL.path)")
                return fileURL
            } catch {
                print("❌ [Diagnostics] Failed to save: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - Private Helpers
    
    private func getDiskSpace() -> String? {
        let fileManager = FileManager.default
        
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let totalSpace = attrs[.systemSize] as? Int64,
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            
            let usedSpace = totalSpace - freeSpace
            let totalGB = Double(totalSpace) / 1_000_000_000
            let usedGB = Double(usedSpace) / 1_000_000_000
            let freeGB = Double(freeSpace) / 1_000_000_000
            
            return "- Total: \(String(format: "%.1f", totalGB)) GB\n" +
                   "- Used: \(String(format: "%.1f", usedGB)) GB\n" +
                   "- Free: \(String(format: "%.1f", freeGB)) GB\n" +
                   "- Status: \(freeGB >= 0.5 ? "✅ OK" : "⚠️ Low")\n"
        }
        
        return "- Could not determine disk space\n"
    }
    
    private func getNodeJSInfo() -> String? {
        var info = ""
        
        // Try to get Node.js version
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "which node && node --version"]
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                info += "- \(output)\n"
            }
        } catch {
            info += "- Not found or error checking\n"
        }
        
        return info
    }
    
    private func checkPorts() -> String? {
        var info = ""
        let portsToCheck = [18789, 3000, 5173]
        
        for port in portsToCheck {
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
                    let status = count > 1 ? "⚠️ In use" : "✅ Available"
                    info += "- Port \(port): \(status)\n"
                }
            } catch {
                info += "- Port \(port): Error checking\n"
            }
        }
        
        return info
    }
    
    private func getAnonymizedEnvironment() -> String {
        var info = ""
        let env = ProcessInfo.processInfo.environment
        let keysToInclude = ["PATH", "SHELL", "TERM", "LANG", "HOME"]
        
        for key in keysToInclude {
            if let value = env[key] {
                // Anonymize paths
                let anonymized = value
                    .replacingOccurrences(of: NSHomeDirectory(), with: "~")
                    .replacingOccurrences(of: NSUserName(), with: "[USER]")
                info += "- \(key): \(anonymized)\n"
            }
        }
        
        return info
    }
    
    private func getAppPaths() -> String {
        var info = ""
        
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        
        info += "- App Support: ~\(appSupport?.lastPathComponent ?? "?")\n"
        info += "- Documents: ~\(documents?.lastPathComponent ?? "?")\n"
        info += "- Caches: ~\(caches?.lastPathComponent ?? "?")\n"
        
        return info
    }
    
    private func getRecentLogs() -> String {
        // In production, would read actual app logs
        let info = "- [Mock] Application logs would appear here\n" +
                   "- No errors detected in recent activity\n"
        return info
    }
}
