import Foundation

struct IPLocationResponse: Codable {
    let zip: String?
    let city: String?
    let regionName: String?
    let status: String?
}

enum LocationError: Error {
    case invalidURL
    case httpError(statusCode: Int)
    case invalidResponse
}

struct LocationService {
    static let shared = LocationService()
    
    private init() {}
    
    /// Fetch approximate location from IP (no permission required)
    /// P1: Apply retry policy with exponential backoff (3 retries: 1s, 2s, 4s)
    func detectLocation() async -> (zip: String, city: String, region: String)? {
        let retryPolicy = RetryPolicy.default
        
        do {
            return try await retryPolicy.execute {
                try await fetchLocationFromAPI()
            }
        } catch {
            print("📍 [Location] Failed after all retries: \(error)")
            return nil
        }
    }
    
    private func fetchLocationFromAPI() async throws -> (zip: String, city: String, region: String) {
        // Note: ip-api.com free tier only supports HTTP (HTTPS requires paid Pro plan)
        // This is acceptable for IP geolocation as no sensitive data is transmitted
        guard let url = URL(string: "http://ip-api.com/json/?fields=status,city,regionName,zip") else {
            throw LocationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("OpenClawKit/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LocationError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        let location = try JSONDecoder().decode(IPLocationResponse.self, from: data)
        
        guard location.status == "success",
              let zip = location.zip, !zip.isEmpty,
              let city = location.city,
              let region = location.regionName else {
            throw LocationError.invalidResponse
        }
        
        return (zip: zip, city: city, region: region)
    }
    
    /// Format location for display
    func formatLocation(city: String, region: String, zip: String) -> String {
        return "\(city), \(region) \(zip)"
    }
}
