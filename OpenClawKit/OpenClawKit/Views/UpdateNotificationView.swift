import SwiftUI

struct UpdateNotificationView: View {
    @StateObject private var viewModel = UpdateViewModel.shared
    @State private var expandedChangelog = false
    
    var body: some View {
        if viewModel.showUpdateNotification {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            
                            Text("Update Available")
                                .fontWeight(.bold)
                        }
                        
                        if let version = viewModel.availableVersion {
                            Text("OpenClawKit \(version) is ready to install")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.skipVersion() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color(.controlBackgroundColor))
                
                if viewModel.isDownloading {
                    // Download Progress
                    VStack(spacing: 12) {
                        ProgressView(value: viewModel.downloadProgress)
                            .tint(.blue)
                        
                        HStack {
                            Text("Downloading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(viewModel.downloadProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(16)
                } else {
                    // Changelog Preview
                    if !viewModel.changelog.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("What's New")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button(action: { expandedChangelog.toggle() }) {
                                    Image(systemName: expandedChangelog ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                            }
                            
                            if expandedChangelog {
                                ScrollView {
                                    Text(viewModel.changelog)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .padding(16)
                        .background(Color(.controlBackgroundColor).opacity(0.5))
                    }
                    
                    Divider()
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button(action: { viewModel.remindLater() }) {
                            Text("Remind Later")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { viewModel.downloadAndInstall() }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Update Now")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 8)
            .padding(16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Standalone Update Notification

struct UpdateNotificationWindow {
    static func show() {
        let viewModel = UpdateViewModel.shared
        
        if viewModel.showUpdateNotification {
            let notificationView = UpdateNotificationView()
            let hostingController = NSHostingController(rootView: notificationView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.styleMask = [.borderless, .nonactivatingPanel]
            window.backgroundColor = NSColor.clear
            window.level = .floating
            window.setContentSize(NSSize(width: 400, height: 300))
            
            // Position at top-right
            if let screen = NSScreen.main {
                let x = screen.visibleFrame.maxX - 420
                let y = screen.visibleFrame.maxY - 320
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            window.makeKeyAndOrderFront(nil)
        }
    }
}

#Preview {
    UpdateNotificationView()
}
