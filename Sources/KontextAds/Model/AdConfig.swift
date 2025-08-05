import Foundation

public struct AdConfig: Codable {
    let url: URL
    let messages: [ChatMessage]
    let messageId: String
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
