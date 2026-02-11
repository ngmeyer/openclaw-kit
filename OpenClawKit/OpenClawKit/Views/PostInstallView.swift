import SwiftUI

struct PostInstallView: View {
    @Environment(\.openURL) var openURL
    var onDismiss: () -> Void = {}
    var onStartChatting: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            FloatingOrbsBackground()
            
            VStack(spacing: 0) {
                // Close button (top right)
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                            .hoverEffect()
                    }
                }
                .padding(24)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Welcome Section
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 48))
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
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Welcome to OpenClawKit!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("You're all set up. Let's get started!")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Try These Conversations
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "bubble.right.fill")
                                    .foregroundColor(.cyan)
                                
                                Text("Try These Conversations")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            VStack(spacing: 12) {
                                ConversationSampleCard(
                                    title: "Writing Assistant",
                                    description: "Ask OpenClaw to help write, edit, and improve your content",
                                    icon: "pencil.circle.fill",
                                    color: .blue
                                )
                                
                                ConversationSampleCard(
                                    title: "Code Development",
                                    description: "Get help writing, debugging, and explaining code",
                                    icon: "curlybraces.square.fill",
                                    color: .orange
                                )
                                
                                ConversationSampleCard(
                                    title: "Research & Analysis",
                                    description: "Analyze information, summarize documents, and explore ideas",
                                    icon: "book.circle.fill",
                                    color: .purple
                                )
                            }
                        }
                        
                        // Recommended Skills
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                
                                Text("Recommended Skills to Install")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            VStack(spacing: 12) {
                                PostInstallSkillCard(
                                    name: "Web Research",
                                    description: "Search the web and fetch URLs",
                                    icon: "globe"
                                )
                                
                                PostInstallSkillCard(
                                    name: "File Operations",
                                    description: "Read, write, and manage files",
                                    icon: "folder.fill"
                                )
                                
                                PostInstallSkillCard(
                                    name: "Image Analysis",
                                    description: "Analyze images and create graphics",
                                    icon: "image.fill"
                                )
                            }
                            
                            // View More Skills Button
                            Button(action: {
                                // In production, would open Skills Marketplace
                                // For now, would navigate to skills view
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                    Text("View More Skills in Marketplace")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Community
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.green)
                                
                                Text("Join Our Community")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            Text("Get help, share ideas, and connect with other OpenClawKit users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                openURL(URL(string: "https://discord.gg/openclawkit")!)
                            }) {
                                HStack {
                                    Image(systemName: "message.circle.fill")
                                    Text("Join Discord")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .padding(24)
                }
                
                // Bottom Action
                VStack(spacing: 12) {
                    Button(action: onStartChatting) {
                        HStack {
                            Image(systemName: "bubble.left.fill")
                            Text("Start Chatting")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            LinearGradient(
                                colors: [.coralAccent, .coralDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: onDismiss) {
                        Text("I'll Explore Later")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12))
            }
        }
    }
}

// MARK: - Conversation Sample Card

struct ConversationSampleCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 44, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 12))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Simple Skill Card (for post-install view)

private struct PostInstallSkillCard: View {
    let name: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.cyan)
                .frame(width: 44, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cyan.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
        )
        .onHoverEffect()
    }
}

// MARK: - Floating Orbs Background

struct FloatingOrbsBackground: View {
    @State private var isAnimating = false
    
    // Orb configuration: (size, x position %, y position %, color, animation delay)
    private let orbs: [(CGFloat, Double, Double, Color, Double)] = [
        // Large background orbs (blue/purple)
        (400, 0.2, 0.3, Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.15), 0.0),
        (350, 0.8, 0.6, Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.12), 2.0),
        (300, 0.5, 0.8, Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.1), 4.0),
        
        // Medium orbs (coral/accent)
        (200, 0.1, 0.7, Color(red: 0.9, green: 0.5, blue: 0.3).opacity(0.2), 1.0),
        (180, 0.9, 0.2, Color(red: 0.8, green: 0.4, blue: 0.6).opacity(0.15), 3.0),
        (220, 0.7, 0.9, Color(red: 0.6, green: 0.7, blue: 0.9).opacity(0.18), 5.0),
        
        // Small accent orbs
        (120, 0.3, 0.5, Color(red: 0.4, green: 0.8, blue: 0.9).opacity(0.25), 0.5),
        (100, 0.6, 0.3, Color(red: 0.7, green: 0.5, blue: 0.8).opacity(0.2), 2.5),
        (80, 0.85, 0.75, Color(red: 0.9, green: 0.6, blue: 0.4).opacity(0.22), 4.5),
        (60, 0.15, 0.15, Color(red: 0.5, green: 0.9, blue: 0.7).opacity(0.2), 6.0),
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base dark gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.08, green: 0.10, blue: 0.20),
                        Color(red: 0.06, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated orbs
                ForEach(Array(orbs.enumerated()), id: \.offset) { index, orb in
                    let (size, xPercent, yPercent, color, delay) = orb
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.8),
                                    color.opacity(0.4),
                                    color.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                        .frame(width: size, height: size)
                        .position(
                            x: geometry.size.width * xPercent,
                            y: geometry.size.height * yPercent
                        )
                        .blur(radius: size * 0.15)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0.7)
                        .animation(
                            Animation
                                .easeInOut(duration: 4.0 + Double(index) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(delay),
                            value: isAnimating
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Extensions

extension View {
    func hoverEffect() -> some View {
        self.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    func onHoverEffect() -> some View {
        self
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

#Preview {
    PostInstallView(
        onDismiss: {},
        onStartChatting: {}
    )
}
