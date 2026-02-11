import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    let onCopy: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Message header
                HStack(spacing: 6) {
                    if message.role == .assistant {
                        Image(systemName: message.role.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.purple)
                    }
                    
                    Text(message.role.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if message.role == .user {
                        Image(systemName: message.role.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                // Message content
                MessageContentView(
                    content: message.content,
                    isStreaming: message.isStreaming,
                    role: message.role
                )
                .textSelection(.enabled)
                .contextMenu {
                    Button(action: onCopy) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .onHover { hovering in
                isHovered = hovering
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    private var backgroundColor: Color {
        if message.role == .user {
            return Color.blue.opacity(0.15)
        } else {
            return Color(red: 0.12, green: 0.12, blue: 0.18)
        }
    }
    
    private var borderColor: Color {
        if isHovered {
            return message.role == .user ? Color.blue.opacity(0.4) : Color.purple.opacity(0.4)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Message Content with Markdown

struct MessageContentView: View {
    let content: String
    let isStreaming: Bool
    let role: ChatMessage.MessageRole
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parse and render markdown-style content
            ForEach(parseContent(), id: \.id) { block in
                renderBlock(block)
            }
            
            // Streaming cursor
            if isStreaming && !content.isEmpty {
                Text("▊")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: isStreaming)
            }
        }
        .frame(maxWidth: 600, alignment: .leading)
    }
    
    // Simple markdown parser
    private func parseContent() -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let lines = content.components(separatedBy: .newlines)
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Code block (```)
            if line.hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                
                let code = codeLines.joined(separator: "\n")
                blocks.append(ContentBlock(type: .code, text: code))
                i += 1
                continue
            }
            
            // Heading (##)
            if line.hasPrefix("## ") {
                blocks.append(ContentBlock(type: .heading, text: String(line.dropFirst(3))))
            }
            // List item (• or -)
            else if line.hasPrefix("• ") || line.hasPrefix("- ") {
                blocks.append(ContentBlock(type: .listItem, text: String(line.dropFirst(2))))
            }
            // Regular paragraph
            else if !line.isEmpty {
                blocks.append(ContentBlock(type: .paragraph, text: line))
            }
            
            i += 1
        }
        
        return blocks
    }
    
    @ViewBuilder
    private func renderBlock(_ block: ContentBlock) -> some View {
        switch block.type {
        case .heading:
            Text(block.text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 4)
                
        case .paragraph:
            MarkdownText(block.text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundColor(.white.opacity(0.6))
                MarkdownText(block.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.leading, 8)
            
        case .code:
            Text(block.text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.green.opacity(0.9))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    struct ContentBlock: Identifiable {
        let id = UUID()
        let type: BlockType
        let text: String
        
        enum BlockType {
            case heading
            case paragraph
            case listItem
            case code
        }
    }
}

// MARK: - Inline Markdown Renderer

struct MarkdownText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        // Parse inline markdown: **bold**, *italic*, `code`, [link](url)
        let segments = parseInlineMarkdown(text)
        
        segments.reduce(Text("")) { result, segment in
            result + segment.render()
        }
    }
    
    private func parseInlineMarkdown(_ text: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        var remaining = text
        
        while !remaining.isEmpty {
            // Bold: **text**
            if let boldRange = remaining.range(of: #"\*\*([^*]+)\*\*"#, options: .regularExpression) {
                // Add text before bold
                let beforeText = String(remaining[..<boldRange.lowerBound])
                if !beforeText.isEmpty {
                    segments.append(.plain(beforeText))
                }
                
                // Extract and add bold text
                let match = String(remaining[boldRange])
                let boldText = match.dropFirst(2).dropLast(2)
                segments.append(.bold(String(boldText)))
                
                remaining = String(remaining[boldRange.upperBound...])
                continue
            }
            
            // Italic: *text*
            if let italicRange = remaining.range(of: #"\*([^*]+)\*"#, options: .regularExpression) {
                let beforeText = String(remaining[..<italicRange.lowerBound])
                if !beforeText.isEmpty {
                    segments.append(.plain(beforeText))
                }
                
                let match = String(remaining[italicRange])
                let italicText = match.dropFirst().dropLast()
                segments.append(.italic(String(italicText)))
                
                remaining = String(remaining[italicRange.upperBound...])
                continue
            }
            
            // Inline code: `code`
            if let codeRange = remaining.range(of: #"`([^`]+)`"#, options: .regularExpression) {
                let beforeText = String(remaining[..<codeRange.lowerBound])
                if !beforeText.isEmpty {
                    segments.append(.plain(beforeText))
                }
                
                let match = String(remaining[codeRange])
                let codeText = match.dropFirst().dropLast()
                segments.append(.code(String(codeText)))
                
                remaining = String(remaining[codeRange.upperBound...])
                continue
            }
            
            // No more markdown, add rest as plain
            segments.append(.plain(remaining))
            break
        }
        
        return segments
    }
    
    enum MarkdownSegment {
        case plain(String)
        case bold(String)
        case italic(String)
        case code(String)
        
        func render() -> Text {
            switch self {
            case .plain(let text):
                return Text(text)
            case .bold(let text):
                return Text(text).bold()
            case .italic(let text):
                return Text(text).italic()
            case .code(let text):
                return Text(text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.green.opacity(0.9))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ChatMessageBubble(
            message: ChatMessage(
                role: .user,
                content: "How do I install a skill?"
            ),
            onCopy: {}
        )
        
        ChatMessageBubble(
            message: ChatMessage(
                role: .assistant,
                content: """
                ## Installing Skills
                
                You can install skills using the **clawhub** command:
                
                • `clawhub install weather` - Install weather skill
                • `clawhub search home` - Search for skills
                • `clawhub list` - List installed skills
                
                ```
                clawhub install weather
                ```
                
                Check out the *documentation* for more details!
                """
            ),
            onCopy: {}
        )
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
