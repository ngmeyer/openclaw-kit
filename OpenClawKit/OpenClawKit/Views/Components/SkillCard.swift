import SwiftUI

struct SkillCard: View {
    let skill: Skill
    let installationStatus: InstallationStatus
    let onInstall: () -> Void
    let onUpdate: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and name
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.bluePrimary, .blueLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: skill.icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(skill.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(skill.author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status badges
                    if skill.isInstalled {
                        if skill.hasUpdate {
                            Badge(text: "Update", color: .coralAccent)
                        } else {
                            Badge(text: "Installed", color: .green)
                        }
                    }
                }
                
                // Description
                Text(skill.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Stats row
                HStack(spacing: 16) {
                    // Rating
                    if let rating = skill.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Downloads
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blueLight)
                        Text(skill.formattedDownloads)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Category
                    Text(skill.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.bluePrimary.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Action button
                Button(action: {
                    if skill.hasUpdate {
                        onUpdate()
                    } else if !skill.isInstalled {
                        onInstall()
                    }
                }) {
                    HStack {
                        if installationStatus.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(.circular)
                        }
                        Text(installationStatus.buttonTitle)
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(buttonBackground)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(installationStatus.isLoading || installationStatus == .installed)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var buttonBackground: some View {
        Group {
            if installationStatus.isLoading {
                Color.gray
            } else if case .failed = installationStatus {
                Color.red
            } else if skill.hasUpdate {
                LinearGradient(
                    colors: [.coralAccent, .coralDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if skill.isInstalled {
                Color.green.opacity(0.6)
            } else {
                LinearGradient(
                    colors: [.coralAccent, .coralDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
}

// MARK: - Badge Component
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            SkillCard(
                skill: Skill(
                    id: "test-1",
                    name: "Twitter/X",
                    description: "Post tweets, read timeline, and manage your Twitter account",
                    shortDescription: "Official Twitter integration",
                    author: "OpenClaw Team",
                    version: "1.0.1",
                    category: .social,
                    icon: "bird",
                    rating: 4.8,
                    reviewCount: 234,
                    downloads: 12453,
                    repository: nil,
                    homepage: nil,
                    screenshots: [],
                    installationInstructions: "",
                    tags: [],
                    dependencies: [],
                    isInstalled: false,
                    installedVersion: nil,
                    hasUpdate: false,
                    publishedAt: Date(),
                    updatedAt: Date()
                ),
                installationStatus: .notInstalled,
                onInstall: {},
                onUpdate: {},
                onTap: {}
            )
            
            SkillCard(
                skill: Skill(
                    id: "test-2",
                    name: "GitHub",
                    description: "Manage repositories, issues, and pull requests",
                    shortDescription: "GitHub CLI integration",
                    author: "OpenClaw Team",
                    version: "2.0.0",
                    category: .devTools,
                    icon: "chevron.left.forwardslash.chevron.right",
                    rating: 4.9,
                    reviewCount: 567,
                    downloads: 45678,
                    repository: nil,
                    homepage: nil,
                    screenshots: [],
                    installationInstructions: "",
                    tags: [],
                    dependencies: [],
                    isInstalled: true,
                    installedVersion: "1.9.0",
                    hasUpdate: true,
                    publishedAt: Date(),
                    updatedAt: Date()
                ),
                installationStatus: .installed,
                onInstall: {},
                onUpdate: {},
                onTap: {}
            )
        }
        .padding()
    }
}
