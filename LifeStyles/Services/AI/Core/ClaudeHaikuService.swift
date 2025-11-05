//
//  ClaudeHaikuService.swift
//  LifeStyles
//
//  Core Claude API Client - Haiku Model
//  Created by Claude on 22.10.2025.
//

import Foundation

// MARK: - Request & Response Models

struct ClaudeRequest: Codable {
    let model: String
    let max_tokens: Int
    let temperature: Double
    let system: String?
    let messages: [ClaudeMessage]
}

struct ClaudeMessage: Codable {
    let role: String  // "user" or "assistant"
    let content: String
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stop_reason: String?
    let usage: ClaudeUsage
}

struct ClaudeContent: Codable {
    let type: String  // "text"
    let text: String
}

struct ClaudeUsage: Codable {
    let input_tokens: Int
    let output_tokens: Int
}

// MARK: - Error Types

enum ClaudeError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case rateLimited
    case clientRateLimited(String)
    case securityCheckFailed(String)  // ✅ YENI: Jailbreak/güvenlik kontrolü
    case invalidResponse
    case apiError(Int, String)
    case contextTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Claude API key geçersiz"
        case .networkError(let message):
            return "Network hatası: \(message)"
        case .rateLimited:
            return "Rate limit aşıldı, lütfen bekleyin"
        case .clientRateLimited(let reason):
            return reason
        case .securityCheckFailed(let reason):
            return reason
        case .invalidResponse:
            return "API'den geçersiz yanıt"
        case .apiError(let code, let message):
            return "API Hatası (\(code)): \(message)"
        case .contextTooLarge:
            return "Context çok büyük, lütfen daha az veri gönderin"
        }
    }
}

// MARK: - Claude Haiku Service

@Observable
class ClaudeHaikuService: AIServiceProtocol {
    static let shared = ClaudeHaikuService()

    // Cost tracking
    private(set) var totalInputTokens: Int = 0
    private(set) var totalOutputTokens: Int = 0
    private(set) var totalRequests: Int = 0

    private init() {
        loadCostTracking()
    }

    // MARK: - Main Generate Method

    /// Generate AI response with Claude Haiku
    func generate(
        systemPrompt: String,
        userMessage: String,
        temperature: Double = APIConfig.defaultTemperature,
        maxTokens: Int = APIConfig.maxTokens
    ) async throws -> String {

        // ✅ YENI: Güvenlik kontrolü (jailbreak detection)
        let securityStatus = SecurityUtilities.shared.getSecurityStatus()
        if !securityStatus.isSecure {
            throw ClaudeError.securityCheckFailed(
                securityStatus.warningMessage ?? "Güvenlik kontrolü başarısız"
            )
        }

        // ✅ YENI: Rate limit kontrolü
        let limiter = APIUsageLimiter.shared
        let (allowed, reason) = limiter.canMakeRequest()
        guard allowed else {
            throw ClaudeError.clientRateLimited(reason ?? "Limit aşıldı")
        }

        // Build request
        let request = ClaudeRequest(
            model: APIConfig.defaultModel,
            max_tokens: maxTokens,
            temperature: temperature,
            system: systemPrompt,
            messages: [
                ClaudeMessage(role: "user", content: userMessage)
            ]
        )

        // Send to API
        let response = try await sendRequest(request)

        // ✅ YENI: Request kaydını yap
        limiter.recordRequest()

        // Track usage
        trackUsage(response.usage)

        // Extract text
        guard let text = response.content.first?.text else {
            throw ClaudeError.invalidResponse
        }

        return text
    }

    // MARK: - Advanced: Multi-turn Conversation

