import Foundation
import Security

// MARK: - Integrity Checker
// Basic anti-tampering and security checks

class IntegrityChecker {
    
    /// Check if app is properly code-signed
    static func isCodeSignatureValid() -> Bool {
        guard let bundlePath = Bundle.main.bundlePath as CFString? else {
            return false
        }
        
        var staticCode: SecStaticCode?
        let createStatus = SecStaticCodeCreateWithPath(
            URL(fileURLWithPath: bundlePath as String) as CFURL,
            [],
            &staticCode
        )
        
        guard createStatus == errSecSuccess, let code = staticCode else {
            print("⚠️ [Integrity] Failed to create static code: \(createStatus)")
            return false
        }
        
        // Validate signature
        let validationStatus = SecStaticCodeCheckValidity(
            code,
            SecCSFlags(rawValue: kSecCSCheckAllArchitectures),
            nil
        )
        
        let isValid = validationStatus == errSecSuccess
        print("🔒 [Integrity] Code signature valid: \(isValid)")
        return isValid
    }
    
    /// Check if running under a debugger (basic anti-debugging)
    static func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        guard result == 0 else { return false }
        
        let isDebugged = (info.kp_proc.p_flag & P_TRACED) != 0
        if isDebugged {
            print("⚠️ [Integrity] Debugger detected")
        }
        return isDebugged
    }
    
    /// Verify bundle identifier matches expected
    static func verifyBundleIdentifier(expected: String) -> Bool {
        let actual = Bundle.main.bundleIdentifier ?? ""
        let matches = actual == expected
        if !matches {
            print("⚠️ [Integrity] Bundle ID mismatch: expected \(expected), got \(actual)")
        }
        return matches
    }
    
    /// Run all integrity checks
    static func runAllChecks(expectedBundleId: String = "com.openclawkit.OpenClawKit") -> IntegrityResult {
        var issues: [String] = []
        
        #if !DEBUG
        // Only enforce in release builds
        if !isCodeSignatureValid() {
            issues.append("Invalid code signature")
        }
        
        if isBeingDebugged() {
            issues.append("Debugger attached")
        }
        
        if !verifyBundleIdentifier(expected: expectedBundleId) {
            issues.append("Bundle identifier mismatch")
        }
        #endif
        
        if issues.isEmpty {
            return .passed
        } else {
            return .failed(issues)
        }
    }
}

enum IntegrityResult {
    case passed
    case failed([String])
    
    var isValid: Bool {
        if case .passed = self { return true }
        return false
    }
}
