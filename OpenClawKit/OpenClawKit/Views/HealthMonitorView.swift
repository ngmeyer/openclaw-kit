import SwiftUI

struct HealthMonitorView: View {
    @StateObject private var viewModel = HealthViewModel.shared
    @State private var showingDiagnosticDetails = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Health")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.overallStatus.icon)
                            .foregroundColor(Color(viewModel.overallStatus.color))
                        
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.runDiagnostics()
                    }
                }) {
                    if viewModel.isRunningDiagnostics {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isRunningDiagnostics)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            // Issues List
            if viewModel.issues.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("All Systems Healthy")
                        .font(.headline)
                    
                    Text("Everything is running smoothly. Last check: \(lastCheckTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.controlBackgroundColor).opacity(0.5))
                .cornerRadius(12)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.issues) { issue in
                            HealthIssueCard(
                                issue: issue,
                                onFix: {
                                    Task {
                                        await viewModel.fixIssue(issue)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button(action: { showingDiagnosticDetails = true }) {
                    Label("Export Debug Info", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.runDiagnostics()
                    }
                }) {
                    Text("Run Full Diagnostics")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isRunningDiagnostics)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .task {
            // Run diagnostics on load
            await viewModel.runDiagnostics()
        }
        .sheet(isPresented: $showingDiagnosticDetails) {
            DiagnosticDetailsView()
        }
    }
    
    private var statusText: String {
        switch viewModel.overallStatus {
        case .healthy:
            return "All systems operational"
        case .warning:
            return "Some issues detected - Review below"
        case .critical:
            return "Critical issues found - Action required"
        }
    }
    
    private var lastCheckTime: String {
        if let lastCheck = viewModel.lastDiagnosticTime {
            let formatter = RelativeDateTimeFormatter()
            return formatter.localizedString(for: lastCheck, relativeTo: Date())
        }
        return "Never"
    }
}

// MARK: - Issue Card

struct HealthIssueCard: View {
    let issue: HealthIssue
    let onFix: () -> Void
    @State private var isFixing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: severityIcon)
                            .foregroundColor(severityColor)
                        
                        Text(issue.title)
                            .fontWeight(.semibold)
                    }
                    
                    Text(issue.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Suggested Fix
            VStack(alignment: .leading, spacing: 8) {
                Label("Suggested Fix", systemImage: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(issue.suggestedFix)
                    .font(.caption)
                    .padding(8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
            }
            
            // Action Button
            Button(action: {
                isFixing = true
                onFix()
                // Auto-reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isFixing = false
                }
            }) {
                if isFixing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Fix Automatically")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isFixing)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var severityIcon: String {
        issue.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }
    
    private var severityColor: Color {
        issue.severity == .critical ? .red : .yellow
    }
}

// MARK: - Diagnostic Details Sheet

struct DiagnosticDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var diagnosticText: String = ""
    @State private var showingCopyConfirm = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Diagnostic Information")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Content
            ScrollView {
                Text(diagnosticText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding()
                    .textSelection(.enabled)
            }
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    DiagnosticExporter.shared.copyDiagnosticsToClipboard()
                    showingCopyConfirm = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showingCopyConfirm = false
                    }
                }) {
                    Label(
                        showingCopyConfirm ? "Copied!" : "Copy to Clipboard",
                        systemImage: showingCopyConfirm ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    if let url = DiagnosticExporter.shared.saveDiagnosticsToFile() {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Save to File", systemImage: "arrow.down.doc")
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            diagnosticText = DiagnosticExporter.shared.exportDiagnostics()
        }
    }
}

#Preview {
    HealthMonitorView()
}