    /// Generate with conversation history
    func generateWithHistory(
        systemPrompt: String,
        messages: [ClaudeMessage],
        temperature: Double = APIConfig.defaultTemperature
    ) async throws -> String {

        // ✅ YENI: Güvenlik kontrolü (jailbreak detection)
        let securityStatus = SecurityUtilities.shared.getSecurityStatus()
        if !securityStatus.isSecure {
            throw ClaudeError.securityCheckFailed(
                securityStatus.warningMessage ?? "Güvenlik kontrolü başarısız"
            )
        }

        // ✅ YENI: Rate limit kontrolü
        let limiter = APIUsageLimiter.shared
        let (allowed, reason) = limiter.canMakeRequest()
        guard allowed else {
            throw ClaudeError.clientRateLimited(reason ?? "Limit aşıldı")
        }

        let request = ClaudeRequest(
            model: APIConfig.defaultModel,
            max_tokens: APIConfig.maxTokens,
            temperature: temperature,
            system: systemPrompt,
            messages: messages
        )

        let response = try await sendRequest(request)

        // ✅ YENI: Request kaydını yap
        limiter.recordRequest()

        trackUsage(response.usage)

        guard let text = response.content.first?.text else {
            throw ClaudeError.invalidResponse
        }

        return text
    }

    // MARK: - HTTP Request

    private func sendRequest(_ request: ClaudeRequest) async throws -> ClaudeResponse {
        guard let url = URL(string: APIConfig.claudeBaseURL) else {
            throw ClaudeError.networkError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(APIConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(
            APIConfig.anthropicVersion,
            forHTTPHeaderField: "anthropic-version"
        )
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.timeoutInterval = 30 // 30 saniye timeout

        // Encode request body
        let encoder = JSONEncoder()
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            print("❌ Request encoding error: \(error.localizedDescription)")
            throw ClaudeError.networkError("Request encoding failed")
        }

        // Send request with timeout
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            print("❌ Network request error: \(error.localizedDescription)")
            throw ClaudeError.networkError(error.localizedDescription)
        }

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.networkError("No HTTP response")
        }

        // Handle errors
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 429 {
                throw ClaudeError.rateLimited
            }

            if let errorData = try? JSONDecoder().decode(
                [String: AnyCodable].self,
                from: data
            ),
               let errorMessage = errorData["error"]?.value as? [String: Any],
               let message = errorMessage["message"] as? String {
                print("❌ API error: \(message)")
                throw ClaudeError.apiError(httpResponse.statusCode, message)
            }

            let errorMsg = "HTTP \(httpResponse.statusCode)"
            print("❌ Unknown API error: \(errorMsg)")
            throw ClaudeError.apiError(httpResponse.statusCode, errorMsg)
        }

        // Decode response
        let decoder = JSONDecoder()
        do {
            let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
            return claudeResponse
        } catch {
            print("❌ Response decode error: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response preview: \(jsonString.prefix(200))...")
            }
            throw ClaudeError.invalidResponse
        }
    }

    // MARK: - Cost Tracking

    private func trackUsage(_ usage: ClaudeUsage) {
        totalInputTokens += usage.input_tokens
        totalOutputTokens += usage.output_tokens
        totalRequests += 1

        saveCostTracking()

        print("📊 Claude Usage: +\(usage.input_tokens) in, +\(usage.output_tokens) out")
        print("   Total: \(totalRequests) requests, \(totalInputTokens) in, \(totalOutputTokens) out")
        print("   Cost: $\(String(format: "%.4f", estimatedCost))")
    }

    var estimatedCost: Double {
        let inputCost = (Double(totalInputTokens) / 1_000_000.0) * APIConfig.inputCostPer1M
        let outputCost = (Double(totalOutputTokens) / 1_000_000.0) * APIConfig.outputCostPer1M
        return inputCost + outputCost
    }

    func resetCostTracking() {
        totalInputTokens = 0
        totalOutputTokens = 0
        totalRequests = 0
        saveCostTracking()
    }

    private func loadCostTracking() {
        totalInputTokens = UserDefaults.standard.integer(forKey: "claude_total_input_tokens")
        totalOutputTokens = UserDefaults.standard.integer(forKey: "claude_total_output_tokens")
        totalRequests = UserDefaults.standard.integer(forKey: "claude_total_requests")
    }

    private func saveCostTracking() {
        UserDefaults.standard.set(totalInputTokens, forKey: "claude_total_input_tokens")
        UserDefaults.standard.set(totalOutputTokens, forKey: "claude_total_output_tokens")
        UserDefaults.standard.set(totalRequests, forKey: "claude_total_requests")
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            try container.encodeNil()
        }
    }
}
