import Foundation

public struct ErrorRequest: Codable {
    let error: String
    let additionalData: Any?

    public init(error: String, additionalData: Any? = nil) {
        self.error = error
        self.additionalData = additionalData
    }
}
