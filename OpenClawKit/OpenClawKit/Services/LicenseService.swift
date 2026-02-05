import Foundation
import Combine
import IOKit

// MARK: - License Service
// Handles license validation via Lemonsqueezy API

@MainActor
class LicenseService: ObservableObject {
    static let shared = LicenseService()
    
    // Lemonsqueezy configuration
    private let storeId = 284970       // OpenClawKit store
    private let productId = 811437     // OpenClawKit product
    private let licenseBaseURL = "https://api.lemonsqueezy.com/v1/licenses"
    
    // Keychain keys
    private let licenseKeyKey = "license_key"
    private let instanceIdKey = "instance_id"
    private let activationDateKey = "activation_date"
    
    @Published var isLicensed: Bool = false
    @Published var licenseStatus: LicenseStatus = .unknown
    @Published var customerEmail: String?
    
    enum LicenseStatus: Equatable {
        case unknown
        case checking
        case valid
        case expired
        case invalid
        case activationLimitReached
        case error(String)
    }
    
    // Machine-specific identifier
    var machineId: String {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        guard platformExpert != 0 else {
            return getOrCreateFallbackUUID()
        }
        
        defer { IOObjectRelease(platformExpert) }
        
        guard let uuidRef = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return getOrCreateFallbackUUID()
        }
        
        return (uuidRef.takeRetainedValue() as? String) ?? getOrCreateFallbackUUID()
    }
    
    private func getOrCreateFallbackUUID() -> String {
        if let existing = KeychainHelper.get("fallback_device_id") {
            return existing
        }
        let newId = UUID().uuidString
        KeychainHelper.set("fallback_device_id", value: newId)
        return newId
    }
    
    init() {
        Task {
            await checkStoredLicense()
        }
    }
    
    // MARK: - Activation
    
    func activate(licenseKey: String) async -> Result<String, LicenseError> {
        licenseStatus = .checking
        print("🔑 [License] Activating license key...")
        
        guard let url = URL(string: "\(licenseBaseURL)/activate") else {
            licenseStatus = .error("Invalid URL")
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let instanceName = Host.current().localizedName ?? "Mac"
        let body = "license_key=\(licenseKey)&instance_name=\(instanceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? instanceName)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                licenseStatus = .error("Invalid response")
                return .failure(.networkError)
            }
            
            print("🔑 [License] Response status: \(httpResponse.statusCode)")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let lsResponse = try decoder.decode(LemonSqueezyResponse.self, from: data)
            
            // Check for errors
            if let error = lsResponse.error {
                licenseStatus = .invalid
                return .failure(.serverError(error))
            }
            
            // Verify activation
            guard lsResponse.activated == true else {
                if lsResponse.licenseKey?.activationUsage ?? 0 >= lsResponse.licenseKey?.activationLimit ?? 1 {
                    licenseStatus = .activationLimitReached
                    return .failure(.activationLimitReached)
                }
                licenseStatus = .invalid
                return .failure(.activationFailed)
            }
            
            // IMPORTANT: Verify this license belongs to OUR product
            if let meta = lsResponse.meta {
                if storeId != 0 && meta.storeId != storeId {
                    licenseStatus = .invalid
                    return .failure(.wrongProduct)
                }
                if productId != 0 && meta.productId != productId {
                    licenseStatus = .invalid
                    return .failure(.wrongProduct)
                }
                customerEmail = meta.customerEmail
            }
            
            // Store license info securely
            KeychainHelper.set(licenseKeyKey, value: licenseKey)
            if let instanceId = lsResponse.instance?.id {
                KeychainHelper.set(instanceIdKey, value: instanceId)
            }
            KeychainHelper.set(activationDateKey, value: ISO8601DateFormatter().string(from: Date()))
            
            isLicensed = true
            licenseStatus = .valid
            
            print("🔑 [License] Activation successful!")
            return .success(lsResponse.licenseKey?.status ?? "active")
            
        } catch let error as DecodingError {
            print("🔑 [License] Decoding error: \(error)")
            licenseStatus = .error("Invalid response format")
            return .failure(.invalidResponse)
        } catch {
            print("🔑 [License] Network error: \(error)")
            licenseStatus = .error("Network error")
            return .failure(.networkError)
        }
    }
    
    // MARK: - Validation
    
    func validate() async -> Bool {
        guard let licenseKey = KeychainHelper.get(licenseKeyKey) else {
            isLicensed = false
            licenseStatus = .invalid
            return false
        }
        
        licenseStatus = .checking
        print("🔑 [License] Validating stored license...")
        
        guard let url = URL(string: "\(licenseBaseURL)/validate") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var body = "license_key=\(licenseKey)"
        if let instanceId = KeychainHelper.get(instanceIdKey) {
            body += "&instance_id=\(instanceId)"
        }
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let lsResponse = try decoder.decode(LemonSqueezyResponse.self, from: data)
            
            guard lsResponse.valid == true else {
                // Check if expired
                if lsResponse.licenseKey?.status == "expired" {
                    isLicensed = false
                    licenseStatus = .expired
                    return false
                }
                isLicensed = false
                licenseStatus = .invalid
                return false
            }
            
            // Verify product ownership
            if let meta = lsResponse.meta {
                if storeId != 0 && meta.storeId != storeId { return false }
                if productId != 0 && meta.productId != productId { return false }
                customerEmail = meta.customerEmail
            }
            
            isLicensed = true
            licenseStatus = .valid
            return true
            
        } catch {
            print("🔑 [License] Validation error: \(error)")
            // On network error, trust local license for 7 days
            if let activationDate = KeychainHelper.get(activationDateKey),
               let date = ISO8601DateFormatter().date(from: activationDate) {
                let daysSinceActivation = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                if daysSinceActivation < 7 {
                    isLicensed = true
                    licenseStatus = .valid
                    return true
                }
            }
            licenseStatus = .error("Validation failed")
            return false
        }
    }
    
    // MARK: - Check stored license
    
    func checkStoredLicense() async {
        guard KeychainHelper.exists(licenseKeyKey) else {
            isLicensed = false
            licenseStatus = .unknown
            return
        }
        
        _ = await validate()
    }
    
    // MARK: - Deactivation
    
    func deactivate() async -> Bool {
        guard let licenseKey = KeychainHelper.get(licenseKeyKey),
              let instanceId = KeychainHelper.get(instanceIdKey) else {
            return false
        }
        
        print("🔑 [License] Deactivating...")
        
        guard let url = URL(string: "\(licenseBaseURL)/deactivate") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "license_key=\(licenseKey)&instance_id=\(instanceId)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let lsResponse = try decoder.decode(LemonSqueezyResponse.self, from: data)
            
            if lsResponse.deactivated == true {
                clearLicense()
                return true
            }
            return false
        } catch {
            print("🔑 [License] Deactivation error: \(error)")
            return false
        }
    }
    
    func clearLicense() {
        KeychainHelper.delete(licenseKeyKey)
        KeychainHelper.delete(instanceIdKey)
        KeychainHelper.delete(activationDateKey)
        isLicensed = false
        licenseStatus = .unknown
        customerEmail = nil
    }
}

