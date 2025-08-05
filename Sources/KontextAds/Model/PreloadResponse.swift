import Foundation

struct PreloadResponse: Decodable {
    let sessionId: String?
    let bids: [Bid]
    let remoteLogLevel: String?
    let preloadTimeout: Int?
}
