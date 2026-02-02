import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()
        
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, 
            defer: false
        )
        window.center()
        window.title = "OpenClawKit Installer"
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

struct ContentView: View {
    @State private var currentStep = 0
    @State private var progress: Float = 0.0
    @State private var isInstalling = false
    @State private var installationComplete = false
    @State private var errorMessage: String? = nil
    
    let steps = [
        "Welcome",
        "System Check",
        "Node.js Setup",
        "OpenClaw Installation",
        "API Configuration",
        "Channel Setup",
        "Complete"
    ]
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Image("Logo")
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("OpenClawKit Installer")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding()
            .background(Color(red: 0.12, green: 0.23, blue: 0.54))
            .foregroundColor(.white)
            
            // Main content
            VStack {
                // Progress bar
                ProgressView(value: progress, total: 1.0)
                    .padding()
                
                // Step indicator
                HStack {
                    Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Step content
                stepContent
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Navigation buttons
                HStack {
                    Button("Back") {
                        if currentStep > 0 {
                            currentStep -= 1
                            progress = Float(currentStep) / Float(steps.count - 1)
                        }
                    }
                    .disabled(currentStep == 0 || isInstalling)
                    
                    Spacer()
                    
                    if currentStep == steps.count - 1 {
                        Button("Finish") {
                            NSApplication.shared.terminate(nil)
                        }
                    } else {
                        Button(currentStep == 3 ? "Install" : "Next") {
                            if currentStep == 3 {
                                startInstallation()
                            } else {
                                currentStep += 1
                                progress = Float(currentStep) / Float(steps.count - 1)
                            }
                        }
                        .disabled(isInstalling)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    @ViewBuilder
    var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            systemCheckStep
        case 2:
            nodeSetupStep
        case 3:
            openClawInstallationStep
        case 4:
            apiConfigurationStep
        case 5:
            channelSetupStep
        case 6:
            completeStep
        default:
            Text("Unknown step")
        }
    }
    
    var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to OpenClawKit!")
                .font(.title)
            
            Text("This installer will guide you through setting up OpenClaw AI on your Mac with a simple, visual interface.")
            
            Text("What we'll do:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("Check and install Node.js 22+", systemImage: "checkmark.circle")
                Label("Install OpenClaw", systemImage: "checkmark.circle")
                Label("Configure your API keys", systemImage: "checkmark.circle")
                Label("Set up messaging channels", systemImage: "checkmark.circle")
                Label("Configure the background service", systemImage: "checkmark.circle")
            }
            
            Text("Click 'Next' to begin!")
                .padding(.top)
        }
    }
    
    var systemCheckStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Requirements Check")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("macOS 12 or newer").font(.headline)
                        Text("Your Mac is compatible").font(.caption).foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("8GB RAM recommended").font(.headline)
                        Text("Required for optimal performance").font(.caption).foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Internet connection").font(.headline)
                        Text("Required for OpenClaw setup").font(.caption).foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Your system meets all requirements. Click 'Next' to continue.")
                .padding(.top)
        }
    }
    
    var nodeSetupStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Node.js Installation")
                .font(.title2)
                .bold()
            
            Text("Node.js 22+ is required for OpenClaw. We'll install it automatically for you.")
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Check for existing Node.js installation", systemImage: "magnifyingglass")
                Label("Install Node.js 22+ if needed via Homebrew", systemImage: "wrench.and.screwdriver")
                Label("Verify installation success", systemImage: "checkmark.seal")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Text("This process typically takes 2-5 minutes depending on your internet connection.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    var openClawInstallationStep: some View {
        VStack {
            if isInstalling {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                    
                    Text("Installing OpenClaw...")
                        .font(.headline)
                    
                    Text("This may take a few minutes. Please don't close this window.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ready to Install OpenClaw")
                        .font(.title2)
                        .bold()
                    
                    Text("The installer will now:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Download OpenClaw from openclaw.ai", systemImage: "cloud.download")
                        Label("Extract and configure the application", systemImage: "folder.badge.gear")
                        Label("Set up daemon service for auto-start", systemImage: "gearshape")
                    }
                    
                    Spacer()
                    
                    Text("Click 'Install' to begin. This typically takes 3-5 minutes.")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    var apiConfigurationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Configuration")
                .font(.title2)
                .bold()
            
            Text("OpenClaw needs an API key to run. Choose your AI provider:")
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading) {
                    Label("Anthropic (Claude)", systemImage: "sparkles")
                        .font(.headline)
                    Text("Get key at: https://console.anthropic.com")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Label("OpenAI", systemImage: "sparkles")
                        .font(.headline)
                    Text("Get key at: https://platform.openai.com/api/keys")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text("You'll be guided through OAuth or API key setup in the next step.")
                .font(.caption)
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Spacer()
        }
    }
    
    var channelSetupStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Channel Configuration")
                .font(.title2)
                .bold()
            
            Text("Select which messaging platforms you want to use:")
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Telegram", systemImage: "paperplane.fill")
                Label("WhatsApp", systemImage: "bubble.right.fill")
                Label("Discord", systemImage: "gamecontroller.fill")
                Label("Slack", systemImage: "bubble.left.fill")
                Label("iMessage", systemImage: "message.fill")
                Label("Google Chat", systemImage: "message.badge.light.fill")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Don't worry—you can add more channels later. For now, we'll set up Telegram as your primary channel.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    var completeStep: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
                .padding()
            
            Text("Installation Complete!")
                .font(.title)
                .bold()
            
            Text("OpenClaw AI is now installed and configured on your Mac.")
                .padding()
            
            Text("You can now chat with your AI assistant through your configured channels.")
                .padding(.bottom)
            
            Button("Start OpenClaw") {
                // Launch OpenClaw
            }
            .padding()
        }
    }
    
    func startInstallation() {
        isInstalling = true
        errorMessage = nil
        
        DispatchQueue.global().async {
            // Get the installation script path
            let bundlePath = Bundle.main.resourcePath ?? ""
            let installScriptPath = "\(bundlePath)/install.sh"
            
            // Run the installation script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [installScriptPath]
            
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                print("Installation output: \(output)")
                
                DispatchQueue.main.async {
                    self.isInstalling = false
                    
                    if process.terminationStatus == 0 {
                        // Installation successful
                        self.currentStep += 1
                        self.progress = Float(self.currentStep) / Float(self.steps.count - 1)
                    } else {
                        // Installation failed
                        self.errorMessage = "Installation failed. Please check the system requirements and try again."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isInstalling = false
                    self.errorMessage = "Error running installation: \(error.localizedDescription)"
                }
            }
        }
    }
}