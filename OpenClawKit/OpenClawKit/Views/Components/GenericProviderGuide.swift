import SwiftUI

// MARK: - Generic Provider Guide (for DeepSeek, OpenAI)
struct GenericProviderGuide: View {
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
                        Text(viewModel.selectedProvider.pricingNote)
                            .font(.caption)
                            .foregroundColor(viewModel.selectedProvider.isLowCost ? .orange : Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Visit \(viewModel.selectedProvider.rawValue) Platform")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if let url = URL(string: viewModel.selectedProvider.apiKeyURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text("Open \(viewModel.selectedProvider.rawValue)")
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
                        
                        Text("5. Create a new API key and copy it")
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
                        Text("Stored locally in macOS Keychain and never sent to our servers")
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
            .frame(maxWidth: .infinity, alignment: .leading)

            // Why [Provider]? section
            providerBenefitsCard
        }
    }
    
    @ViewBuilder
    private var providerBenefitsCard: some View {
        switch viewModel.selectedProvider {
        case .deepseek:
            deepSeekBenefitsCard
        case .openAI:
            openAIBenefitsCard
        default:
            EmptyView()
        }
    }
    
    private var deepSeekBenefitsCard: some View {
        GlassCard(cornerRadius: 16, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    Text("Why DeepSeek?")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    BenefitRow(icon: "dollarsign.circle", text: "Extremely low pricing — great for high-volume use")
                    BenefitRow(icon: "cpu", text: "DeepSeek V3 matches GPT-4 quality at fraction of cost")
                    BenefitRow(icon: "globe", text: "Strong performance on coding and reasoning tasks")
                    BenefitRow(icon: "bolt.fill", text: "Fast inference with efficient model architecture")
                    BenefitRow(icon: "checkmark.shield", text: "Reliable uptime and consistent performance")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                
                HStack(alignment: .top, spacing: 8) {
                    Text("💡")
                    Text("Best choice if you want top-tier AI at the lowest cost")
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
    
    private var openAIBenefitsCard: some View {
        GlassCard(cornerRadius: 16, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    Text("Why OpenAI?")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    BenefitRow(icon: "sparkles", text: "GPT-4o: Most capable multimodal model")
                    BenefitRow(icon: "message", text: "Excellent conversation and instruction following")
                    BenefitRow(icon: "doc.text", text: "Strong document analysis and summarization")
                    BenefitRow(icon: "globe", text: "Broad ecosystem and third-party integrations")
                    BenefitRow(icon: "checkmark.shield", text: "Proven reliability and enterprise support")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                
                HStack(alignment: .top, spacing: 8) {
                    Text("💡")
                    Text("Choose OpenAI if you want the most mature platform with widest support")
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

// MARK: - Previews
#Preview("DeepSeek Guide") {
    GenericProviderGuide(viewModel: DeepSeekPreviewViewModel())
        .frame(width: 450)
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}

#Preview("OpenAI Guide") {
    GenericProviderGuide(viewModel: OpenAIPreviewViewModel())
        .frame(width: 450)
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}

// MARK: - Preview Helpers
private class DeepSeekPreviewViewModel: SetupWizardViewModel {
    override init() {
        super.init()
        self.apiKey = ""
        self.selectedProvider = .deepseek
    }
}

private class OpenAIPreviewViewModel: SetupWizardViewModel {
    override init() {
        super.init()
        self.apiKey = ""
        self.selectedProvider = .openAI
    }
}
