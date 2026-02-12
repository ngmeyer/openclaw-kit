import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isEnabled: Bool
    let onSend: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var textEditorHeight: CGFloat = 36 // Start at single line height
    
    private let minHeight: CGFloat = 36  // Single line
    private let maxHeight: CGFloat = 140 // ~7 lines
    private let lineHeight: CGFloat = 20 // Approximate line height
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input with auto-expanding height
            ZStack(alignment: .topLeading) {
                // Placeholder - only show when empty and not focused
                if text.isEmpty {
                    Text("Type a message... (⌘↩ to send)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 4)
                        .padding(.top, 8)
                }
                
                // Text editor with dynamic height
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .frame(height: textEditorHeight)
                    .onChange(of: text) { newText in
                        calculateHeight(for: newText)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Send button - vertically centered
            Button(action: handleSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canSend ? .blue : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .help("Send message (⌘↩)")
            .frame(height: minHeight) // Align with minimum input height
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .onAppear {
            // Auto-focus input field
            isFocused = true
            // Calculate initial height
            calculateHeight(for: text)
        }
        // Keyboard shortcut: Cmd+Enter
        .onReceive(NotificationCenter.default.publisher(for: .cmdEnterPressed)) { _ in
            if canSend {
                handleSend()
            }
        }
    }
    
    private func calculateHeight(for text: String) {
        // Simple height calculation based on newlines and text length
        let lines = text.components(separatedBy: .newlines).count
        let estimatedLines = max(1, min(lines, 7))
        let targetHeight = minHeight + CGFloat(estimatedLines - 1) * lineHeight
        textEditorHeight = min(targetHeight, maxHeight)
    }
    
    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleSend() {
        guard canSend else { return }
        onSend()
    }
}

// MARK: - Keyboard Shortcut Handling

extension Notification.Name {
    static let cmdEnterPressed = Notification.Name("cmdEnterPressed")
}

// Custom AppDelegate handler for global keyboard shortcuts
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            // Intercept Cmd+Enter in TextEditor
            if let event = NSApp.currentEvent,
               event.type == .keyDown,
               event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers == "\r" {
                NotificationCenter.default.post(name: .cmdEnterPressed, object: nil)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        ChatInputView(
            text: .constant(""),
            isEnabled: true,
            onSend: {
                print("Send pressed")
            }
        )
    }
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
