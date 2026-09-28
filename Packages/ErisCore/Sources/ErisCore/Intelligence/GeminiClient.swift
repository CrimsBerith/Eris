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
            throw NSError(domain: "ErisGemini", code: 401, userInfo: [NSLocalizedDescriptionKey: "Eris yapay zekâ servisine bağlanılamadı. Lütfen internet bağlantınızı kontrol edin."])
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel.rawValue):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ErisGemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API URL'i."])
        }
        
        // Eğer arama veya harici bilgi gerektiren bir soruysa DuckDuckGo üzerinden sorgula
        let lowerPrompt = prompt.lowercased()
        var webContext = ""
        if lowerPrompt.contains("araştır") || lowerPrompt.contains("internette ara") || lowerPrompt.contains("nedir") || lowerPrompt.contains("kimdir") || lowerPrompt.contains("haber") {
            let searchResult = await ExternalDataService.shared.searchWebUntrusted(query: prompt)
            webContext = "\n\(searchResult)\n(Not: Bu harici bilgi kaynağıdır, teyit ederek kısa ve tok özetle.)\n"
        }
        
        var contents: [GeminiRequest.Content] = []
        for msg in conversationHistory {
            contents.append(GeminiRequest.Content(
                role: msg.role == .user ? "user" : "model",
                parts: [GeminiRequest.Part(text: msg.content)]
            ))
        }
        
        let userPromptWithWeb = prompt + (webContext.isEmpty ? "" : "\n" + webContext)
        contents.append(GeminiRequest.Content(role: "user", parts: [GeminiRequest.Part(text: userPromptWithWeb)]))
        
        // Açık işleri (Open Loops) ve çoklu niyetleri otomatik saptama
        if let detectedLoop = ErisOpenLoopsEngine.shared.scanTextForOpenLoops(prompt) {
            ErisOpenLoopsEngine.shared.addLoop(detectedLoop)
        }
        if let plan = ErisIntentDecomposer.shared.decomposeUtterance(prompt) {
            for loopTitle in plan.openLoopsToCreate {
                ErisOpenLoopsEngine.shared.addLoop(OpenLoopItem(
                    domain: .tasksOpenLoops,
                    title: loopTitle,
                    detectedSource: "chat"
                ))
            }
        }
        
        // Kişisel hafıza + Bugünün takvim bağlamını + Açık döngüleri dinamik enjekte et
        let memoryContext = ErisMemoryDatabase.shared.getMemoryContextString()
        let calendarContext = CalendarCapability.shared.getCalendarContextString()
        let preferencesContext = ErisPersonalMemoryBank.shared.generatePromptContext()
        let openLoops = ErisOpenLoopsEngine.shared.activeLoops
        let openLoopsContext = openLoops.isEmpty ? "" : "\n[KULLANICININ AÇIK İŞLERİ & TAAHHÜTLERİ: " + openLoops.prefix(4).map { $0.title }.joined(separator: ", ") + "]"
        let fullSystemInstruction = ErisSystemPrompt.standardPrompt + "\nŞu anki İstanbul Saati: " + ErisSystemPrompt.istanbulDateString + calendarContext + memoryContext + "\n" + preferencesContext + openLoopsContext
        
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
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            var friendlyMessage = "Yapay zekâ servisiyle iletişim kurulurken bir sorun oluştu (Hata: \(statusCode)). Lütfen tekrar deneyin."
            
            if statusCode == 429 {
                friendlyMessage = "Yapay zekâ servis kotası geçici olarak doldu. Lütfen kısa bir süre sonra tekrar deneyin."
            } else if statusCode == 401 || statusCode == 403 {
                friendlyMessage = "Yapay zekâ servisi kimlik doğrulama hatası. Lütfen internet bağlantınızı kontrol edin."
            } else if statusCode >= 500 {
                friendlyMessage = "Yapay zekâ servisinde geçici bir yoğunluk yaşanıyor. Lütfen biraz sonra tekrar deneyin."
            } else if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let errorObj = errorJson["error"] as? [String: Any],
                      let msg = errorObj["message"] as? String {
                friendlyMessage = "Servis bildirimi: \(msg)"
            }
            
            throw NSError(domain: "ErisGemini", code: statusCode, userInfo: [NSLocalizedDescriptionKey: friendlyMessage])
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
