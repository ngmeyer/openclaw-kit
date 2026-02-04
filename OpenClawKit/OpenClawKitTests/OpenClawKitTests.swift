//
//  OpenClawKitTests.swift
//  OpenClawKitTests
//
//  Created by Neal Meyer on 2/3/26.
//

import Testing
import Foundation
@testable import OpenClawKit

// MARK: - Setup Step Tests
struct SetupStepTests {
    
    @Test func testStepOrder() {
        let steps = SetupStep.allCases
        #expect(steps.count == 7)
        #expect(steps[0] == .license)
        #expect(steps[1] == .welcome)
        #expect(steps[6] == .complete)
    }
    
    @Test func testStepTitles() {
        #expect(SetupStep.license.title == "License")
        #expect(SetupStep.welcome.title == "Welcome")
        #expect(SetupStep.complete.title == "Complete")
    }
    
    @Test func testStepIcons() {
        #expect(SetupStep.license.icon == "key.horizontal.fill")
        #expect(SetupStep.systemCheck.icon == "checkmark.shield.fill")
    }
}

// MARK: - AI Provider Tests
struct AIProviderTests {
    
    @Test func testProviderOrder() {
        let providers = AIProvider.allCases
        #expect(providers[0] == .nvidia) // Default should be first
    }
    
    @Test func testNvidiaRequiresNoApiKey() {
        #expect(AIProvider.nvidia.requiresApiKey == false)
        #expect(AIProvider.anthropic.requiresApiKey == true)
        #expect(AIProvider.openAI.requiresApiKey == true)
    }
    
    @Test func testDefaultModels() {
        #expect(AIProvider.nvidia.defaultModel == "nvidia/kimi-k2.5")
        #expect(AIProvider.anthropic.defaultModel == "anthropic/claude-sonnet-4")
    }
}

// MARK: - Messaging Channel Tests
struct MessagingChannelTests {
    
    @Test func testAllChannelsHaveIcons() {
        for channel in MessagingChannel.allCases {
            #expect(!channel.icon.isEmpty)
        }
    }
    
    @Test func testAllChannelsHaveDescriptions() {
        for channel in MessagingChannel.allCases {
            #expect(!channel.description.isEmpty)
        }
    }
}

// MARK: - System Requirement Tests
struct SystemRequirementTests {
    
    @Test func testRequirementStatusEquality() {
        let checking = SystemRequirement.RequirementStatus.checking
        let passed = SystemRequirement.RequirementStatus.passed
        let failed = SystemRequirement.RequirementStatus.failed("error")
        
        // These are different states
        #expect(checking != passed)
    }
}

// MARK: - Keychain Helper Tests
struct KeychainHelperTests {
    
    @Test func testSetAndGet() {
        let testKey = "test_key_\(UUID().uuidString)"
        let testValue = "test_value_123"
        
        KeychainHelper.set(testKey, value: testValue)
        let retrieved = KeychainHelper.get(testKey)
        
        #expect(retrieved == testValue)
        
        // Cleanup
        KeychainHelper.delete(testKey)
    }
    
    @Test func testDelete() {
        let testKey = "test_delete_\(UUID().uuidString)"
        
        KeychainHelper.set(testKey, value: "value")
        #expect(KeychainHelper.exists(testKey) == true)
        
        KeychainHelper.delete(testKey)
        #expect(KeychainHelper.exists(testKey) == false)
    }
    
    @Test func testNonExistentKey() {
        let result = KeychainHelper.get("nonexistent_key_\(UUID().uuidString)")
        #expect(result == nil)
    }
}

// MARK: - Integrity Checker Tests
struct IntegrityCheckerTests {
    
    @Test func testBundleIdentifierVerification() {
        // This will fail in test context but shouldn't crash
        let result = IntegrityChecker.verifyBundleIdentifier(expected: "com.test.fake")
        // Don't check result as it depends on test runner bundle ID
    }
    
    @Test func testCodeSignatureCheck() {
        // Should not crash
        let _ = IntegrityChecker.isCodeSignatureValid()
    }
    
    @Test func testDebuggerCheck() {
        // Should not crash
        let _ = IntegrityChecker.isBeingDebugged()
    }
}

// MARK: - License Error Tests
struct LicenseErrorTests {
    
    @Test func testErrorDescriptions() {
        #expect(LicenseError.invalidKey.localizedDescription == "Invalid license key")
        #expect(LicenseError.networkError.localizedDescription == "Network error - please check your connection")
        #expect(LicenseError.activationLimitReached.localizedDescription == "Activation limit reached. Deactivate another device first.")
    }
}

// MARK: - LemonSqueezy Response Parsing Tests
struct LemonSqueezyResponseTests {
    
    @Test func testDecodeActivationResponse() throws {
        let json = """
        {
            "activated": true,
            "license_key": {
                "id": 123,
                "status": "active",
                "key": "XXXX-XXXX",
                "activation_limit": 3,
                "activation_usage": 1,
                "expires_at": null
            },
            "instance": {
                "id": "abc-123",
                "name": "My Mac"
            },
            "meta": {
                "store_id": 1,
                "product_id": 2,
                "variant_id": 3,
                "customer_id": 4,
                "customer_email": "test@example.com"
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(LemonSqueezyResponse.self, from: json.data(using: .utf8)!)
        
        #expect(response.activated == true)
        #expect(response.licenseKey?.id == 123)
        #expect(response.licenseKey?.status == "active")
        #expect(response.instance?.id == "abc-123")
        #expect(response.meta?.storeId == 1)
        #expect(response.meta?.customerEmail == "test@example.com")
    }
    
    @Test func testDecodeValidationResponse() throws {
        let json = """
        {
            "valid": true,
            "license_key": {
                "id": 123,
                "status": "active",
                "key": "XXXX-XXXX",
                "activation_limit": 3,
                "activation_usage": 1
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(LemonSqueezyResponse.self, from: json.data(using: .utf8)!)
        
        #expect(response.valid == true)
        #expect(response.licenseKey?.status == "active")
    }
    
    @Test func testDecodeErrorResponse() throws {
        let json = """
        {
            "error": "Invalid license key"
        }
        """
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(LemonSqueezyResponse.self, from: json.data(using: .utf8)!)
        
        #expect(response.error == "Invalid license key")
        #expect(response.activated == nil)
    }
}
