import Foundation

public struct Bid: Codable, Sendable {
    public let bidId: String
    public let code: String
    public let adDisplayPosition: AdDisplayPosition
}

public enum AdDisplayPosition: String, Codable, Sendable {
    case afterAssistantMessage
    case afterUserMessage
}
