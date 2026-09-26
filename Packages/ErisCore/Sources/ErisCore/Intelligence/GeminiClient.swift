import Foundation
import Combine

public enum GeminiModelChoice: String, CaseIterable, Codable, Sendable {
    case flash = "gemini-1.5-flash"
    case pro = "gemini-1.5-pro"
    
    public var displayName: String {
        switch self {
        case .flash: return "Gemini 1.5 Flash (Çok Hızlı, Tok & Canlı)"
        case .pro: return "Gemini 1.5 Pro (Daha Derin Analiz)"
        }
    }
}

public struct GeminiRequest: Codable, Sendable {
    public struct Content: Codable, Sendable {
        public let role: String
        public let parts: [Part]
        public init(role: String, parts: [Part]) {
            self.role = role
            self.parts = parts
        }
    }
    
    public struct Part: Codable, Sendable {
        public let text: String?
        public init(text: String?) {
            self.text = text
        }
    }
    
    public let contents: [Content]
    public let systemInstruction: Content?
    
    public init(contents: [Content], systemInstruction: Content? = nil) {
        self.contents = contents
        self.systemInstruction = systemInstruction
    }
}

public final class GeminiClient: @unchecked Sendable {
    public static let shared = GeminiClient()
    private let session = URLSession.shared
    
    public var selectedModel: GeminiModelChoice = .flash
    
    private init() {}
    
    public func generateContent(prompt: String, conversationHistory: [Message] = []) async throws -> String {
        guard let apiKey = KeychainManager.shared.getApiKey(), !apiKey.isEmpty else {
            throw NSError(domain: "ErisGemini", code: 401, userInfo: [NSLocalizedDescriptionKey: "Gemini API Anahtarı bulunamadı. Lütfen ayarlardan kaydedin."])
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel.rawValue):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ErisGemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API URL'i."])
        }
        
        var contents: [GeminiRequest.Content] = []
        for msg in conversationHistory {
            contents.append(GeminiRequest.Content(
                role: msg.role == .user ? "user" : "model",
                parts: [GeminiRequest.Part(text: msg.content)]
            ))
        }
        contents.append(GeminiRequest.Content(role: "user", parts: [GeminiRequest.Part(text: prompt)]))
        
        // Kişisel hafıza bağlamını sisteme dinamik enjekte et
        let memoryContext = ErisMemoryDatabase.shared.getMemoryContextString()
        let fullSystemInstruction = ErisSystemPrompt.standardPrompt + "\nŞu anki İstanbul Saati: " + ErisSystemPrompt.istanbulDateString + memoryContext
        
        let systemContent = GeminiRequest.Content(
            role: "system",
            parts: [GeminiRequest.Part(text: fullSystemInstruction)]
        )
        
        let requestBody = GeminiRequest(contents: contents, systemInstruction: systemContent)
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Bilinmeyen sunucu hatası"
            throw NSError(domain: "ErisGemini", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let contentObj = firstCandidate["content"] as? [String: Any],
           let parts = contentObj["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let replyText = firstPart["text"] as? String {
            return replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw NSError(domain: "ErisGemini", code: 502, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API yanıtı."])
    }
}
