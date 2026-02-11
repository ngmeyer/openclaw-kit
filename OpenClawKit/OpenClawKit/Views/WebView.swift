import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    var onNavigationError: ((Error) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Set a custom user agent to identify OpenClawKit
        webView.customUserAgent = "OpenClawKit/1.0 (macOS)"
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only load if URL changed or first load
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.onNavigationError?(error)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            
            let nsError = error as NSError
            print("⚠️ [WebView] Provisional navigation failed: \(error)")
            print("⚠️ [WebView] Error code: \(nsError.code), Domain: \(nsError.domain)")
            
            // -999 is NSURLErrorCancelled - often transient, don't treat as fatal
            if nsError.code == -999 {
                print("⚠️ [WebView] Got -999 (cancelled), will retry...")
                // Don't report this error - let the caller retry
                return
            }
            
            parent.onNavigationError?(error)
        }
    }
}

// MARK: - OpenClaw Browser View
struct OpenClawBrowserView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    @State private var isStartingGateway = true
    @State private var gatewayCheckAttempts = 0
    @State private var hasOpenedBrowser = false
    @State private var showPostInstallGuide = true
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            if showPostInstallGuide && !isStartingGateway {
                // Show post-install guide first
                PostInstallView(
                    onDismiss: {
                        showPostInstallGuide = false
                    },
                    onStartChatting: {
                        showPostInstallGuide = false
                        if let url = URL(string: viewModel.defaultGatewayURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            } else if isStartingGateway {
                // Show starting gateway state while we verify it's running
                StartingGatewayView()
            } else {
                // Show running state with browser button
                RunningView(viewModel: viewModel, hasOpenedBrowser: $hasOpenedBrowser)
            }
        }
        .onAppear {
            Task {
                await waitForGateway()
            }
        }
    }
    
    private func waitForGateway() async {
        let maxAttempts = 30 // 30 seconds max
        
        while gatewayCheckAttempts < maxAttempts {
            gatewayCheckAttempts += 1
            
            if await checkGatewayStatus() {
                isStartingGateway = false
                // Auto-open browser once gateway is ready
                if !hasOpenedBrowser {
                    hasOpenedBrowser = true
                    if let url = URL(string: viewModel.defaultGatewayURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
                return
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        // Timeout
        isStartingGateway = false
    }
    
    private func checkGatewayStatus() async -> Bool {
        guard let url = URL(string: "\(viewModel.defaultGatewayURL)/status") else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Gateway not ready yet
        }
        return false
    }
}

// MARK: - Running View (shows when gateway is active)
struct RunningView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    @Binding var hasOpenedBrowser: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
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
                Text("OpenClaw is Running")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your AI assistant is ready")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Status card
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .modifier(PulseAnimation())
                        
                        Text("Gateway active at \(viewModel.defaultGatewayURL)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    Text("The chat interface has been opened in your default browser. You can also connect via Telegram, Discord, or other configured channels.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 400)
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    if let url = URL(string: viewModel.defaultGatewayURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Open Chat in Browser")
                    }
                    .frame(maxWidth: 280)
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
                
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            _ = await runShellCommand("openclaw gateway stop")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                            Text("Stop Gateway")
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button(action: {
                        Task {
                            _ = await runShellCommand("openclaw gateway restart")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart")
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
            
            Spacer()
            
            // Tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tip: Bookmark the chat URL for quick access")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(40)
    }
    
    private func runShellCommand(_ command: String) async -> String? {
        await withCheckedContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-l", "-c", command]
            task.launchPath = "/bin/zsh"
            
            var env = ProcessInfo.processInfo.environment
            let homebrewPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin"
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(homebrewPaths):\(existingPath)"
            }
            task.environment = env
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                continuation.resume(returning: task.terminationStatus == 0 ? output : nil)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

// MARK: - Pulse Animation Modifier
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Starting Gateway View (P0: Shows while waiting for gateway)
struct StartingGatewayView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "network")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.bluePrimary, .blueLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Starting OpenClaw...")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Waiting for gateway to be ready")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
        }
        .padding(40)
    }
}
