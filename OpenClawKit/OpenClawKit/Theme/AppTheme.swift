import SwiftUI

// MARK: - OpenClawKit Color Theme
// Matches website styling from css/styles.css

extension Color {
    // Primary Blues
    static let bluePrimary = Color(red: 30/255, green: 58/255, blue: 138/255)      // #1E3A8A
    static let blueLight = Color(red: 59/255, green: 92/255, blue: 201/255)        // #3B5CC9
    static let blueDark = Color(red: 23/255, green: 37/255, blue: 84/255)          // #172554
    static let blueLightBg = Color(red: 191/255, green: 209/255, blue: 255/255)    // #BFD1FF
    
    // Coral Accents
    static let coralAccent = Color(red: 251/255, green: 124/255, blue: 74/255)     // #FB7C4A
    static let coralLight = Color(red: 255/255, green: 161/255, blue: 131/255)     // #FFA183
    static let coralDark = Color(red: 232/255, green: 94/255, blue: 45/255)        // #E85E2D
    
    // Neutrals
    static let navyDark = Color(red: 23/255, green: 37/255, blue: 84/255)          // #172554
    static let lightGray = Color(red: 242/255, green: 242/255, blue: 242/255)      // #F2F2F2
    static let mediumGray = Color(red: 204/255, green: 204/255, blue: 204/255)     // #CCCCCC
    static let darkGray = Color(red: 74/255, green: 74/255, blue: 74/255)          // #4A4A4A
}

// MARK: - Gradients
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [.bluePrimary, .blueLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [.coralAccent, .coralLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [.blueDark, .navyDark],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.08, green: 0.12, blue: 0.25),
            Color(red: 0.05, green: 0.08, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isEnabled 
                                ? [.coralAccent, .coralDark]
                                : [.gray, .gray.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bluePrimary)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Styles
struct ThemedGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    
    init(cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blueLight.opacity(0.3),
                                        Color.bluePrimary.opacity(0.1),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            }
    }
}
