import SwiftUI

// MARK: - Anthropic Connection Guide
struct AnthropicConnectionGuide: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Instructions card
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("How to get your API key")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("💳 Pay-as-you-go")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Visit Anthropic Console")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if let url = URL(string: "https://console.anthropic.com/settings/keys") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text("Open Anthropic Console")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: true))
                        
                        Text("2. Sign in or create an account")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("3. Add billing information (pay-as-you-go)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("4. Go to API Keys section")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("5. Click 'Create Key' and copy it (starts with sk-ant-...)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // API Key input
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste your API Key")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    SecureField("sk-ant-...", text: $viewModel.apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.apiKey.isEmpty ? Color.white.opacity(0.1) : Color.green.opacity(0.5), lineWidth: 1)
                        )
                    
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

            // Why Anthropic? (benefits section)
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        Text("Why Anthropic?")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        BenefitRow(icon: "brain.head.profile", text: "Claude models excel at reasoning and analysis")
                        BenefitRow(icon: "doc.text", text: "200K token context window for long documents")
                        BenefitRow(icon: "code", text: "Strong code generation and technical tasks")
                        BenefitRow(icon: "shield.checkerboard", text: "Built with safety and alignment in mind")
                        BenefitRow(icon: "bolt.fill", text: "Fast response times with Haiku model")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("💡")
                        Text("Claude Haiku offers the best balance of speed and intelligence for most tasks")
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
}

// MARK: - Preview
#Preview("Anthropic Guide") {
    AnthropicConnectionGuide(viewModel: AnthropicPreviewViewModel())
        .frame(width: 450)
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}

// MARK: - Preview Helper
private class AnthropicPreviewViewModel: SetupWizardViewModel {
    override init() {
        super.init()
        self.apiKey = ""
        self.selectedProvider = .anthropic
    }
}
