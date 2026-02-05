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
            parent.onNavigationError?(error)
        }
    }
}

// MARK: - OpenClaw Browser View
struct OpenClawBrowserView: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    @State private var isWebViewLoading = true
    @State private var connectionError: String?
    @State private var retryCount = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            if let error = connectionError {
                // Connection error state
                VStack(spacing: 24) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)
                    
                    Text("Connecting to OpenClaw...")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Button("Retry Connection") {
                        connectionError = nil
                        retryCount += 1
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                }
                .padding(40)
            } else if OpenClawKitApp.isDemoMode {
                // Demo mode placeholder
                VStack(spacing: 24) {
                    Image(systemName: "play.display")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.bluePrimary, .blueLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("OpenClaw Interface")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Demo Mode Active")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("In production, this view displays the OpenClaw chat interface\nrunning at \(viewModel.defaultGatewayURL)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical)
                    
                    // Demo chat mockup
                    GlassCard(cornerRadius: 16, padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("OpenClaw is running")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Text("You can now chat with your AI assistant through this interface, or connect messaging channels like Telegram, Discord, and more.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: 500)
                }
                .padding(40)
            } else {
                // Actual WebView
                WebView(
                    url: URL(string: viewModel.defaultGatewayURL)!,
                    isLoading: $isWebViewLoading,
                    onNavigationError: { error in
                        connectionError = "Could not connect to OpenClaw gateway.\n\(error.localizedDescription)"
                    }
                )
                .id(retryCount) // Force reload on retry
                
                // Loading overlay
                if isWebViewLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading OpenClaw...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7))
                }
            }
        }
    }
}
