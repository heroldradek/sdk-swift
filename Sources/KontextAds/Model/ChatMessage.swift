import Foundation

public struct ChatMessage: Codable, Sendable {
    public let id: String
    public let role: Role
    public let content: String
    public let createdAt: Date

    public init(id: String, role: Role, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

public enum Role: String, Codable, Sendable {
    case user
    case assistant
}

public enum Theme: String {
    case light, dark
}
