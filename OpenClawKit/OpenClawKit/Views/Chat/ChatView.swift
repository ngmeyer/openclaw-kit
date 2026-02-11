import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearAlert = false
    @State private var showingMissionControl = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeaderView(
                isConnected: viewModel.isConnected,
                onBack: {
                    presentationMode.wrappedValue.dismiss()
                },
                onClear: {
                    showingClearAlert = true
                },
                onMissionControl: {
                    showingMissionControl = true
                }
            )
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageBubble(
                                message: message,
                                onCopy: {
                                    viewModel.copyMessage(message)
                                }
                            )
                            .id(message.id)
                        }
                        
                        // Typing indicator
                        if viewModel.isTyping {
                            TypingIndicatorView()
                                .padding(.leading, 16)
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                // Auto-scroll to latest message
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.last?.content) { _ in
                    // Scroll while streaming
                    scrollToBottom(proxy: proxy, animated: false)
                }
            }
            
            // Error banner
            if let error = viewModel.error {
                ErrorBannerView(
                    message: error,
                    onDismiss: {
                        viewModel.clearError()
                    },
                    onRetry: {
                        viewModel.retryLastMessage()
                    }
                )
            }
            
            // Input
            ChatInputView(
                text: $viewModel.inputText,
                isEnabled: viewModel.isConnected && !viewModel.isTyping,
                onSend: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            )
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .alert("Clear Conversation?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearConversation()
            }
        } message: {
            Text("This will delete all messages in this conversation. This action cannot be undone.")
        }
        .sheet(isPresented: $showingMissionControl) {
            MissionControlView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .onAppear {
            // Check connection status
            Task {
                await viewModel.checkConnection()
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if viewModel.isTyping {
            withAnimation(animated ? .easeOut : nil) {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if let lastMessage = viewModel.messages.last {
            withAnimation(animated ? .easeOut : nil) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Header

struct ChatHeaderView: View {
    let isConnected: Bool
    let onBack: () -> Void
    let onClear: () -> Void
    let onMissionControl: () -> Void
    
    var body: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .help("Back to setup")
            
            Spacer()
            
            // Title
            VStack(spacing: 2) {
                Text("OpenClaw Chat")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    
                    Text(isConnected ? "Connected" : "Disconnected")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Mission Control button
                Button(action: onMissionControl) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.3x3")
                            .font(.system(size: 14))
                        Text("Mission Control")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Open Mission Control dashboard")
                
                // Clear button
                Button(action: onClear) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Clear conversation")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
}

// MARK: - Error Banner

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.2))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.red.opacity(0.3)),
            alignment: .top
        )
    }
}

// MARK: - Preview

#Preview {
    ChatView()
        .frame(width: 900, height: 750)
}
