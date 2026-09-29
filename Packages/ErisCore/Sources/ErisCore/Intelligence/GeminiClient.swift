import Foundation

public enum GeminiModelChoice: String, CaseIterable, Codable, Sendable {
    case flash2 = "gemini-2.0-flash"
    case flash = "gemini-1.5-flash"
    case pro = "gemini-1.5-pro"

    public var displayName: String {
        switch self {
        case .flash2: return "Gemini 2.0 Flash (Yeni Nesil & Hızlı)"
        case .flash: return "Gemini 1.5 Flash (Kararlı & Canlı)"
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

    public var selectedModel: GeminiModelChoice = .flash2

    /// Özel URLSession: 15s istek / 30s kaynak zaman aşımı
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private init() {}

    public func generateContent(prompt: String, conversationHistory: [Message] = []) async throws -> String {
        // MARK: 1. Güvenlik Kapısı — Kullanıcı girdisini GuardrailFilter'dan geçir
        let guardResult = GuardrailFilter.validateInput(prompt)
        guard guardResult.isSafe else {
            throw NSError(
                domain: "ErisGuardrail",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: guardResult.reason ?? "Bu istek güvenlik politikası gereği filtrelendi."]
            )
        }

        // MARK: 2. API Anahtarı — ErisAppConfig üzerinden 4-katmanlı çözüm
        let apiKey = ErisAppConfig.activeApiKey
        guard !apiKey.isEmpty else {
            throw NSError(
                domain: "ErisGemini",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Eris yapay zekâ servisine bağlanılamadı. Lütfen internet bağlantınızı kontrol edin."]
            )
        }

        // MARK: 2.1 Günlük İstek Kotası (Rate Limiting & Kötüye Kullanım Koruması)
        let rateCheck = ErisRateLimiter.shared.canMakeRequest()
        guard rateCheck.allowed else {
            throw NSError(
                domain: "ErisRateLimit",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: rateCheck.message ?? "Günlük kullanım sınırına ulaşıldı."]
            )
        }

        // MARK: 3. İstek Oluşturma
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel.rawValue):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ErisGemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API URL'i."])
        }

        // Arama veya harici bilgi gerektiren sorularda DuckDuckGo'dan bağlam al
        let lowerPrompt = prompt.lowercased()
        var webContext = ""
        if lowerPrompt.contains("araştır") || lowerPrompt.contains("internette ara")
            || lowerPrompt.contains("nedir") || lowerPrompt.contains("kimdir")
            || lowerPrompt.contains("haber") {
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

        // Açık işler ve çoklu niyetleri otomatik saptama
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

        // Kişisel hafıza + takvim + açık döngüler dinamik bağlam
        let memoryContext = ErisMemoryDatabase.shared.getMemoryContextString()
        let calendarContext = CalendarCapability.shared.getCalendarContextString()
        let preferencesContext = ErisPersonalMemoryBank.shared.generatePromptContext()
        let openLoops = ErisOpenLoopsEngine.shared.activeLoops
        let openLoopsContext = openLoops.isEmpty ? "" : "\n[KULLANICININ AÇIK İŞLERİ & TAAHHÜTLERİ: "
            + openLoops.prefix(4).map { $0.title }.joined(separator: ", ") + "]"
        let fullSystemInstruction = ErisSystemPrompt.standardPrompt
            + "\nŞu anki İstanbul Saati: " + ErisSystemPrompt.istanbulDateString
            + calendarContext + memoryContext + "\n" + preferencesContext + openLoopsContext

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

        // MARK: 4. Ağ İsteği — Üstel geri çekilmeli (exponential backoff) yeniden deneme
        return try await performRequestWithRetry(request: request, maxRetries: 2)
    }

    // MARK: - Retry Motoru

    private func performRequestWithRetry(request: URLRequest, maxRetries: Int) async throws -> String {
        var lastError: Error?
        for attempt in 0..<(maxRetries + 1) {
            do {
                return try await sendRequest(request)
            } catch let error as NSError {
                lastError = error
                let code = error.code
                // Yeniden deneme uygulanabilir hatalar: 429 (kota) ve 5xx (sunucu)
                let shouldRetry = attempt < maxRetries && (code == 429 || (code >= 500 && code < 600))
                if shouldRetry {
                    // Üstel bekleme: 1s → 2s
                    let delay = UInt64(1_000_000_000) * UInt64(1 << attempt)
                    try? await Task.sleep(nanoseconds: delay)
                    continue
                }
                throw error
            }
        }
        throw lastError ?? NSError(domain: "ErisGemini", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bilinmeyen hata."])
    }

    private func sendRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
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
            // Başarılı istek sonrası günlük kotayı kaydet
            ErisRateLimiter.shared.recordRequest()
            return replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw NSError(domain: "ErisGemini", code: 502, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API yanıtı."])
    }
}
