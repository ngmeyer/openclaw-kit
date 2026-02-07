import Foundation
import AppKit
import Combine

// MARK: - Uninstall Service
// Handles complete uninstallation of OpenClawKit and OpenClaw components

@MainActor
class UninstallService: ObservableObject {
    static let shared = UninstallService()
    
    @Published var isUninstalling: Bool = false
    @Published var uninstallProgress: Double = 0
    @Published var currentStep: String = ""
    @Published var completedSteps: [UninstallStep] = []
    @Published var errors: [String] = []
    
    struct UninstallStep: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        var success: Bool
    }
    
    private init() {}
    
    // MARK: - Components to Remove
    
    struct UninstallOptions {
        var stopGateway: Bool = true
        var removeConfigDirectory: Bool = true
        var removeLaunchAgents: Bool = true
        var removeKeychainEntries: Bool = true
        var removeApp: Bool = true
        var removeOpenClaw: Bool = true
    }
    
    // MARK: - Uninstall Process
    
    func uninstall(options: UninstallOptions = UninstallOptions()) async -> Bool {
        isUninstalling = true
        uninstallProgress = 0
        currentStep = "Starting uninstall..."
        completedSteps = []
        errors = []
        
        let totalSteps: Double = [
            options.stopGateway,
            options.removeOpenClaw,
            options.removeConfigDirectory,
            options.removeLaunchAgents,
            options.removeKeychainEntries,
            options.removeApp
        ].filter { $0 }.count.double
        
        var currentStepNum = 0.0
        
        // Step 1: Stop the gateway
        if options.stopGateway {
            currentStep = "Stopping OpenClaw gateway..."
            let result = await stopGateway()
            currentStepNum += 1
            uninstallProgress = currentStepNum / totalSteps
            completedSteps.append(UninstallStep(
                name: "Stop Gateway",
                detail: result ? "Gateway stopped successfully" : "Gateway was not running",
                success: true // Not a failure if it wasn't running
            ))
        }
        
        // Step 2: Remove OpenClaw
        if options.removeOpenClaw {
            currentStep = "Removing OpenClaw..."
            let result = await removeOpenClaw()
            currentStepNum += 1
            uninstallProgress = currentStepNum / totalSteps
            completedSteps.append(UninstallStep(
                name: "Remove OpenClaw",
                detail: result ? "OpenClaw removed" : "Could not remove OpenClaw (may not be installed)",
                success: result
            ))
            if !result {
                errors.append("Could not remove OpenClaw CLI")
            }
        }
        
        // Step 3: Remove config directory
        if options.removeConfigDirectory {
            currentStep = "Removing configuration files..."
            let result = await removeConfigDirectory()
            currentStepNum += 1
            uninstallProgress = currentStepNum / totalSteps
            completedSteps.append(UninstallStep(
                name: "Remove Config",
                detail: result ? "~/.openclaw removed" : "Config directory not found",
                success: true
            ))
        }
        
        // Step 4: Remove LaunchAgents
        if options.removeLaunchAgents {
            currentStep = "Removing launch agents..."
            let result = await removeLaunchAgents()
            currentStepNum += 1
            uninstallProgress = currentStepNum / totalSteps
            completedSteps.append(UninstallStep(
                name: "Remove Launch Agents",
                detail: result ? "Launch agents removed" : "No launch agents found",
                success: true
            ))
        }
        
        // Step 5: Remove keychain entries
        if options.removeKeychainEntries {
            currentStep = "Removing keychain entries..."
            let result = await removeKeychainEntries()
            currentStepNum += 1
            uninstallProgress = currentStepNum / totalSteps
            completedSteps.append(UninstallStep(
                name: "Clear Keychain",
                detail: result ? "License data cleared" : "No keychain entries found",
                success: true
            ))
        }
        
        // Step 6: Remove app (schedule self-deletion)
        if options.removeApp {
            currentStep = "Preparing to remove app..."
            currentStepNum += 1
            uninstallProgress = currentStepNum / totalSteps
            completedSteps.append(UninstallStep(
                name: "Remove App",
                detail: "App will be moved to Trash on quit",
                success: true
            ))
            
            // Schedule self-deletion after app quits
            scheduleSelfDeletion()
        }
        
        uninstallProgress = 1.0
        currentStep = "Uninstall complete!"
        isUninstalling = false
        
        return errors.isEmpty
    }
    
    // MARK: - Individual Steps
    
    private func stopGateway() async -> Bool {
        let result = await runShellCommand("openclaw gateway stop 2>/dev/null")
        return result != nil
    }
    
    private func removeOpenClaw() async -> Bool {
        // Try npm uninstall first
        let npmResult = await runShellCommand("npm uninstall -g openclaw 2>/dev/null")
        if npmResult != nil {
            return true
        }
        
        // Try direct removal
        let whichResult = await runShellCommand("which openclaw")
        if let path = whichResult {
            _ = await runShellCommand("rm -f '\(path)'")
            return true
        }
        
        return false
    }
    
    private func removeConfigDirectory() async -> Bool {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw")
        
        do {
            if FileManager.default.fileExists(atPath: configPath.path) {
                try FileManager.default.removeItem(at: configPath)
                return true
            }
        } catch {
            print("⚠️ [Uninstall] Failed to remove config: \(error)")
        }
        return false
    }
    
    private func removeLaunchAgents() async -> Bool {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        let agentNames = [
            "com.openclawkit.gateway.plist",
            "com.openclaw.gateway.plist"
        ]
        
        var removed = false
        for name in agentNames {
            let plistPath = launchAgentsPath.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: plistPath.path) {
                // Unload first
                _ = await runShellCommand("launchctl unload '\(plistPath.path)' 2>/dev/null")
                try? FileManager.default.removeItem(at: plistPath)
                removed = true
            }
        }
        
        return removed
    }
    
    private func removeKeychainEntries() async -> Bool {
        // Clear all OpenClawKit keychain entries
        KeychainHelper.delete("license_key")
        KeychainHelper.delete("instance_id")
        KeychainHelper.delete("activation_date")
        KeychainHelper.delete("fallback_device_id")
        return true
    }
    
    private func scheduleSelfDeletion() {
        // Create a script that will move the app to Trash after it quits
        let appPath = Bundle.main.bundlePath
        let script = """
        #!/bin/bash
        sleep 2
        osascript -e 'tell application "Finder" to delete POSIX file "\(appPath)"'
        """
        
        let scriptPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("openclaw_uninstall.sh")
        
        do {
            try script.write(to: scriptPath, atomically: true, encoding: .utf8)
            
            // Make executable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: scriptPath.path
            )
            
            // Launch the script and don't wait
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = [scriptPath.path]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            try task.run()
        } catch {
            print("⚠️ [Uninstall] Failed to schedule self-deletion: \(error)")
        }
    }
    
    // MARK: - Shell Command
    
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
                
                if task.terminationStatus == 0 {
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

// MARK: - Extensions

extension Int {
    var double: Double { Double(self) }
}
