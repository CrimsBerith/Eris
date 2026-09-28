//
//  ErisNoteIntelligence.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

/// Çıkarılan veya organize edilen not bilgisi
public struct ExtractedNoteInfo: Sendable, Equatable {
    public let isValuable: Bool
    public let category: MemoryCategory
    public let title: String
    public let content: String
    public let tags: [String]
    public let suggestedFileName: String
    public let detectionReason: String
    public let isExplicitCommand: Bool
    
    public init(
        isValuable: Bool,
        category: MemoryCategory,
        title: String,
        content: String,
        tags: [String],
        suggestedFileName: String,
        detectionReason: String,
        isExplicitCommand: Bool = false
    ) {
        self.isValuable = isValuable
        self.category = category
        self.title = title
        self.content = content
        self.tags = tags
        self.suggestedFileName = suggestedFileName
        self.detectionReason = detectionReason
        self.isExplicitCommand = isExplicitCommand
    }
}

/// Kullanıcının sesli konuşmalarından ve sohbetlerinden önemli bilgileri (fiyatlar, sözleşmeler,
/// teknik detaylar, görevler, tasarım fikirleri) tespit eden ve Notlar & Dosyalar kasasına
/// organize eden akıllı zekâ motoru.
public final class ErisNoteIntelligence: Sendable {
    public static let shared = ErisNoteIntelligence()
    
    private init() {}
    
    // MARK: - Explicit Triggers
    private let explicitTriggers = [
        "bunu not et", "bunu not al", "not al:", "not et:", "not tut:", "not düş:",
        "hafızaya yaz", "hafızaya kaydet", "aklında tut", "bunu hatırla", "hatırla:",
        "dosyalara ekle", "dosyaya kaydet", "bunu kaydet", "kaydet:",
        "take a note", "note this", "remember this", "save this", "jot this down",
        "save to files", "anota esto", "recuerda esto", "notiere das"
    ]
    
    /// Verilen metni analiz eder. Açık not alma isteği veya konuşma içindeki kritik bilgiyi saptar.
    public func analyzeUtterance(_ rawText: String, isVoice: Bool = false) -> ExtractedNoteInfo? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        
        // 1. Açık Not Alma Komutu Kontrolü
        var cleanContent = trimmed
        var isExplicit = false
        
        for trigger in explicitTriggers {
            if lower.contains(trigger) {
                isExplicit = true
                // Trigger kelimesini içerikten nazikçe ayıkla
                if let range = cleanContent.range(of: trigger, options: .caseInsensitive) {
                    cleanContent.removeSubrange(range)
                }
                break
            }
        }
        
        cleanContent = cleanContent
            .trimmingCharacters(in: CharacterSet(charactersIn: " :,-–—\t\n\r"))
        if cleanContent.isEmpty {
            cleanContent = trimmed
        }
        
        // 2. Kategori ve İçerik Analizi (Örtük Bilgi Tespiti)
        let (category, reason, tags, derivedTitle, fileName) = categorizeAndExtractMetadata(cleanContent)
        
        // Açıkça not istenmişse veya örtük kritik bilgi yakalanmışsa
        let isValuable = isExplicit || (reason != nil)
        
        guard isValuable else { return nil }
        
        let finalTitle: String
        if !derivedTitle.isEmpty {
            finalTitle = derivedTitle
        } else {
            finalTitle = generateFallbackTitle(from: cleanContent, category: category)
        }
        
        let safeReason = reason ?? (isExplicit ? "Kullanıcı doğrudan not alma komutu verdi" : "Önemli bilgi tespit edildi")
        
