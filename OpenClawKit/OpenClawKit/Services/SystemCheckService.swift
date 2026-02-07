import Foundation

/// P1: System check logic extracted from ViewModel
/// Protocol-based for testability, uses async/await with proper error handling
protocol SystemCheckServiceProtocol {
    func checkMacOSVersion() async -> SystemRequirement
    func checkNodeJS() async -> SystemRequirement
    func checkDiskSpace() async -> SystemRequirement
    func checkNetwork() async -> SystemRequirement
}

class SystemCheckService: SystemCheckServiceProtocol {
    static let shared = SystemCheckService()
    
    private init() {}
    
    // MARK: - System Checks
    
    func checkMacOSVersion() async -> SystemRequirement {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion)"
        
        if version.majorVersion >= 12 {
            return SystemRequirement(
                name: "macOS Version",
                description: "macOS \(versionString)",
                status: .passed
            )
        } else {
            return SystemRequirement(
                name: "macOS Version",
                description: "macOS 12.0 or later",
                status: .failed("macOS \(versionString) found, 12.0+ required")
            )
        }
    }
    
    func checkNodeJS() async -> SystemRequirement {
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
                return SystemRequirement(
                    name: "Node.js",
                    description: "v22.0 or later required",
                    status: .passed
                )
            } else {
                return SystemRequirement(
                    name: "Node.js",
                    description: "v22.0 or later required",
                    status: .warning("Node.js \(version) found - will upgrade to v22")
                )
            }
        } else {
            print("🔍 [NodeCheck] FAILED - result was nil or didn't start with 'v'")
            return SystemRequirement(
                name: "Node.js",
                description: "v22.0 or later required",
                status: .warning("Not found - will install v22 automatically")
            )
        }
    }
    
    func checkDiskSpace() async -> SystemRequirement {
        let fileManager = FileManager.default
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            let freeGB = Double(freeSpace) / 1_000_000_000
            if freeGB >= 0.5 {
                return SystemRequirement(
                    name: "Disk Space",
                    description: "500MB free space required",
                    status: .passed
                )
            } else {
                return SystemRequirement(
                    name: "Disk Space",
                    description: "500MB free space required",
                    status: .failed("Only \(String(format: "%.1f", freeGB))GB free")
                )
            }
        } else {
            return SystemRequirement(
                name: "Disk Space",
                description: "500MB free space required",
                status: .warning("Could not check disk space")
            )
        }
    }
    
    func checkNetwork() async -> SystemRequirement {
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
            return SystemRequirement(
                name: "Network",
                description: "Internet connection required",
                status: .passed
            )
        } else {
            print("🌐 [NetworkCheck] FAILED - expected '200', got '\(result ?? "nil")'")
            return SystemRequirement(
                name: "Network",
                description: "Internet connection required",
                status: .failed("Cannot reach npm registry (got: \(result ?? "nil"))")
            )
        }
    }
    
    // MARK: - Shell Command Runner
    
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
}
