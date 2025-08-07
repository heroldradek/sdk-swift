import Foundation

// MARK: - Event Data Objects

/// Data for view-iframe events
public struct ViewIframeData {
    public let id: String
    public let content: String
    public let messageId: String
    public let url: String
    
    public init(id: String, content: String, messageId: String, url: String) {
        self.id = id
        self.content = content
        self.messageId = messageId
        self.url = url
    }
}

/// Data for click-iframe events
public struct ClickIframeData {
    public let id: String
    public let content: String
    
    public init(id: String, content: String) {
        self.id = id
        self.content = content
    }
}

/// Data for resize-iframe events
public struct ResizeIframeData {
    public let height: CGFloat

    public init(height: CGFloat) {
        self.height = height
    }
}

/// Data for error events
public struct ErrorData {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

/// Data for unknown events
public struct UnknownData {
    public let type: String
    public let data: [String: Any]
    
    public init(type: String, data: [String: Any]) {
        self.type = type
        self.data = data
    }
}

/// Represents different types of events that can be received from the InlineAd iframe
public enum InlineAdEvent {
    /// The ad has been viewed by the user
    case viewIframe(ViewIframeData)
    
    /// The ad has been clicked by the user
    case clickIframe(ClickIframeData)
    
    /// The height of the iframe has changed
    case resizeIframe(ResizeIframeData)
    
    /// Error event from the iframe
    case error(ErrorData)
    
    /// Unknown event type
    case unknown(UnknownData)

    /// Init event from the iframe
    case initIframe
}

// MARK: - Event Parsing

extension InlineAdEvent {
    /// Creates an InlineAdEvent from a dictionary received from the iframe
    /// - Parameter dict: The dictionary containing event data
    /// - Returns: Parsed InlineAdEvent or nil if parsing fails
    public static func from(dict: [String: Any]) -> InlineAdEvent? {
        guard let type = dict["type"] as? String else { return nil }
        
        switch type {
        case "view-iframe":
            return parseViewIframe(dict: dict)
        case "click-iframe":
            return parseClickIframe(dict: dict)
        case "resize-iframe":
            return parseResizeIframe(dict: dict)
        case "error-iframe":
            return parseError(dict: dict)
        case "init-iframe":
             return .initIframe
        default:
            return .unknown(UnknownData(type: type, data: dict))
        }
    }
    
    private static func parseViewIframe(dict: [String: Any]) -> InlineAdEvent? {
        guard let data = dict["data"] as? [String: Any],
              let id = data["id"] as? String,
              let content = data["content"] as? String,
              let messageId = data["messageId"] as? String,
              let url = data["url"] as? String else {
            return nil
        }
        let viewData = ViewIframeData(id: id, content: content, messageId: messageId, url: url)
        return .viewIframe(viewData)
    }
    
    private static func parseClickIframe(dict: [String: Any]) -> InlineAdEvent? {
        guard let data = dict["data"] as? [String: Any],
              let id = data["id"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        let clickData = ClickIframeData(id: id, content: content)
        return .clickIframe(clickData)
    }
    
    private static func parseResizeIframe(dict: [String: Any]) -> InlineAdEvent? {
        guard let data = dict["data"] as? [String: Any],
              let height = data["height"] as? CGFloat else {
            return nil
        }
        let resizeData = ResizeIframeData(height: height)
        return .resizeIframe(resizeData)
    }
    
    private static func parseError(dict: [String: Any]) -> InlineAdEvent? {
        let message = dict["message"] as? String ?? "Unknown error"
        let errorData = ErrorData(message: message)
        return .error(errorData)
    }
}

// MARK: - Event Properties

extension InlineAdEvent {
    /// The event type as a string
    public var type: String {
        switch self {
        case .viewIframe:
            return "view-iframe"
        case .clickIframe:
            return "click-iframe"
        case .resizeIframe:
            return "resize-iframe"
        case .error:
            return "error-iframe"
        case .initIframe:
            return "init-iframe"
        case .unknown(let data):
            return data.type
        }
    }
    
    /// The bid ID if available
    public var bidId: String? {
        switch self {
        case .viewIframe(let data):
            return data.id
        case  .clickIframe(let data):
            return data.id
        default:
            return nil
        }
    }
    
    /// The message ID if available
    public var messageId: String? {
        switch self {
        case .viewIframe(let data):
            return data.messageId
        default:
            return nil
        }
    }
    
    /// The URL if available
    public var url: String? {
        switch self {
        case .viewIframe(let data):
            return data.url
        default:
            return nil
        }
    }
    
    /// The height if available (for resize events)
    public var height: CGFloat? {
        switch self {
        case .resizeIframe(let data):
            return data.height
        default:
            return nil
        }
    }
    
    /// The content if available
    public var content: String? {
        switch self {
        case .viewIframe(let data):
            return data.content
        case .clickIframe(let data):
            return data.content
        default:
            return nil
        }
    }
    
    /// The error message if available
    public var errorMessage: String? {
        switch self {
        case .error(let data):
            return data.message
        default:
            return nil
        }
    }
} 