        return ExtractedNoteInfo(
            isValuable: true,
            category: category,
            title: finalTitle,
            content: cleanContent,
            tags: tags,
            suggestedFileName: fileName,
            detectionReason: safeReason,
            isExplicitCommand: isExplicit
        )
    }
    
    // MARK: - İçerik Analiz & Metadata Çıkarımı
    private func categorizeAndExtractMetadata(_ text: String) -> (MemoryCategory, String?, [String], String, String) {
        let lower = text.lowercased()
        
        // A. Finans & Fiyatlar (Para birimleri, tutarlar, maliyetler, teklifler)
        let financeIndicators = [
            "$", "€", "₺", "usd", "eur", "try", "gbp", " tl", "dolar", "euro", "lira",
            "fiyat", "ücret", "bütçe", "maliyet", "teklif", "fatura", "harcama",
            "metresi", "metre başı", "adet fiyatı", "kdv dahil", "kdv hariç", "cost", "price", "budget"
        ]
        let hasNumber = text.rangeOfCharacter(from: .decimalDigits) != nil
        let matchesFinance = financeIndicators.contains { lower.contains($0) }
        
        if matchesFinance && (hasNumber || lower.contains("bütçe") || lower.contains("teklif")) {
            var tags = ["#finans", "#fiyat"]
            if lower.contains("kumaş") || lower.contains("ipek") || lower.contains("astar") || lower.contains("saten") {
                tags.append("#kumaş")
            }
            if lower.contains("bütçe") { tags.append("#bütçe") }
            if lower.contains("teklif") { tags.append("#teklif") }
            
            let title = extractHeadline(from: text, fallbackPrefix: "Finans & Fiyat Notu")
            let fileName = sanitizeFileName("Finans_\(title).txt")
            return (.finance, "Finansal tutar, fiyat veya bütçe bilgisi tespit edildi", tags, title, fileName)
        }
        
        // B. Belgeler & Resmi Bilgiler (IBAN, Vergi No, TC Kimlik, Sözleşme Maddesi)
        let docIndicators = ["iban", "tr0", "tr1", "tr2", "tr3", "tr4", "tr5", "tr6", "tr7", "tr8", "tr9", "vergi no", "vergi dairesi", "tc kimlik", "sözleşme", "kontrat", "madde ", "lisans no", "şirket unvanı", "mersis"]
        if docIndicators.contains(where: { lower.contains($0) }) {
            let tags = ["#belge", "#resmi", "#kayıt"]
            let title = extractHeadline(from: text, fallbackPrefix: "Resmi Belge Notu")
            let fileName = sanitizeFileName("Belge_\(title).md")
            return (.document, "Resmi evrak, IBAN veya sözleşme bilgisi tespit edildi", tags, title, fileName)
        }
        
        // C. Kodlama & Teknik Altyapı (API, Server, IP, Port, Concurrency, Swift, Docker, SQL)
        let techIndicators = [
            "api", "endpoint", "database", "veritabanı", "sql", "sqlite", "swift", "concurrency",
            "actor", "docker", "ip adresi", "port ", "ssh", "github", "token", "jwt", "backend",
            "frontend", "rest api", "graphql", "ssl", "sertifika", "nginx", "redis", "sunucu"
        ]
        if techIndicators.contains(where: { lower.contains($0) }) {
            var tags = ["#teknik", "#yazılım"]
            if lower.contains("swift") { tags.append("#swift") }
            if lower.contains("api") { tags.append("#api") }
            if lower.contains("sunucu") || lower.contains("server") { tags.append("#sunucu") }
            
            let title = extractHeadline(from: text, fallbackPrefix: "Teknik Mimari Notu")
            let fileName = sanitizeFileName("Teknik_\(title).md")
            return (.technical, "Yazılım mimarisi veya teknik sistem detayı tespit edildi", tags, title, fileName)
        }
        
        // D. Projeler & Görevler (Teslim tarihi, deadline, kilometre taşı, görev)
        let projectIndicators = [
            "teslim tarihi", "deadline", "milestone", "pazartesiye kadar", "haftaya cuma",
            "görev:", "proje:", "tamamlanacak", "yapılacaklar", "todo", "sürüm ", "versiyon", "release"
        ]
        if projectIndicators.contains(where: { lower.contains($0) }) {
            let tags = ["#proje", "#görev", "#plan"]
            let title = extractHeadline(from: text, fallbackPrefix: "Proje Görevi")
            let fileName = sanitizeFileName("Proje_\(title).txt")
            return (.project, "Proje teslimi, görev veya takvim maddesi tespit edildi", tags, title, fileName)
        }
        
        // E. Fikirler & Tasarım (Koleksiyon, silüet, renk, drape, desen, konsept)
        let designIndicators = [
            "tasarım", "koleksiyon", "silüet", "drape", "renk paleti", "pantone", "eskiz",
            "desen", "kumaş kombinasyonu", "form", "konsept", "estetik", "model", "ceket fikri"
        ]
        if designIndicators.contains(where: { lower.contains($0) }) {
            let tags = ["#tasarım", "#fikir", "#koleksiyon"]
            let title = extractHeadline(from: text, fallbackPrefix: "Tasarım Fikri")
            let fileName = sanitizeFileName("Tasarim_\(title).md")
            return (.designIdea, "Yaratıcı tasarım fikri veya koleksiyon detayı tespit edildi", tags, title, fileName)
        }
        
        // F. Önemli Kişi & İletişim (Telefon, e-posta, unvan)
        let contactIndicators = ["telefonu", "tel:", "gsm:", "iletişim", "@", "mail adresi", "e-posta", "bey'in", "hanım'ın", "kaptan", "mimar", "avukat"]
        if contactIndicators.contains(where: { lower.contains($0) }) && (hasNumber || lower.contains("@")) {
            let tags = ["#kişi", "#rehber", "#iletişim"]
            let title = extractHeadline(from: text, fallbackPrefix: "Kişi İletişim Notu")
            let fileName = sanitizeFileName("Kisi_\(title).txt")
            return (.person, "Kişi kartı, iletişim veya unvan bilgisi tespit edildi", tags, title, fileName)
        }
        
        // Varsayılan / Genel Not
        return (.preference, nil, ["#genel", "#not"], "", "Not.txt")
    }
    
    // MARK: - Başlık ve Dosya Adı Yardımcıları
    private func extractHeadline(from text: String, fallbackPrefix: String) -> String {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let first = lines.first else { return fallbackPrefix }
        
        let cleaned = first
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.count <= 45 {
            return cleaned
        } else {
            let idx = cleaned.index(cleaned.startIndex, offsetBy: 42)
            return String(cleaned[..<idx]) + "..."
        }
    }
    
    private func generateFallbackTitle(from text: String, category: MemoryCategory) -> String {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count <= 5 {
            return text
        }
        let prefixWords = words.prefix(5).joined(separator: " ")
        return "\(prefixWords)..."
    }
    
    private func sanitizeFileName(_ rawName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>| \t\n\r")
        let components = rawName.components(separatedBy: invalidCharacters)
        let clean = components.filter { !$0.isEmpty }.joined(separator: "_")
        return clean.isEmpty ? "Eris_Not.txt" : clean
    }
    
    /// Bir not kaydını organize edilmiş Markdown formatına çevirir
    public func formatRecordAsMarkdown(_ record: ErisMemoryRecord) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        let dateStr = formatter.string(from: record.createdAt)
        
        var md = "# \(record.title)\n\n"
        md += "- **Kategori:** \(record.category.displayName)\n"
        md += "- **Kayıt Tarihi:** \(dateStr)\n"
        md += "- **Kaynak Kanal:** \(sourceDisplayName(record.source))\n"
        if !record.tags.isEmpty {
            md += "- **Etiketler:** \(record.tags.joined(separator: " "))\n"
        }
        if let fName = record.fileName {
            md += "- **Dosya Referansı:** `\(fName)`\n"
        }
        md += "\n---\n\n"
        md += "\(record.content)\n"
        return md
    }
    
    public func sourceDisplayName(_ source: String) -> String {
        switch source.lowercased() {
        case "voice": return "🎙️ Sesli Konuşma (Akıllı Yakalama)"
        case "chat": return "💬 Doğal Dil Sohbeti"
        default: return "✍️ Manuel Not Girişi"
        }
    }
}
