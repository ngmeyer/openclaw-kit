import SwiftUI

struct SetupWizardView: View {
    @StateObject private var viewModel = SetupWizardViewModel()
    
    var body: some View {
        ZStack {
            // Animated background
            FloatingOrbsBackground()
            
            VStack(spacing: 0) {
                // Header with logo and progress
                HeaderView(viewModel: viewModel)
                
                // Main content area
                ScrollView {
                    VStack(spacing: 24) {
                        // Step content
                        Group {
                            switch viewModel.currentStep {
                            case .license:
                                LicenseStepView(viewModel: viewModel)
                            case .welcome:
                                WelcomeStepView(viewModel: viewModel)
                            case .systemCheck:
                                SystemCheckStepView(viewModel: viewModel)
                            case .installation:
                                InstallationStepView(viewModel: viewModel)
                            case .apiSetup:
                                APISetupStepView(viewModel: viewModel)
                            case .channelSetup:
                                ChannelSetupStepView(viewModel: viewModel)
                            case .complete:
                                CompleteStepView(viewModel: viewModel)
                            }
                        }
                        .frame(maxWidth: .infinity) // Push scrollbar to window edge
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    .padding(32)
                }
                
                // Navigation footer
                NavigationFooterView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 900, minHeight: 750)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header View
struct HeaderView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Logo
            HStack(spacing: 12) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("OpenClawKit")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 24)
            
            // Progress indicator
            StepProgressIndicator(
                steps: SetupStep.allCases,
                currentStep: viewModel.currentStep
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
        .background(.ultraThinMaterial.opacity(0.5))
    }
}

// MARK: - Navigation Footer
struct NavigationFooterView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                // Back button
                if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                    Button(action: viewModel.previousStep) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                
                Spacer()
                
                // Status message
                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Next/Continue button
                if viewModel.currentStep != .complete {
                    Button(action: viewModel.nextStep) {
                        HStack(spacing: 6) {
                            Text(nextButtonTitle)
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                    .disabled(!viewModel.canGoNext || viewModel.isLoading)
                    .opacity(viewModel.canGoNext && !viewModel.isLoading ? 1 : 0.5)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial.opacity(0.5))
        }
    }
    
    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .license: return "Activate"
        case .welcome: return "Get Started"
        case .systemCheck: return "Continue"
        case .installation: return "Continue"
        case .apiSetup: return "Continue"
        case .channelSetup: return "Finish Setup"
        case .complete: return ""
        }
    }
}

// MARK: - License Step
struct LicenseStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    @FocusState private var isLicenseFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Hero section
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.coralAccent.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.coralAccent, .coralLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Activate Your License")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Enter your license key to unlock OpenClawKit")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // License input
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("License Key")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("XXXX-XXXX-XXXX-XXXX", text: $viewModel.licenseKey)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isLicenseFieldFocused)
                        .onSubmit {
                            Task {
                                await viewModel.activateLicense()
                            }
                        }
                    
                    if let error = viewModel.licenseError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if viewModel.isLicenseValid {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("License activated successfully!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.activateLicense()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoading ? "Activating..." : "Activate License")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                    .disabled(viewModel.licenseKey.isEmpty || viewModel.isLoading)
                }
            }
            
            // Purchase link
            VStack(spacing: 12) {
                Text("Don't have a license?")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: {
                    if let url = URL(string: "https://openclawkit.lemonsqueezy.com/checkout/buy/7b279de2-56be-4f84-9049-e81c892b2bac") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Purchase OpenClawKit - $49.99")
                    }
                }
                .buttonStyle(GlassButtonStyle(isProminent: false))
            }
        }
        .onAppear {
            isLicenseFieldFocused = true
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Hero section
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.bluePrimary.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.bluePrimary, .blueLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Welcome to OpenClawKit")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your personal AI assistant, running locally on your Mac")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Feature cards
            GlassCard(cornerRadius: 16, padding: 24) {
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "Private & Secure",
                        description: "Everything runs locally on your Mac"
                    )
                    
                    FeatureRow(
                        icon: "message.fill",
                        title: "Multi-Channel",
                        description: "Connect to Telegram, Discord, Slack, and more"
                    )
                    
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Multiple AI Providers",
                        description: "Use Claude, GPT-4, Gemini, or local models"
                    )
                    
                    FeatureRow(
                        icon: "bolt.fill",
                        title: "Quick Setup",
                        description: "Up and running in under 5 minutes"
                    )
                }
            }
            .frame(maxWidth: 500)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.6, blue: 1.0),
                            Color(red: 0.6, green: 0.4, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

// MARK: - System Check Step
struct SystemCheckStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("System Requirements")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Let's make sure your Mac is ready for OpenClaw")
                .foregroundColor(.white.opacity(0.7))
            
            GlassCard(cornerRadius: 16, padding: 24) {
                VStack(spacing: 16) {
                    ForEach(viewModel.requirements) { req in
                        RequirementRow(requirement: req)
                    }
                }
            }
            .frame(maxWidth: 500)
            
            if !viewModel.systemCheckComplete && !viewModel.isLoading {
                Button("Run System Check") {
                    viewModel.runSystemCheck()
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
    }
}

struct RequirementRow: View {
    let requirement: SystemRequirement
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            Group {
                switch requirement.status {
                case .checking:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                case .passed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                case .warning:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
            .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(requirement.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
        }
    }
    
    private var statusText: String {
        switch requirement.status {
        case .checking:
            return "Checking..."
        case .passed:
            return requirement.description
        case .failed(let message):
            return message
        case .warning(let message):
            return message
        }
    }
    
    private var statusColor: Color {
        switch requirement.status {
        case .checking: return .white.opacity(0.5)
        case .passed: return .green.opacity(0.8)
        case .failed: return .red.opacity(0.8)
        case .warning: return .orange.opacity(0.8)
        }
    }
}

// MARK: - Installation Step
struct InstallationStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Install OpenClaw")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("We'll install OpenClaw and its dependencies")
                .foregroundColor(.white.opacity(0.7))
            
            GlassCard(cornerRadius: 16, padding: 32) {
                VStack(spacing: 24) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.installationProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.6, blue: 1.0),
                                        Color(red: 0.6, green: 0.4, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.installationProgress)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(viewModel.installationProgress * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(viewModel.installationStatus)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    if !viewModel.isLoading && !viewModel.isInstalled {
                        Button("Start Installation") {
                            viewModel.startInstallation()
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: true))
                    }
                    
                    if viewModel.isInstalled {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Installation Complete")
                                .foregroundColor(.green)
                        }
                        .font(.headline)
                    }
                }
            }
            .frame(maxWidth: 400)
        }
    }
}

