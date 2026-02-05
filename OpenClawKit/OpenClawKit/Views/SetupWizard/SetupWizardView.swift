import SwiftUI

struct SetupWizardView: View {
    @StateObject private var viewModel = SetupWizardViewModel()
    
    var body: some View {
        Group {
            switch viewModel.appMode {
            case .setup:
                SetupWizardContent(viewModel: viewModel)
            case .running:
                OpenClawBrowserView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 900, minHeight: 750)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Setup Wizard Content
struct SetupWizardContent: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
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
                            case .skillsSetup:
                                SkillsSetupStepView(viewModel: viewModel)
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
        case .skillsSetup: return "Continue"
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
        VStack(spacing: 24) {
            // Hero section
            VStack(spacing: 12) {
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
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.coralAccent, .coralLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Activate Your License")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Enter your license key to unlock OpenClawKit")
                    .font(.body)
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
        VStack(spacing: 28) {
            // Hero section
            VStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.bluePrimary, .blueLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Welcome to OpenClawKit")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your personal AI assistant, running locally on your Mac")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Setup steps preview (matches wizard order)
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(spacing: 0) {
                    SetupPreviewRow(
                        number: "1",
                        icon: "arrow.down.circle.fill",
                        title: "Install OpenClaw",
                        description: "Core engine and dependencies",
                        isLast: false
                    )
                    SetupPreviewRow(
                        number: "2",
                        icon: "puzzlepiece.fill",
                        title: "Configure Skills",
                        description: "Weather, notes, reminders, and more",
                        isLast: false
                    )
                    SetupPreviewRow(
                        number: "3",
                        icon: "brain.head.profile",
                        title: "Connect AI Provider",
                        description: "Claude, GPT-4, or Gemini",
                        isLast: false
                    )
                    SetupPreviewRow(
                        number: "4",
                        icon: "message.fill",
                        title: "Add Channels",
                        description: "Telegram, Discord, Slack (optional)",
                        isLast: true
                    )
                }
            }
            .frame(maxWidth: 420)
        }
    }
}

struct SetupPreviewRow: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Step number
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    
                    Text(number)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                }
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(.vertical, 14)
            
            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.1))
            }
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
    
    private var hasStarted: Bool {
        viewModel.isLoading || viewModel.installationProgress > 0
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Install OpenClaw")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(hasStarted ? viewModel.installationStatus : "Ready to install OpenClaw and dependencies")
                .foregroundColor(.white.opacity(0.7))
            
            // Progress bar and components
            GlassCard(cornerRadius: 16, padding: 24) {
                VStack(spacing: 20) {
                    // Progress bar (always visible)
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                                Color(red: 0.6, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * viewModel.installationProgress, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.installationProgress)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(Int(viewModel.installationProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Placeholder or component list
                    if viewModel.installedComponents.isEmpty {
                        // Placeholder before installation starts
                        VStack(spacing: 16) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Click Install to begin")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(height: 120)
                        
                        Button(action: {
                            viewModel.startInstallation()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Install Now")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: true))
                    } else {
                        // Progressive component list
                        VStack(spacing: 12) {
                            ForEach(viewModel.installedComponents) { component in
                                ComponentRow(component: component)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .animation(.easeOut(duration: 0.25), value: viewModel.installedComponents.count)
                    }
                }
            }
            .frame(maxWidth: 450)
        }
    }
}

struct ComponentRow: View {
    let component: InstalledComponent
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            Group {
                switch component.status {
                case .pending:
                    Image(systemName: "circle")
                        .foregroundColor(.white.opacity(0.3))
                case .installing:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                case .installed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(component.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
    
    private var statusText: String {
        switch component.status {
        case .pending:
            return "Waiting..."
        case .installing:
            return "Installing..."
        case .installed:
            return component.location
        case .failed(let message):
            return message
        }
    }
    
    private var statusColor: Color {
        switch component.status {
        case .pending: return .white.opacity(0.4)
        case .installing: return .white.opacity(0.6)
        case .installed: return .green.opacity(0.8)
        case .failed: return .red.opacity(0.8)
        }
    }
}

// MARK: - Skills Setup Step
struct SkillsSetupStepView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    private var selectedSkill: SkillInfo? {
        viewModel.selectedSkills.first { $0.id == viewModel.selectedSkillId }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Included Skills")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Select a skill to learn more")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .top, spacing: 20) {
                // Skills list (left)
                GlassCard(cornerRadius: 16, padding: 16) {
                    VStack(spacing: 8) {
                        ForEach(viewModel.selectedSkills) { skill in
                            SkillListRow(
                                skill: skill,
                                isSelected: skill.id == viewModel.selectedSkillId,
                                action: { viewModel.selectedSkillId = skill.id }
                            )
                        }
                    }
                }
                .frame(width: 200)
                
                // Skill detail panel (right)
                if let skill = selectedSkill {
                    SkillDetailPanel(
                        skill: skill,
                        userLocation: $viewModel.userLocation,
                        isDetectingLocation: viewModel.isDetectingLocation
                    )
                }
            }
        }
    }
}

struct SkillListRow: View {
    let skill: SkillInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: skill.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .frame(width: 22)
                
                Text(skill.name)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SkillDetailPanel: View {
    let skill: SkillInfo
    @Binding var userLocation: String
    let isDetectingLocation: Bool
    
    var body: some View {
        GlassCard(cornerRadius: 16, padding: 24) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: skill.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(skill.name)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Text(skill.tagline)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Description
                Text(skill.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                
                // Weather-specific: Location input
                if skill.id == "weather" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Location")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack {
                            TextField("ZIP or City, State", text: $userLocation)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            if isDetectingLocation {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                        }
                        
                        Text("Optional — say \"weather in [city]\" anytime")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // Example commands
                VStack(alignment: .leading, spacing: 10) {
                    Text("Try saying")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(skill.exampleCommands, id: \.self) { command in
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                                
                                Text("\"\(command)\"")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .italic()
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: 340)
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
                                            } else if provider.isLowCost {
                                                Text("LOW COST")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.orange)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.orange.opacity(0.2))
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
                            
                            // Validation message
                            if viewModel.apiKey.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("An API key is required to continue")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding(.top, 4)
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
                        label: "Skills",
                        value: {
                            let enabled = viewModel.selectedSkills.filter { $0.isEnabled }
                            return enabled.isEmpty ? "None" : enabled.map { $0.name }.joined(separator: ", ")
                        }()
                    )
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
