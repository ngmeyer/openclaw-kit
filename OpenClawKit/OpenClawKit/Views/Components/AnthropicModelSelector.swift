import SwiftUI

// MARK: - Anthropic Model Information
struct AnthropicModel: Identifiable {
    let id: String
    let name: String
    let fullId: String
    let description: String
    let useCase: String
    let costNote: String
    let contextWindow: String
    
    static let models: [AnthropicModel] = [
        AnthropicModel(
            id: "haiku",
            name: "Claude Haiku",
            fullId: "anthropic/claude-haiku-4-5",
            description: "Fastest and most affordable Claude model",
            useCase: "General tasks, quick responses, high volume",
            costNote: "💰 Most economical - Recommended for OpenClawKit default",
            contextWindow: "200K tokens"
        ),
        AnthropicModel(
            id: "sonnet",
            name: "Claude Sonnet",
            fullId: "anthropic/claude-sonnet-4-5",
            description: "Balanced intelligence and speed",
            useCase: "Complex tasks, code generation, analysis",
            costNote: "💳 Mid-tier pricing",
            contextWindow: "200K tokens"
        ),
        AnthropicModel(
            id: "opus",
            name: "Claude Opus",
            fullId: "anthropic/claude-opus-4-5",
            description: "Most capable Claude model",
            useCase: "Advanced reasoning, difficult problems",
            costNote: "⭐ Best for complex tasks (fallback)",
            contextWindow: "200K tokens"
        )
    ]
}

// MARK: - Model Selection Card
struct ModelSelectionCard: View {
    let model: AnthropicModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with selection indicator
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(model.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    } else {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Details
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(icon: "target", label: "Best for", value: model.useCase)
                    DetailRow(icon: "dollarsign.circle.fill", label: "Pricing", value: model.costNote)
                    DetailRow(icon: "filebadge", label: "Context", value: model.contextWindow)
                }
                .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.15) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                .frame(width: 16)
            
            Text(label)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .foregroundColor(.white)
                .lineLimit(2)
        }
    }
}

// MARK: - Anthropic Connection Guide
struct AnthropicConnectionGuide: View {
    @ObservedObject var viewModel: SetupWizardViewModel
    @State private var selectedModel = AnthropicModel.models[0] // Default to Haiku
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anthropic Claude")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Powerful AI with flexible pricing")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Text("Choose your preferred Claude model based on your needs and budget")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Model Selection
            GlassCard(cornerRadius: 16, padding: 0) {
                VStack(spacing: 0) {
                    Text("Available Models")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(spacing: 12) {
                        ForEach(AnthropicModel.models) { model in
                            ModelSelectionCard(
                                model: model,
                                isSelected: selectedModel.id == model.id,
                                action: { selectedModel = model }
                            )
                        }
                    }
                    .padding(20)
                }
            }
            
            // API Key Setup
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        Text("Get Your API Key")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
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
                    
                    Text("2. Sign in (or create account)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text("3. Go to API Keys section")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text("4. Click 'Create Key' and copy it")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text("5. Paste below")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    // API Key input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paste your Anthropic API Key")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
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
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                        Text("Your API key is stored locally and never sent anywhere")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Pricing Info
            GlassCard(cornerRadius: 16, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        Text("Pricing & Billing")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text("Anthropic offers pay-as-you-go pricing. You only pay for what you use.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        PricingInfo(model: "Claude Haiku", example: "$0.80 per million input tokens")
                        PricingInfo(model: "Claude Sonnet", example: "$3 per million input tokens")
                        PricingInfo(model: "Claude Opus", example: "$15 per million input tokens")
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                    
                    Text("💡 Pro Tip: OpenClawKit defaults to Haiku for cost-efficiency while maintaining quality")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(12)
                        .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct PricingInfo: View {
    let model: String
    let example: String
    
    var body: some View {
        HStack {
            Text(model)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            Spacer()
            Text(example)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