// MARK: - API Setup Step
struct APISetupStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("AI Provider")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Choose your AI provider and get your API key")
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .top, spacing: 24) {
                // Provider selection (left side)
                GlassCard(cornerRadius: 16, padding: 20) {
                    VStack(spacing: 12) {
                        ForEach(AIProvider.allCases) { provider in
                            SelectionCard(
                                isSelected: viewModel.selectedProvider == provider,
                                action: { viewModel.selectedProvider = provider }
                            ) {
                                HStack(spacing: 16) {
                                    Image(systemName: provider.icon)
                                        .font(.title2)
                                        .foregroundColor(viewModel.selectedProvider == provider ? .white : .white.opacity(0.6))
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(provider.rawValue)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            if provider.isFree {
                                                Text("FREE")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.green)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Text(provider.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedProvider == provider {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 350)
                
                // Instructions and API Key (right side)
                VStack(spacing: 16) {
                    // Instructions card
                    GlassCard(cornerRadius: 16, padding: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("How to get your API key")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(viewModel.selectedProvider.pricingNote)
                                    .font(.caption)
                                    .foregroundColor(viewModel.selectedProvider.isFree ? .green : .orange)
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            Text(viewModel.selectedProvider.setupInstructions)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                            
                            Button(action: {
                                if let url = URL(string: viewModel.selectedProvider.apiKeyURL) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("Open \(viewModel.selectedProvider.rawValue) to get API key")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassButtonStyle(isProminent: true))
                        }
                    }
                    
                    // API Key input
                    GlassCard(cornerRadius: 16, padding: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Paste your API Key")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            SecureField("Enter your \(viewModel.selectedProvider.rawValue) API key", text: $viewModel.apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.apiKey.isEmpty ? Color.white.opacity(0.1) : Color.green.opacity(0.5), lineWidth: 1)
                                )
                            
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Stored locally and never sent to our servers")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .frame(maxWidth: 400)
            }
        }
    }
}

// MARK: - Channel Setup Step
struct ChannelSetupStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Messaging Channels")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Select the channels you want to connect (optional)")
                .foregroundColor(.white.opacity(0.7))
            
            GlassCard(cornerRadius: 16, padding: 20) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(MessagingChannel.allCases) { channel in
                        ChannelToggleCard(
                            channel: channel,
                            isSelected: viewModel.selectedChannels.contains(channel),
                            action: {
                                if viewModel.selectedChannels.contains(channel) {
                                    viewModel.selectedChannels.remove(channel)
                                } else {
                                    viewModel.selectedChannels.insert(channel)
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: 600)
            
            Text("You can configure additional channels later in the OpenClaw settings")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct ChannelToggleCard: View {
    let channel: MessagingChannel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: channel.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                    
                    Text(channel.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0) : .white.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.15) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Complete Step
struct CompleteStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Success animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.9, blue: 0.5),
                                Color(red: 0.2, green: 0.7, blue: 0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("OpenClaw is installed and configured")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: viewModel.launchOpenClaw) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Launch OpenClaw")
                    }
                    .frame(maxWidth: 280)
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
                
                Button(action: viewModel.openDocumentation) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                        Text("View Documentation")
                    }
                    .frame(maxWidth: 280)
                }
                .buttonStyle(GlassButtonStyle())
            }
            
            // Summary card
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configuration Summary")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    SummaryRow(label: "Gateway", value: viewModel.defaultGatewayURL)
                    SummaryRow(label: "AI Provider", value: viewModel.selectedProvider.rawValue)
                    SummaryRow(label: "Model", value: viewModel.selectedProvider.defaultModel)
                    SummaryRow(
                        label: "Channels",
                        value: viewModel.selectedChannels.isEmpty 
                            ? "None configured" 
                            : viewModel.selectedChannels.map { $0.rawValue }.joined(separator: ", ")
                    )
                }
            }
            .frame(maxWidth: 400)
            
            // Pro Tips from Alex Finn
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.coralAccent)
                        Text("Pro Tips")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ProTipRow(
                            tip: "Master the Onboarding",
                            detail: "Tell your AI everything about yourself, goals, and work style"
                        )
                        ProTipRow(
                            tip: "Give the Proactive Mandate",
                            detail: "Explicitly grant permission for it to take initiative"
                        )
                        ProTipRow(
                            tip: "Interview Your Bot",
                            detail: "Ask: 'What are 10 things you can do for me I haven't thought of?'"
                        )
                        ProTipRow(
                            tip: "Use Model Fallbacks",
                            detail: "Your config includes automatic fallback to cheaper models"
                        )
                    }
                }
            }
            .frame(maxWidth: 400)
        }
    }
}

struct ProTipRow: View {
    let tip: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("• \(tip)")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            Text(detail)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview
#Preview {
    SetupWizardView()
        .frame(width: 800, height: 700)
}
