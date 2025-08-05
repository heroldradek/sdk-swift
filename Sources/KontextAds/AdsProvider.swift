import Foundation


public class AdsProvider: @unchecked Sendable {

    // MARK: - Settings
    private var messages: [ChatMessage]
    private let publisherToken: String
    private let userId: String
    private let conversationId: String
    private let enabledPlacementCodes: [String]
    private let character: Character?
    private var variantId: String?
    private var advertisingId: String?
    private var vendorId: String?
    private var isDisabled: Bool
    private var adServerUrl: String
    private var apiClient: APIClient?
    private var sessionId: String?

    public var theme: Theme = .light
    public var onAdView: ((AdEvent) -> Void)?
    public var onAdClick: ((AdEvent) -> Void)?
    
    private var response: PreloadResponse?
    // MARK: - Initializer
    public init(
        messages: [ChatMessage],
        publisherToken: String,
        userId: String,
        conversationId: String,
        enabledPlacementCodes: [String],
        character: Character? = nil,
        variantId: String? = nil,
        advertisingId: String? = nil,
        vendorId: String? = nil,
        sessionId: String? = nil,
        isDisabled: Bool = false,
        adServerUrl: String = "https://server.megabrain.co"
    ) {
        self.messages = messages
        self.publisherToken = publisherToken
        self.userId = userId
        self.conversationId = conversationId
        self.enabledPlacementCodes = enabledPlacementCodes
        self.character = character
        self.variantId = variantId
        self.advertisingId = advertisingId
        self.vendorId = vendorId
        self.sessionId = sessionId
        self.isDisabled = isDisabled
        self.adServerUrl = adServerUrl

        if let serverURL = URL(string: adServerUrl) {
            apiClient = APIClient(url: serverURL)
        }
    }

    private func preload() {
        let requestBody = generatePreloadBodyRequest()
        Task {
            do {
                response = try await apiClient?.request(path: "/preload", method: .post, body: requestBody)
            } catch {
                log("ERROR preloading ads: \(error)", additionalData: .init(preloadBodyRequest: requestBody))
            }
        }
    }

    private func getAdConfig() -> [AdConfig] {
        guard
            let response,
            let lastMessage = messages.last
        else {
            log("ERROR iFrame config", additionalData: .init(preloadBodyRequest: generatePreloadBodyRequest()))
            return []
        }

        let items = response.bids.compactMap { [weak self] bid -> AdConfig? in
            guard let self, let url = URL(string: "\(adServerUrl)/api/frame/\(bid.bidId)?messageId=\(lastMessage.id)&code=\(bid.code)") else { return nil }

            return AdConfig(
                url: url,
                messages: self.messages,
                messageId: lastMessage.id,
                sdk: "sdk-swift",
                otherParams: ["theme": theme.rawValue],
                bid: bid
            )
        }

        return items
    }

    public func addMessage(_ message: ChatMessage) -> [AdConfig]? {
        guard !isDisabled else { return nil }
        messages.append(message)
        switch message.role {
        case .user:
            preload()
            return nil
        case .assistant:
            return getAdConfig()
        }
    }

    private func log(_ message: String, additionalData: AdditionalData? = nil) {
        print("[AdsProvider] \(message)")
        let errorRequest = ErrorRequest(error: message, additionalData: additionalData)
        Task {
            try await apiClient?.send(path: "/error", method: .post, body: errorRequest)
        }
    }

    private func generatePreloadBodyRequest() -> PreloadBodyRequest {
        PreloadBodyRequest(
            publisherToken: publisherToken,
            conversationId: conversationId,
            userId: userId,
            messages: messages,
            variantId: variantId,
            character: character,
            advertisingId: advertisingId,
            vendorId: vendorId,
            sessionId: sessionId
        )
    }
}
