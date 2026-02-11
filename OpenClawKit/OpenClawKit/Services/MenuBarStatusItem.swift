import AppKit
import SwiftUI
import Combine

/// Manages the menu bar status item for OpenClawKit
/// Shows status, tokens used, cost estimate, and quick actions
class MenuBarStatusItem: NSObject, ObservableObject {
    static let shared = MenuBarStatusItem()
    
    @Published var gatewayStatus: GatewayStatus = .stopped
    @Published var tokensUsedToday: Int = 0
    @Published var estimatedCostToday: Double = 0.0
    @Published var dailyLimit: Int = 1_000_000
    @Published var isHealthy: Bool = true
    
    private var statusItem: NSStatusItem?
    private var statusWindow: NSWindow?
    private var statusViewController: NSHostingController<MenuBarPopoverView>?
    private let userDefaults = UserDefaults.standard
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    override private init() {
        super.init()
        setupStatusItem()
        setupAutoUpdate()
    }
    
    /// Setup the menu bar status item
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            updateStatusIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    /// Setup periodic updates from gateway status
    private func setupAutoUpdate() {
        // Update every 10 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        
        // Initial update
        updateStatus()
    }
    
    /// Update status from gateway
    private func updateStatus() {
        // Mock: Simulate getting gateway status
        // In production, would query actual gateway
        let isRunning = Bool.random()
        gatewayStatus = isRunning ? .running : .paused
        
        // Mock token usage
        tokensUsedToday = Int.random(in: 10000...500000)
        
        // Estimate cost at $0.01 per 1M tokens (approximate)
        estimatedCostToday = Double(tokensUsedToday) * 0.01 / 1_000_000
        
        // Check health
        Task {
            let healthVM = HealthViewModel.shared
            await healthVM.runDiagnostics()
            DispatchQueue.main.async {
                self.isHealthy = healthVM.issues.isEmpty
            }
        }
        
        DispatchQueue.main.async {
            self.updateStatusIcon()
        }
    }
    
    /// Update the status icon in menu bar
    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        
        let statusSymbol: String
        let color: NSColor
        
        if !isHealthy {
            statusSymbol = "exclamationmark.triangle.fill"
            color = NSColor.systemRed
        } else if gatewayStatus == .running {
            statusSymbol = "circle.fill"
            color = NSColor.systemGreen
        } else if gatewayStatus == .paused {
            statusSymbol = "circle.fill"
            color = NSColor.systemYellow
        } else {
            statusSymbol = "circle.fill"
            color = NSColor.systemRed
        }
        
        // Create attributed title with icon
        let config = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        if let image = NSImage(systemSymbolName: statusSymbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            button.image = image
            button.contentTintColor = color
        }
    }
    
    /// Toggle the popover menu
    @objc private func togglePopover() {
        if statusWindow?.isVisible ?? false {
            statusWindow?.orderOut(nil)
        } else {
            showPopover()
        }
    }
    
    /// Show the status popover
    private func showPopover() {
        guard let statusButton = statusItem?.button else { return }
        
        let popoverView = MenuBarPopoverView(
            statusItem: self,
            onPauseAllAgents: { self.pauseAllAgents() }
        )
        
        statusViewController = NSHostingController(rootView: popoverView)
        statusViewController?.view.wantsLayer = true
        statusViewController?.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        let window = NSWindow(contentViewController: statusViewController!)
        window.styleMask = [.borderless, .nonactivatingPanel]
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.setContentSize(NSSize(width: 300, height: 320))
        
        // Position below status item
        if let frame = statusButton.window?.frame {
            let popoverX = frame.midX - 150
            let popoverY = frame.minY - 320
            window.setFrameOrigin(NSPoint(x: popoverX, y: popoverY))
        }
        
        statusWindow = window
        window.makeKeyAndOrderFront(nil)
    }
    
    /// Pause all agents
    private func pauseAllAgents() {
        print("⏸️  [MenuBar] Pausing all agents...")
        gatewayStatus = .paused
        updateStatusIcon()
        
        // In production, would send pause command to gateway
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.statusWindow?.orderOut(nil)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Status Models

enum GatewayStatus {
    case running
    case paused
    case error
    case stopped
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .paused: return "Paused"
        case .error: return "Error"
        case .stopped: return "Stopped"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .stopped: return "stop.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .green
        case .paused: return .yellow
        case .error: return .red
        case .stopped: return .gray
        }
    }
}

// MARK: - Popover View

struct MenuBarPopoverView: View {
    @ObservedObject var statusItem: MenuBarStatusItem
    let onPauseAllAgents: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: statusItem.gatewayStatus.icon)
                        .foregroundColor(statusItem.gatewayStatus.color)
                    
                    Text(statusItem.gatewayStatus.displayName)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                if !statusItem.isHealthy {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Warning: System issues detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Status Details
            VStack(spacing: 12) {
                StatRow(
                    label: "Tokens Today",
                    value: formatTokens(statusItem.tokensUsedToday),
                    icon: "doc.text.fill"
                )
                
                StatRow(
                    label: "Estimated Cost",
                    value: String(format: "$%.2f", statusItem.estimatedCostToday),
                    icon: "creditcard.fill"
                )
                
                // Daily Limit Progress
                VStack(spacing: 6) {
                    HStack {
                        Text("Daily Limit")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        let percentage = Double(statusItem.tokensUsedToday) / Double(statusItem.dailyLimit)
                        Text(String(format: "%.0f%%", percentage * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(
                        value: Double(statusItem.tokensUsedToday),
                        total: Double(statusItem.dailyLimit)
                    )
                    .tint(progressColor(for: statusItem.tokensUsedToday, limit: statusItem.dailyLimit))
                }
            }
            .padding(12)
            
            Divider()
            
            // Actions
            VStack(spacing: 8) {
                Button(action: onPauseAllAgents) {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                        Text("Pause All Agents")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    // Open health monitor or settings
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings & Health")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
        }
        .frame(width: 300)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
    
    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    private func progressColor(for used: Int, limit: Int) -> Color {
        let percentage = Double(used) / Double(limit)
        if percentage >= 0.9 {
            return .red
        } else if percentage >= 0.75 {
            return .orange
        } else if percentage >= 0.5 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    MenuBarPopoverView(
        statusItem: MenuBarStatusItem.shared,
        onPauseAllAgents: {}
    )
    .previewDisplayName("Menu Bar Popover")
}
