import SwiftUI

/// Demo app to test Skills Marketplace UI
/// Run with: swift run or open in Xcode
@main
struct SkillsMarketplaceDemo: App {
    var body: some Scene {
        WindowGroup {
            SkillsMarketplaceView()
                .frame(minWidth: 1000, minHeight: 700)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
