import Foundation

public struct AdConfig: Codable, Sendable {
    let url: URL
    let messages: [ChatMessage]
    public let messageId: String
    let sdk: String
    let otherParams: [String:String]
    public let bid: Bid
}

extension Encodable {
    var asDictionary: [String: Any]? {
        guard
            let data = try? JSONEncoder().encode(self),
            let obj  = try? JSONSerialization.jsonObject(with: data),
            let dict = obj as? [String: Any]
        else { return nil }
        return dict
    }
}
