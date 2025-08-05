import Foundation

public struct Bid: Codable {
    public let bidId: String
    public let code: String
    public let adDisplayPosition: AdDisplayPosition
}

public enum AdDisplayPosition: String, Codable {
    case afterAssistantMessage
    case afterUserMessage
}
