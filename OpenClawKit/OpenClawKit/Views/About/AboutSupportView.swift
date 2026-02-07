import SwiftUI

// MARK: - About/Support Window View
struct AboutSupportView: View {
    @StateObject private var viewModel = AboutSupportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                AboutSupportHeader(dismiss: dismiss)
                
                // Tab Bar
                TabBarView(selectedTab: $viewModel.selectedTab)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch viewModel.selectedTab {
                        case .about:
                            AboutTabView(viewModel: viewModel)
                        case .license:
                            LicenseTabView(viewModel: viewModel)
                        case .support:
                            SupportTabView(viewModel: viewModel)
                        case .advanced:
                            AdvancedTabView(viewModel: viewModel)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(width: 600, height: 680)
        .preferredColorScheme(.dark)
        // Sheets
        .sheet(isPresented: $viewModel.showChangeLicenseSheet) {
            ChangeLicenseSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showUninstallProgress) {
            UninstallProgressSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Header
struct AboutSupportHeader: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("OpenClawKit")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Note: macOS provides default close button on window
            // No custom close button needed
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.5))
    }
}

// MARK: - Tab Bar
struct TabBarView: View {
    @Binding var selectedTab: AboutSupportViewModel.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AboutSupportViewModel.Tab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.rawValue,
                    icon: tab.icon,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - About Tab
struct AboutTabView: View {
    @ObservedObject var viewModel: AboutSupportViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon and Info
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 4) {
                    Text(viewModel.appName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Version \(viewModel.appVersion) (\(viewModel.buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Description
            Text("OpenClawKit is the official installer and companion app for OpenClaw — your personal AI agent platform that runs locally on your Mac.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Links
            GlassCard(cornerRadius: 12, padding: 16) {
                VStack(spacing: 12) {
                    LinkRow(
                        icon: "globe",
                        title: "Website",
                        subtitle: "openclawkit.ai",
                        action: viewModel.openWebsite
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    LinkRow(
                        icon: "envelope.fill",
                        title: "Support Email",
                        subtitle: viewModel.supportEmail,
                        action: viewModel.openSupportEmail
                    )
                }
            }
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Copyright
            VStack(spacing: 8) {
                Text(viewModel.copyrightText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                
                Text("Built with ❤️ for the AI community")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}

struct LinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - License Tab
struct LicenseTabView: View {
    @ObservedObject var viewModel: AboutSupportViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // License Status Card
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("License Status")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(viewModel.licenseStatusColor)
                                    .frame(width: 10, height: 10)
                                
                                Text(viewModel.licenseStatusText)
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.licenseStatusColor)
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.isProcessingLicense {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // License Key
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("License Key")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(viewModel.maskedLicenseKey)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: { viewModel.showLicenseKey.toggle() }) {
                            Image(systemName: viewModel.showLicenseKey ? "eye.slash" : "eye")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Activation Date
                    if let activationDate = viewModel.activationDate {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Activated On")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(activationDate)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Customer Email
                    if let email = viewModel.licenseService.customerEmail {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Registered To")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: 450)
            
            // License Message
            if let message = viewModel.licenseMessage {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.licenseMessageIsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(viewModel.licenseMessageIsError ? .red : .green)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(viewModel.licenseMessageIsError ? .red : .green)
                }
            }
            
            // Actions
            HStack(spacing: 16) {
                Button(action: {
                    Task { await viewModel.validateLicense() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Verify")
                    }
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(viewModel.isProcessingLicense || !viewModel.licenseService.isLicensed)
                
                Button(action: { viewModel.showChangeLicenseSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                        Text("Change License")
                    }
                }
                .buttonStyle(GlassButtonStyle())
                
                Button(action: {
                    Task { await viewModel.deactivateLicense() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("Deactivate")
                    }
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(viewModel.isProcessingLicense || !viewModel.licenseService.isLicensed)
            }
            
            Spacer()
            
            // Purchase Link
            if !viewModel.licenseService.isLicensed {
                VStack(spacing: 8) {
                    Text("Don't have a license?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button(action: {
                        if let url = URL(string: LicenseService.checkoutURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "cart.fill")
                            Text("Purchase OpenClawKit - $49.99")
                        }
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                }
            }
        }
    }
}

// MARK: - Support Tab
struct SupportTabView: View {
    @ObservedObject var viewModel: AboutSupportViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // System Information
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("System Information")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            Task { await viewModel.loadSupportInfo() }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    if viewModel.isLoadingInfo {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Spacer()
                        }
                        .padding()
                    } else if let info = viewModel.systemInfo {
                        SystemInfoGrid(info: info)
                    }
                }
            }
            
            // Gateway Controls
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Gateway Status")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(viewModel.systemInfo?.gatewayStatus == .running ? .green : .red)
                                .frame(width: 10, height: 10)
                            
                            Text(viewModel.systemInfo?.gatewayStatus.rawValue ?? "Unknown")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        Button(action: { Task { await viewModel.startGateway() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(viewModel.systemInfo?.gatewayStatus == .running)
                        
                        Button(action: { Task { await viewModel.stopGateway() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(viewModel.systemInfo?.gatewayStatus == .stopped)
                        
                        Button(action: { Task { await viewModel.restartGateway() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Restart")
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
            }
            
            // Debug Actions
            HStack(spacing: 16) {
                Button(action: {
                    Task { await viewModel.copyDebugInfo() }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isCopying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "doc.on.doc.fill")
                        }
                        Text(viewModel.isCopying ? "Copied!" : "Copy Debug Info")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                
                Button(action: {
                    Task { await viewModel.exportLogs() }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "square.and.arrow.up.fill")
                        }
                        Text(viewModel.exportSuccess ? "Exported!" : "Export Logs")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            
            // Recent Logs Preview
            if !viewModel.recentLogs.isEmpty {
                GlassCard(cornerRadius: 12, padding: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Logs")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.recentLogs.prefix(10)) { entry in
                                    Text(entry.message)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(height: 100)
                    }
                }
            }
        }
    }
}

struct SystemInfoGrid: View {
    let info: LogCollectorService.SystemInfo
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            InfoCell(label: "macOS", value: "\(info.macOSVersion)")
            InfoCell(label: "Architecture", value: info.architecture)
            InfoCell(label: "OpenClawKit", value: "\(info.openClawKitVersion)")
            InfoCell(label: "OpenClaw", value: info.openClawVersion ?? "Not installed")
            InfoCell(label: "Node.js", value: info.nodeVersion ?? "Not installed")
            InfoCell(label: "Gateway Port", value: "\(info.gatewayPort)")
        }
    }
}

struct InfoCell: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Advanced Tab
struct AdvancedTabView: View {
    @ObservedObject var viewModel: AboutSupportViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Reset Options
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reset Options")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("These actions cannot be undone. Please proceed with caution.")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    ResetOptionRow(
                        icon: "slider.horizontal.3",
                        title: "Reset Preferences",
                        description: "Clears all app preferences and settings",
                        buttonTitle: "Reset",
                        isDestructive: false,
                        action: { viewModel.showResetPrefsConfirm = true }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    ResetOptionRow(
                        icon: "key.slash",
                        title: "Clear License",
                        description: "Deactivates and removes license from this device",
                        buttonTitle: "Clear",
                        isDestructive: true,
                        action: { viewModel.showClearLicenseConfirm = true }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    ResetOptionRow(
                        icon: "arrow.counterclockwise",
                        title: "Reset to First Launch",
                        description: "Clears all data and returns to setup wizard",
                        buttonTitle: "Reset All",
                        isDestructive: true,
                        action: { viewModel.showResetAllConfirm = true }
                    )
                }
            }
            
            // Reset Message
            if let message = viewModel.resetMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Uninstall Section
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Uninstall OpenClawKit")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text("This will remove OpenClawKit, OpenClaw, and all configuration files. Node.js and Homebrew will be left intact.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button(action: { viewModel.showUninstallConfirm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Uninstall")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
        }
        // Confirmation Alerts
        .alert("Reset Preferences?", isPresented: $viewModel.showResetPrefsConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetPreferences()
            }
        } message: {
            Text("This will reset all OpenClawKit preferences to their default values.")
        }
        .alert("Clear License?", isPresented: $viewModel.showClearLicenseConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task { await viewModel.clearLicense() }
            }
        } message: {
            Text("This will deactivate your license on this device. You can reactivate it later.")
        }
        .alert("Reset to First Launch?", isPresented: $viewModel.showResetAllConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All", role: .destructive) {
                Task { await viewModel.resetToFirstLaunch() }
            }
        } message: {
            Text("This will clear all preferences and license data. The app will restart with the setup wizard.")
        }
        .alert("Uninstall OpenClawKit?", isPresented: $viewModel.showUninstallConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall", role: .destructive) {
                Task { await viewModel.startUninstall() }
            }
        } message: {
            Text("This will remove OpenClawKit, OpenClaw, configuration files, and license data. This cannot be undone.")
        }
    }
}

struct ResetOptionRow: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let isDestructive: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isDestructive ? .orange : Color(red: 0.4, green: 0.6, blue: 1.0))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if isDestructive {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(DestructiveButtonStyle())
            } else {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }
}

// MARK: - Change License Sheet
struct ChangeLicenseSheet: View {
    @ObservedObject var viewModel: AboutSupportViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Enter License Key")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Sheet uses Cancel button for dismissal, no X needed
                }
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("XXXX-XXXX-XXXX-XXXX", text: $viewModel.newLicenseKey)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isFocused)
                    
                    if let message = viewModel.licenseMessage, viewModel.licenseMessageIsError {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(GlassButtonStyle())
                    
                    Button(action: {
                        Task { await viewModel.activateNewLicense() }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isProcessingLicense {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                            Text("Activate")
                        }
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                    .disabled(viewModel.newLicenseKey.isEmpty || viewModel.isProcessingLicense)
                }
            }
            .padding(24)
        }
        .frame(width: 400, height: 200)
        .onAppear { isFocused = true }
    }
}

// MARK: - Uninstall Progress Sheet
struct UninstallProgressSheet: View {
    @ObservedObject var viewModel: AboutSupportViewModel
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("Uninstalling OpenClawKit")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }
                
                // Progress
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.uninstallService.uninstallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    
                    Text(viewModel.uninstallService.currentStep)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Steps
                GlassCard(cornerRadius: 12, padding: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.uninstallService.completedSteps) { step in
                            HStack(spacing: 12) {
                                Image(systemName: step.success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(step.success ? .green : .orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                    
                                    Text(step.detail)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                }
                
                if !viewModel.uninstallService.isUninstalling && viewModel.uninstallService.uninstallProgress >= 1.0 {
                    VStack(spacing: 12) {
                        Text("Uninstall complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("The app will close shortly.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 450, height: 400)
        .interactiveDismissDisabled(viewModel.uninstallService.isUninstalling)
    }
}

// MARK: - Destructive Button Style
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.8))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    AboutSupportView()
}
