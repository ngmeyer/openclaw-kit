import SwiftUI
import Combine
import AppKit

@main
struct OpenClawKitApp: App {
    // Demo mode: Skip license validation and installation for UI testing
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
        return false  // Production mode by default
    }()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SetupWizardView()
                .frame(minWidth: 900, minHeight: 750)
                .preferredColorScheme(.dark)
                .environmentObject(DemoModeManager.shared)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Replace default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About OpenClawKit") {
                    AboutWindowController.shared.showWindow()
                }
            }
            
            // Add Help menu items
            CommandGroup(replacing: .help) {
                Button("OpenClawKit Help") {
                    if let url = URL(string: "https://docs.openclawkit.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Divider()
                
                Button("Contact Support...") {
                    let subject = "OpenClawKit Support"
                    let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "mailto:support@openclawkit.ai?subject=\(encodedSubject)") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Report an Issue...") {
                    if let url = URL(string: "https://github.com/openclawkit/issues/new") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        // About/Support window
        Window("About OpenClawKit", id: "about") {
            AboutSupportView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarStatusItem: MenuBarStatusItem?
    private var updateCheckService: UpdateCheckService?
    private var healthMonitor: HealthViewModel?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Disable automatic window restoration
        NSWindow.allowsAutomaticWindowTabbing = false
        
        // Initialize services
        menuBarStatusItem = MenuBarStatusItem.shared
        updateCheckService = UpdateCheckService.shared
        healthMonitor = HealthViewModel.shared
        
        // Start periodic update checks (weekly)
        Task {
            updateCheckService?.checkForUpdates()
        }
        
        // Start health monitoring
        Task {
            await healthMonitor?.runDiagnostics()
        }
        
        print("✅ [AppDelegate] OpenClawKit services initialized")
    }
}

// MARK: - About Window Controller
class AboutWindowController {
    static let shared = AboutWindowController()
    
    private var aboutWindow: NSWindow?
    
    func showWindow() {
        // Check if window already exists
        if let existingWindow = aboutWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create new window
        let aboutView = AboutSupportView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About OpenClawKit"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
        window.setContentSize(NSSize(width: 600, height: 550))
        window.center()
        
        // Keep reference
        aboutWindow = window
        
        // Show window
        window.makeKeyAndOrderFront(nil)
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
