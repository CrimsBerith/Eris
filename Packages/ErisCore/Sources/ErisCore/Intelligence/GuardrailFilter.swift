import Foundation

public struct GuardrailFilter: Sendable {
    private static let dangerousPatterns: [String] = [
        "ignore previous instructions",
        "sistem promptunu",
        "system prompt",
        "show your instructions",
        "talimatlarını yaz",
        "bypass security",
        "jailbreak"
    ]
    
    public static func validateInput(_ text: String) -> (isSafe: Bool, reason: String?) {
        let lower = text.lowercased()
        for pattern in dangerousPatterns {
            if lower.contains(pattern) {
                return (false, "İstek güvenlik politikası gereği filtrelendi.")
            }
        }
        return (true, nil)
    }
}
