import Foundation

public struct GuardrailFilter: Sendable {
    private static let dangerousPatterns: [String] = [
        "ignore previous instructions",
        "ignore all previous instructions",
        "forget all instructions",
        "disregard previous instructions",
        "sistem promptunu",
        "system prompt",
        "system prompt'unu",
        "show your instructions",
        "talimatlarını yaz",
        "gizli talimatlarını",
        "bypass security",
        "jailbreak",
        "dan mode",
        "developer mode enabled",
        "prompt injection"
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
