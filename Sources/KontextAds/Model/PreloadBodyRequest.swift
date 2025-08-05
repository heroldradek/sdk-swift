import Foundation

public struct PreloadBodyRequest: Codable, Sendable {
    let publisherToken: String
    let conversationId: String
    let userId: String
    let messages: [ChatMessage]
    let variantId: String?
    let character: Character?
    let advertisingId: String?
    let vendorId: String?
    let sessionId: String?
}
