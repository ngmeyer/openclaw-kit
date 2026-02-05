import SwiftUI
import Combine

@main
struct OpenClawKitApp: App {
    // Demo mode: Skip license validation for testing
    // Enable via: --demo flag or OPENCLAWKIT_DEMO=1 env var
    static let isDemoMode: Bool = {
        if CommandLine.arguments.contains("--demo") {
            print("🎭 [Demo] Demo mode enabled via --demo flag")
            return true
        }
        if ProcessInfo.processInfo.environment["OPENCLAWKIT_DEMO"] == "1" {
            print("🎭 [Demo] Demo mode enabled via OPENCLAWKIT_DEMO env var")
            return true
        }
        return false
    }()
    
    var body: some Scene {
        WindowGroup {
            SetupWizardView()
                .frame(minWidth: 700, minHeight: 600)
                .preferredColorScheme(.dark)
                .environmentObject(DemoModeManager.shared)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

// MARK: - Demo Mode Manager
class DemoModeManager: ObservableObject {
    static let shared = DemoModeManager()
    
    @Published var isDemoMode: Bool = OpenClawKitApp.isDemoMode
    
    var demoLicenseKey: String {
        "DEMO-MODE-XXXX-XXXX"
    }
}