// MARK: - Lemonsqueezy Response Models

struct LemonSqueezyResponse: Codable {
    let activated: Bool?
    let valid: Bool?
    let deactivated: Bool?
    let error: String?
    let licenseKey: LSLicenseKey?
    let instance: LSInstance?
    let meta: LSMeta?
}

struct LSLicenseKey: Codable {
    let id: Int
    let status: String
    let key: String
    let activationLimit: Int
    let activationUsage: Int
    let expiresAt: String?
}

struct LSInstance: Codable {
    let id: String
    let name: String
}

struct LSMeta: Codable {
    let storeId: Int
    let productId: Int
    let variantId: Int
    let customerId: Int
    let customerEmail: String
}

// MARK: - Errors

enum LicenseError: LocalizedError {
    case invalidURL
    case invalidKey
    case invalidResponse
    case networkError
    case serverError(String)
    case activationFailed
    case activationLimitReached
    case wrongProduct
    case deactivationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid license server URL"
        case .invalidKey:
            return "Invalid license key"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError:
            return "Network error - please check your connection"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .activationFailed:
            return "Failed to activate license"
        case .activationLimitReached:
            return "Activation limit reached. Deactivate another device first."
        case .wrongProduct:
            return "This license key is for a different product"
        case .deactivationFailed:
            return "Failed to deactivate license"
        }
    }
}
