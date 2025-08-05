import Foundation

public struct ErrorRequest: Codable {
    let error: String
    let additionalData: AdditionalData

    public init(error: String, additionalData: AdditionalData) {
        self.error = error
        self.additionalData = additionalData
    }
}

public struct AdditionalData: Codable {
    let preloadBodyRequest: PreloadBodyRequest?

    public init(preloadBodyRequest: PreloadBodyRequest?) {
        self.preloadBodyRequest = preloadBodyRequest
    }
}
