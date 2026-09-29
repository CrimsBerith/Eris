import Foundation

public struct GuardrailFilter: Sendable {
    private static let regexPatterns: [String] = [
        #"\b(?:ignore|disregard|forget)\s+(?:all\s+)?(?:previous|prior|above)\s+instructions\b"#,
        #"\b(?:show|print|reveal|display|output)\s+(?:your|the)\s+(?:system\s+)?instructions\b"#,
        #"\b(?:sistem|system)\s*(?:prompt|talimat|direktif)"#,
        #"\b(?:gizli\s+talimat|talimatlar[ıi]n[ıi]\s+yaz)\b"#,
        #"\b(?:jailbreak|dan\s+mode|developer\s+mode\s+enabled)\b"#,
        #"\b(?:bypass|override)\s+(?:security|safety|rules|guardrails)\b"#
    ]
    
    private static let plainKeywords: [String] = [
        "ignore previous instructions",
        "ignore all previous instructions",
        "forget all instructions",
        "disregard previous instructions",
        "system prompt",
        "sistem promptu",
        "show your instructions",
        "gizli talimat",
        "jailbreak",
        "dan mode",
        "prompt injection"
    ]
    
    public static func validateInput(_ text: String) -> (isSafe: Bool, reason: String?) {
        // 1. Sıfır genişlikli ve görünmez karakterleri temizle
        var normalized = text.replacingOccurrences(of: #"[\u{200B}-\u{200D}\u{FEFF}]"#, with: "", options: .regularExpression)
        normalized = normalized.lowercased()
        
        // 2. Düz anahtar kelimeler
        for kw in plainKeywords {
            if normalized.contains(kw) {
                return (false, "İstek güvenlik politikası gereği filtrelendi.")
            }
        }
        
        // 3. Regex tabanlı eşleşmeler
        for pattern in regexPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: normalized.utf16.count)
                if regex.firstMatch(in: normalized, options: [], range: range) != nil {
                    return (false, "İstek güvenlik politikası gereği filtrelendi.")
                }
            }
        }
        
        // 4. Boşlukları ve noktalama işaretlerini kaldırarak leetspeak/obfuscation kontrolü
        let stripped = normalized
            .replacingOccurrences(of: #"[^a-z0-9çğıöşü]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "3", with: "e")
            .replacingOccurrences(of: "4", with: "a")
            .replacingOccurrences(of: "5", with: "s")
        
        let compressedDangerous = [
            "systemprompt",
            "sistemprompt",
            "jailbreak",
            "danmode",
            "ignoreallprevious",
            "ignorepreviousinstructions"
        ]
        
        for c in compressedDangerous {
            if stripped.contains(c) {
                return (false, "İstek güvenlik politikası gereği filtrelendi.")
            }
        }
        
        return (true, nil)
    }
}
