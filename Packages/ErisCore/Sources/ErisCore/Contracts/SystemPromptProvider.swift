import Foundation

public enum ErisSystemPrompt {
    public static var standardPrompt: String {
        return ErisAgentPersonaManager.shared.generateSystemInstruction()
    }
    
    public static var istanbulDateString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss (z)"
        return formatter.string(from: Date())
    }
}
