import Foundation

struct IPLocationResponse: Codable {
    let zip: String?
    let city: String?
    let regionName: String?
    let status: String?
}

struct LocationService {
    static let shared = LocationService()
    
    private init() {}
    
    /// Fetch approximate location from IP (no permission required)
    func detectLocation() async -> (zip: String, city: String, region: String)? {
        guard let url = URL(string: "http://ip-api.com/json/?fields=status,city,regionName,zip") else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let location = try JSONDecoder().decode(IPLocationResponse.self, from: data)
            
            guard location.status == "success",
                  let zip = location.zip, !zip.isEmpty,
                  let city = location.city,
                  let region = location.regionName else {
                return nil
            }
            
            return (zip: zip, city: city, region: region)
        } catch {
            print("📍 [Location] Failed to detect: \(error)")
            return nil
        }
    }
    
    /// Format location for display
    func formatLocation(city: String, region: String, zip: String) -> String {
        return "\(city), \(region) \(zip)"
    }
}
