import Foundation

/// P1: Retry policy with exponential backoff for network operations
struct RetryPolicy {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    
    /// Default policy: 3 retries with 1s, 2s, 4s delays
    static let `default` = RetryPolicy(maxAttempts: 3, baseDelay: 1.0)
    
    /// Execute an async operation with retry and exponential backoff
    /// - Parameter operation: The async operation to retry
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all retries fail
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't delay after last attempt
                guard attempt < maxAttempts - 1 else { break }
                
                // Exponential backoff: 2^attempt * baseDelay
                let delay = baseDelay * pow(2.0, Double(attempt))
                print("⏱️ [Retry] Attempt \(attempt + 1) failed, retrying in \(delay)s...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? RetryError.allAttemptsFailed
    }
}

enum RetryError: Error {
    case allAttemptsFailed
}
