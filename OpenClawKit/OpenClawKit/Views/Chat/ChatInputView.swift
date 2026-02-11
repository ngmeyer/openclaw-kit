import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isEnabled: Bool
    let onSend: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input
            ZStack(alignment: .leading) {
                // Placeholder
                if text.isEmpty {
                    Text("Type a message... (⌘↩ to send)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 4)
                }
                
                // Text editor
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .frame(minHeight: 20, maxHeight: 100)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Send button
            Button(action: handleSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .help("Send message (⌘↩)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .onAppear {
            // Auto-focus input field
            isFocused = true
        }
        // Keyboard shortcut: Cmd+Enter
        .onReceive(NotificationCenter.default.publisher(for: .cmdEnterPressed)) { _ in
            if canSend {
                handleSend()
            }
        }
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
