//
//  TestMorningInsight.swift
//  LifeStyles - Test Script
//
//  Quick test for Morning Insight functionality
//

import Foundation

print("🧪 Testing Morning Insight Setup...")
print("=" * 50)

// Test 1: API Key
print("\n1️⃣ API Key Test:")
let keyManager = SecureAPIKeyManager.shared
if keyManager.hasValidAPIKey() {
    print("✅ API Key is valid and stored in Keychain")
    print("   Masked key: \(APIConfig.apiKeyMasked)")
} else {
    print("❌ API Key is missing or invalid!")
}

// Test 2: Service Initialization
print("\n2️⃣ Service Initialization Test:")
let claudeService = ClaudeHaikuService.shared
print("✅ ClaudeHaikuService initialized")
print("   Model: \(APIConfig.defaultModel)")
print("   Max Tokens: \(APIConfig.maxTokens)")
print("   Temperature: \(APIConfig.defaultTemperature)")

let morningService = MorningInsightService.shared
print("✅ MorningInsightService initialized")

// Test 3: Cost Tracking
print("\n3️⃣ Cost Tracking Test:")
print("   Total Requests: \(claudeService.totalRequests)")
print("   Total Input Tokens: \(claudeService.totalInputTokens)")
print("   Total Output Tokens: \(claudeService.totalOutputTokens)")
print("   Estimated Cost: $\(String(format: "%.4f", claudeService.estimatedCost))")

// Test 4: Cache Status
print("\n4️⃣ Cache Status Test:")
if let cached = morningService.getCachedInsight() {
    print("✅ Cached insight found")
    print("   Date: \(cached.date)")
    print("   Preview: \(String(cached.insight.prefix(50)))...")
} else {
    print("ℹ️  No cached insight (will generate on first run)")
}

print("\n" + "=" * 50)
print("🎉 Test completed! Ready to test in simulator.")
print("\n📱 Next Steps:")
print("1. Open LifeStyles.xcodeproj in Xcode")
print("2. Run on iOS Simulator (Cmd+R)")
print("3. Navigate to Dashboard tab")
print("4. Watch for Morning Insight card")
print("5. Check Console for generation logs")
