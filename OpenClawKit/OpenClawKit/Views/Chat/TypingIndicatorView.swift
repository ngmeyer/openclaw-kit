import SwiftUI
import Combine

struct TypingIndicatorView: View {
    @State private var animationPhase: Int = 0
    
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(.purple)
            
            // Label
            Text("Aria")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            // Animated dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(dotOpacity(for: index)))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.4), value: animationPhase)
                }
            }
            .padding(.leading, 80)
            .padding(.vertical, 12)
            ,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(maxWidth: 600, alignment: .leading)
        .onReceive(timer) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
    
    private func dotOpacity(for index: Int) -> Double {
        if index == animationPhase {
            return 1.0
        } else if index == (animationPhase + 2) % 3 {
            return 0.4
        } else {
            return 0.6
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TypingIndicatorView()
            .padding()
    }
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
