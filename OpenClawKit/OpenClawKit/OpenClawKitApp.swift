import SwiftUI

@main
struct OpenClawKitApp: App {
    var body: some Scene {
        WindowGroup {
            SetupWizardView()
                .frame(minWidth: 700, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
