import Foundation

public struct Message: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date
    public let isAudioTranscript: Bool
    public var plan: DecomposedPlan?
    
    public enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
        case tool
    }
    
    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), isAudioTranscript: Bool = false, plan: DecomposedPlan? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isAudioTranscript = isAudioTranscript
        self.plan = plan
    }
}

public struct PendingAction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let actionType: ActionType
    public let summary: String
    public let payloadJson: String
    public let proposedAt: Date
    public var approvalToken: ApprovalToken?
    
    public enum ActionType: String, Codable, Sendable {
        case calendarWrite = "calendar_write"
        case smsToSelf = "sms_to_self"
        case pinMemory = "pin_memory"
    }
    
    public init(id: UUID = UUID(), actionType: ActionType, summary: String, payloadJson: String, proposedAt: Date = Date(), approvalToken: ApprovalToken? = nil) {
        self.id = id
        self.actionType = actionType
        self.summary = summary
        self.payloadJson = payloadJson
        self.proposedAt = proposedAt
        self.approvalToken = approvalToken
    }
}

public struct ApprovalToken: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let tokenString: String
    public let expiresAt: Date
    public var isUsed: Bool
    
    public init(id: UUID = UUID(), tokenString: String = UUID().uuidString, expiresAt: Date = Date().addingTimeInterval(120), isUsed: Bool = false) {
        self.id = id
        self.tokenString = tokenString
        self.expiresAt = expiresAt
        self.isUsed = isUsed
    }
    
    public var isValid: Bool {
        return !isUsed && Date() <= expiresAt
    }
}

public struct MemoryItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let category: String
    public let content: String
    public var pinned: Bool
    
    public init(id: UUID = UUID(), createdAt: Date = Date(), category: String, content: String, pinned: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.category = category
        self.content = content
        self.pinned = pinned
    }
}
