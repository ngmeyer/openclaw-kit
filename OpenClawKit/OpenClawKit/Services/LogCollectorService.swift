import Foundation
import AppKit
import Combine

// MARK: - Log Collector Service
// Collects system info, logs, and debug data for support

@MainActor
class LogCollectorService: ObservableObject {
    static let shared = LogCollectorService()
    
    @Published var isCollecting: Bool = false
    @Published var recentLogs: [LogEntry] = []
    @Published var gatewayStatus: GatewayStatus = .unknown
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: LogLevel
        let message: String
        
        enum LogLevel: String {
            case info = "INFO"
            case warning = "WARN"
            case error = "ERROR"
            case debug = "DEBUG"
            
            var color: String {
                switch self {
                case .info: return "blue"
                case .warning: return "orange"
                case .error: return "red"
                case .debug: return "gray"
                }
            }
        }
    }
    
    enum GatewayStatus: String {
        case running = "Running"
        case stopped = "Stopped"
        case unknown = "Unknown"
        case error = "Error"
    }
    
    private init() {}
    
    // MARK: - System Information
    
    struct SystemInfo {
        let macOSVersion: String
        let macOSBuild: String
        let architecture: String
        let hostname: String
        let openClawKitVersion: String
        let openClawKitBuild: String
        let openClawVersion: String?
        let nodeVersion: String?
        let gatewayStatus: GatewayStatus
        let configPath: String
        let installPath: String?
        let gatewayPort: Int
        let isLicensed: Bool
        let licenseEmail: String?
    }
    
    func collectSystemInfo() async -> SystemInfo {
        let processInfo = ProcessInfo.processInfo
        let osVersion = processInfo.operatingSystemVersion
        let macOSVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        
        // Get build number
        let macOSBuild = await runShellCommand("sw_vers -buildVersion") ?? "Unknown"
        
        // Get architecture
        var architecture = "Unknown"
        var sysinfo = utsname()
        if uname(&sysinfo) == 0 {
            architecture = withUnsafePointer(to: &sysinfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(cString: $0)
                }
            }
        }
        
        // App version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        // OpenClaw version
        let openClawVersion = await runShellCommand("openclaw --version 2>/dev/null")
        
        // Node version
        let nodeVersion = await runShellCommand("node --version 2>/dev/null")
        
        // Gateway status
        let gatewayStatus = await checkGatewayStatus()
        
        // OpenClaw install path
        let installPath = await runShellCommand("which openclaw")
        
        // Config path
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw").path
        
        // License info
        let licenseService = LicenseService.shared
        
        return SystemInfo(
            macOSVersion: macOSVersion,
            macOSBuild: macOSBuild,
            architecture: architecture,
            hostname: Host.current().localizedName ?? "Mac",
            openClawKitVersion: appVersion,
            openClawKitBuild: buildNumber,
            openClawVersion: openClawVersion,
            nodeVersion: nodeVersion,
            gatewayStatus: gatewayStatus,
            configPath: configPath,
            installPath: installPath,
            gatewayPort: 18789,
            isLicensed: licenseService.isLicensed,
            licenseEmail: licenseService.customerEmail
        )
    }
    
    // MARK: - Gateway Status
    
    func checkGatewayStatus() async -> GatewayStatus {
        let result = await runShellCommand("openclaw gateway status 2>/dev/null")
        
        if let output = result?.lowercased() {
            if output.contains("running") || output.contains("started") {
                gatewayStatus = .running
                return .running
            } else if output.contains("stopped") || output.contains("not running") {
                gatewayStatus = .stopped
                return .stopped
            }
        }
        
        // Try to check if process is running
        let pidCheck = await runShellCommand("pgrep -f 'openclaw.*gateway' 2>/dev/null")
        if pidCheck != nil && !pidCheck!.isEmpty {
            gatewayStatus = .running
            return .running
        }
        
        gatewayStatus = .stopped
        return .stopped
    }
    
    // MARK: - Log Collection
    
    func collectRecentLogs(limit: Int = 50) async {
        isCollecting = true
        recentLogs = []
        
        // Collect logs from various sources
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw")
        
        let logPaths = [
            configPath.appendingPathComponent("logs/gateway.log"),
            configPath.appendingPathComponent("gateway.log"),
            configPath.appendingPathComponent("openclaw.log")
        ]
        
        var allEntries: [LogEntry] = []
        
        for logPath in logPaths {
            if let entries = await readLogFile(logPath, limit: limit) {
                allEntries.append(contentsOf: entries)
            }
        }
        
        // Sort by timestamp and limit
        allEntries.sort { $0.timestamp > $1.timestamp }
        recentLogs = Array(allEntries.prefix(limit))
        
        // If no logs found, add a placeholder
        if recentLogs.isEmpty {
            recentLogs.append(LogEntry(
                timestamp: Date(),
                level: .info,
                message: "No log entries found. Gateway may not have been started yet."
            ))
        }
        
        isCollecting = false
    }
    
    private func readLogFile(_ path: URL, limit: Int) async -> [LogEntry]? {
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        
        guard let content = try? String(contentsOf: path, encoding: .utf8) else { return nil }
        
        let lines = content.components(separatedBy: .newlines)
            .suffix(limit)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return lines.compactMap { line -> LogEntry? in
            guard !line.isEmpty else { return nil }
            
            // Parse log level
            var level: LogEntry.LogLevel = .info
            let lowercasedLine = line.lowercased()
            if lowercasedLine.contains("error") || lowercasedLine.contains("[err]") {
                level = .error
            } else if lowercasedLine.contains("warn") {
                level = .warning
            } else if lowercasedLine.contains("debug") {
                level = .debug
            }
            
            // Try to parse timestamp
            var timestamp = Date()
            if let isoMatch = line.range(of: #"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"#, options: .regularExpression) {
                let dateString = String(line[isoMatch])
                if let parsed = dateFormatter.date(from: dateString + "Z") {
                    timestamp = parsed
                }
            }
            
            return LogEntry(timestamp: timestamp, level: level, message: line)
        }
    }
    
    // MARK: - Debug Info Generation
    
    func generateDebugInfo() async -> String {
        let info = await collectSystemInfo()
        
        var output = """
        ==========================================
        OpenClawKit Debug Information
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        ==========================================
        
        ## System Information
        - macOS Version: \(info.macOSVersion) (\(info.macOSBuild))
        - Architecture: \(info.architecture)
        - Hostname: \(info.hostname)
        
        ## OpenClawKit
        - Version: \(info.openClawKitVersion) (Build \(info.openClawKitBuild))
        - Licensed: \(info.isLicensed ? "Yes" : "No")
        
        """
        
        if let email = info.licenseEmail {
            output += "- License Email: \(email)\n"
        }
        
        output += """
        
        ## OpenClaw
        - Version: \(info.openClawVersion ?? "Not installed")
        - Install Path: \(info.installPath ?? "N/A")
        - Gateway Status: \(info.gatewayStatus.rawValue)
        - Gateway Port: \(info.gatewayPort)
        - Config Path: \(info.configPath)
        
        ## Node.js
        - Version: \(info.nodeVersion ?? "Not installed")
        
        ## Recent Logs
        """
        
        await collectRecentLogs(limit: 20)
        
        if recentLogs.isEmpty {
            output += "\nNo recent logs available.\n"
        } else {
            output += "\n"
            for entry in recentLogs.suffix(20) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                output += "[\(formatter.string(from: entry.timestamp))] [\(entry.level.rawValue)] \(entry.message)\n"
            }
        }
        
        output += """
        
        ==========================================
        End of Debug Information
        ==========================================
        """
        
        return output
    }
    
    // MARK: - Export Logs
    
    func exportLogs() async -> URL? {
        let debugInfo = await generateDebugInfo()
        
        // Also collect full log files
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw")
        
        let logPaths = [
            configPath.appendingPathComponent("logs/gateway.log"),
            configPath.appendingPathComponent("gateway.log"),
            configPath.appendingPathComponent("openclaw.log")
        ]
        
        // Create export directory
        let exportDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenClawKit_Logs_\(Int(Date().timeIntervalSince1970))")
        
        do {
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
            
            // Write debug info
            let debugPath = exportDir.appendingPathComponent("debug_info.txt")
            try debugInfo.write(to: debugPath, atomically: true, encoding: .utf8)
            
            // Copy log files
            for logPath in logPaths {
                if FileManager.default.fileExists(atPath: logPath.path) {
                    let destPath = exportDir.appendingPathComponent(logPath.lastPathComponent)
                    try FileManager.default.copyItem(at: logPath, to: destPath)
                }
            }
            
            // Create zip file
            let zipPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("OpenClawKit_Logs.zip")
            
            // Remove existing zip if present
            try? FileManager.default.removeItem(at: zipPath)
            
            let task = Process()
            task.launchPath = "/usr/bin/zip"
            task.arguments = ["-r", zipPath.path, exportDir.lastPathComponent]
            task.currentDirectoryURL = exportDir.deletingLastPathComponent()
            
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                return zipPath
            }
            
            // Fallback to just the debug info
            return debugPath
            
        } catch {
            print("⚠️ [LogCollector] Export failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Copy to Clipboard
    
    func copyDebugInfoToClipboard() async {
        let debugInfo = await generateDebugInfo()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(debugInfo, forType: .string)
    }
    
    // MARK: - Shell Command
    
    private func runShellCommand(_ command: String) async -> String? {
        await withCheckedContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice
            task.arguments = ["-l", "-c", command]
            task.launchPath = "/bin/zsh"
            
            var env = ProcessInfo.processInfo.environment
            let homebrewPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin"
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(homebrewPaths):\(existingPath)"
            } else {
                env["PATH"] = "\(homebrewPaths):/usr/bin:/bin:/usr/sbin:/sbin"
            }
            task.environment = env
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if task.terminationStatus == 0 && output?.isEmpty == false {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
