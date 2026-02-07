import SwiftUI

// MARK: - OpenRouter Connection Guide
@MainActor
struct OpenRouterConnectionGuide: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    @State private var isVerifying = false
    @State private var verificationStatus: VerificationStatus = .idle
    
    enum VerificationStatus {
        case idle
        case verifying
        case success
        case failed(String)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Instructions card (first, like DeepSeek)
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("How to get your API key")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("🌐 One key, 100+ models")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Visit OpenRouter and sign up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if let url = URL(string: "https://openrouter.ai/keys") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text("Open OpenRouter")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: true))
                        
                        Text("2. Sign in with GitHub or Google")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("3. Add billing information (pay-as-you-go)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("4. Go to API Keys and click 'Create Key'")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("5. Copy the key (starts with sk-or-v1-...)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // API Key input (second, like DeepSeek)
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste your API Key")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        SecureField("sk-or-v1-...", text: $viewModel.apiKey)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                        
                        if !viewModel.apiKey.isEmpty {
                            DebouncedButton(action: verifyAPIKey) {
                                HStack(spacing: 4) {
                                    if isVerifying {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Image(systemName: "checkmark.shield")
                                    }
                                    Text(isVerifying ? "Verifying..." : "Verify")
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isVerifying)
                        }
                    }
                    
                    // Verification status
                    if case .failed(let error) = verificationStatus {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    } else if case .success = verificationStatus {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API key verified successfully!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 4)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                        Text("Stored locally in macOS Keychain and never leaves this device")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                    
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
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Why OpenRouter? (benefits section)
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        Text("Why OpenRouter?")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        BenefitRow(icon: "key.fill", text: "One API key for 100+ models")
                        BenefitRow(icon: "arrow.left.arrow.right", text: "Switch models instantly without changing code")
                        BenefitRow(icon: "chart.bar", text: "Unified analytics and usage tracking")
                        BenefitRow(icon: "dollarsign.circle", text: "Competitive pricing across all providers")
                        BenefitRow(icon: "checkmark.shield", text: "Built-in fallbacks if a provider is down")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("💡")
                        Text("We've pre-configured Claude Haiku as your default model for the best balance of quality and cost")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.1))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var borderColor: Color {
        if viewModel.apiKey.isEmpty {
            return Color.white.opacity(0.1)
        }
        switch verificationStatus {
        case .success:
            return Color.green.opacity(0.5)
        case .failed:
            return Color.orange.opacity(0.5)
        default:
            return Color.green.opacity(0.3)
        }
    }
    
    func verifyAPIKey() {
        let capturedKey = viewModel.apiKey
        guard !capturedKey.isEmpty else { return }
        
        isVerifying = true
        verificationStatus = .verifying
        
        Task {
            guard capturedKey.hasPrefix("sk-or-v1-") else {
                await MainActor.run {
                    guard capturedKey == viewModel.apiKey else { return }
                    verificationStatus = .failed("Key format looks incorrect. OpenRouter keys start with 'sk-or-v1-'")
                    isVerifying = false
                }
                return
            }
            
            let isValid = await verifyWithOpenRouter(apiKey: capturedKey)
            
            await MainActor.run {
                guard capturedKey == viewModel.apiKey else { return }
                
                if isValid {
                    verificationStatus = .success
                } else {
                    verificationStatus = .failed("API key verification failed - check your key")
                }
                isVerifying = false
            }
        }
    }
    
    private func verifyWithOpenRouter(apiKey: String) async -> Bool {
        guard let url = URL(string: "https://openrouter.ai/api/v1/auth/key") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            print("🔑 [Verify] OpenRouter API check failed: \(error)")
            return false
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview("OpenRouter Guide") {
    OpenRouterConnectionGuide(viewModel: PreviewViewModel())
        .frame(width: 450)
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}

// MARK: - Preview Helper
private class PreviewViewModel: SetupWizardViewModel {
    override init() {
        super.init()
        // Override any persisted values for preview
        self.apiKey = ""
        self.selectedProvider = .openRouter
    }
}
