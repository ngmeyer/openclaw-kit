import Foundation

/// Client for communicating with the OpenClaw gateway API
class OpenClawAPIClient {
    
    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case noAuthToken
        case invalidResponse
        case streamingError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid gateway URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .noAuthToken:
                return "No authentication token found. Please complete setup."
            case .invalidResponse:
                return "Invalid response from gateway"
            case .streamingError(let message):
                return "Streaming error: \(message)"
            }
        }
    }
    
    /// Send a message and stream the response using Server-Sent Events (SSE)
    /// - Parameters:
    ///   - message: The user's message text
    ///   - gatewayURL: Gateway base URL (e.g., "http://localhost:18789")
    ///   - authToken: Gateway authentication token
    ///   - sessionID: Unique session identifier for conversation context
    /// - Returns: AsyncThrowingStream that yields text deltas as they arrive
    func sendMessage(
        _ message: String,
        gatewayURL: String,
        authToken: String,
        sessionID: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Construct request URL
                    guard let url = URL(string: "\(gatewayURL)/v1/responses") else {
                        continuation.finish(throwing: APIError.invalidURL)
                        return
                    }
                    
                    // Build request
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 60 // 60 second timeout
                    
                    // Request body
                    let body: [String: Any] = [
                        "model": "openclaw:main",
                        "input": message,
                        "user": sessionID,
                        "stream": true
                    ]
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    print("📤 Sending message to \(url.absoluteString)")
                    print("📤 Session: \(sessionID)")
                    
                    // Start streaming request
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    // Check HTTP status
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📥 Response status: \(httpResponse.statusCode)")
                        
                        guard (200...299).contains(httpResponse.statusCode) else {
                            continuation.finish(throwing: APIError.streamingError("HTTP \(httpResponse.statusCode)"))
                            return
                        }
                    }
                    
                    // Parse SSE stream line by line
                    for try await line in bytes.lines {
                        // SSE format: "data: {json}"
                        if line.hasPrefix("data: ") {
                            let dataString = String(line.dropFirst(6))
                            
                            // Check for stream end marker
                            if dataString == "[DONE]" {
                                print("✅ Stream completed")
                                continuation.finish()
                                return
                            }
                            
                            // Parse JSON delta
                            if let jsonData = dataString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let delta = json["delta"] as? String {
                                continuation.yield(delta)
                            }
                        } else if line.hasPrefix("event: ") {
                            // Event type (e.g., "event: response.output_text.delta")
                            let eventType = String(line.dropFirst(7))
                            print("📡 Event: \(eventType)")
                        }
                    }
                    
                    // Stream ended without [DONE] marker
                    continuation.finish()
                    
                } catch {
                    print("❌ API error: \(error)")
                    continuation.finish(throwing: APIError.networkError(error))
                }
            }
        }
    }
    
    /// Load gateway configuration from OpenClaw config file
    /// - Returns: Tuple of (gatewayURL, authToken) or nil if not found
    static func loadGatewayConfig() -> (url: String, token: String)? {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw/openclaw.json")
        
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            print("⚠️ Config file not found at \(configPath.path)")
            return nil
        }
        
        guard let data = try? Data(contentsOf: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ Failed to parse config file")
            return nil
        }
        
        // Extract gateway configuration
        guard let gateway = json["gateway"] as? [String: Any] else {
            print("⚠️ No gateway config found")
            return nil
        }
        
        // Get port (default 18789)
        let port = gateway["port"] as? Int ?? 18789
        let url = "http://localhost:\(port)"
        
        // Get auth token
        guard let auth = gateway["auth"] as? [String: Any],
              let token = auth["token"] as? String else {
            print("⚠️ No auth token found in config")
            return nil
        }
        
        print("✅ Loaded gateway config: \(url)")
        return (url, token)
    }
}
