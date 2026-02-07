import SwiftUI

/// Debounced button to prevent double-clicks and rapid taps
/// P0 Fix: 500ms debounce interval to prevent duplicate actions
struct DebouncedButton<Label: View>: View {
    let action: () -> Void
    let debounceInterval: TimeInterval
    let label: () -> Label
    
    @State private var isDebouncing = false
    
    init(
        debounceInterval: TimeInterval = 0.5,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.debounceInterval = debounceInterval
        self.label = label
    }
    
    var body: some View {
        Button(action: handleAction) {
            label()
        }
        .disabled(isDebouncing)
        .opacity(isDebouncing ? 0.6 : 1.0)
    }
    
    private func handleAction() {
        guard !isDebouncing else { return }
        
        isDebouncing = true
        action()
        
        // Re-enable after debounce interval
        Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            await MainActor.run {
                isDebouncing = false
            }
        }
    }
}
