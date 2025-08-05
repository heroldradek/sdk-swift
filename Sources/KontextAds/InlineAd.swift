import SwiftUI
import UIKit
import WebKit

/// Delegate protocol to receive events from the InlineAd iframe
///     - Parameters:
///   - inlineAd: the InlineAd instance sending the event
///   - event: the payload object sent from the iframe (usually a Dictionary)
///

public protocol InlineAdDelegate: AnyObject {
    @MainActor
    func inlineAd(_ inlineAd: InlineAd, didReceiveEvent event: [String: Any])
}

public class InlineAdScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var inlineAd: InlineAd?

    public init(inlineAd: InlineAd) {
        self.inlineAd = inlineAd
        super.init()
    }

    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "iframeMessage",
              let ad = inlineAd else { return }
        if let dict = message.body as? [String: Any],
           let type = dict["type"] as? String {

            switch type {
            case "init-iframe":
                ad.sendUpdateIframe()
            case "view-iframe", "click-iframe":
                ad.adDelegate?.inlineAd(ad, didReceiveEvent: dict)
            case "error-iframe":
                print("[InlineAd]: Error: \(dict)")
            default: break
            }
        } else {
            print("[InlineAd]: Received non-dictionary message: \(message.body)")
        }
    }
}

public class InlineAd: WKWebView {
    private let config: AdConfig
    let webConfiguration = WKWebViewConfiguration()

    public weak var adDelegate: InlineAdDelegate?
    private var scriptHandler: InlineAdScriptMessageHandler?

    public init(frame: CGRect = .zero, config: AdConfig) {
        self.config = config

        let js = """
        window.addEventListener('message', function(event) {
            window.webkit.messageHandlers.iframeMessage.postMessage(event.data);
        });
        """
        let userScript = WKUserScript(source: js,
                                      injectionTime: .atDocumentStart,
                                      forMainFrameOnly: false)

        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)

        webConfiguration.userContentController = contentController

        super.init(frame: frame, configuration: webConfiguration)

        scriptHandler = InlineAdScriptMessageHandler(inlineAd: self)
        if let scriptHandler {
            configuration.userContentController.add(scriptHandler, name: "iframeMessage")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Task { [weak self] in
            await self?.webConfiguration
              .userContentController
              .removeScriptMessageHandler(forName: "iframeMessage")
        }
    }

    fileprivate func loadAd(from url: URL) {
        load(URLRequest(url: url))
    }

    fileprivate func sendUpdateIframe() {
        guard let data = config.asDictionary else {
            return
        }

        let payload: [String: Any] = [
            "type": "update-iframe",
            "data": data
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        // Post the message to the iframe
        let js = "window.postMessage(\(jsonString), '*');"
        evaluateJavaScript(js, completionHandler: nil)
    }
}

// MARK: - SwiftUI Wrapper

public struct InlineAdView: UIViewRepresentable {
    private let config: AdConfig
    private var onEvent: ((InlineAd, [String: Any]) -> Void)? = nil

    public init(config: AdConfig,
                onEvent: ((InlineAd, [String: Any]) -> Void)? = nil) {
        self.config = config
        self.onEvent = onEvent
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIView(context: Context) -> InlineAd {
        let view = InlineAd(frame: .zero, config: config)
        view.adDelegate = context.coordinator
        view.loadAd(from: config.url)
        return view
    }
    
    public func updateUIView(_ uiView: InlineAd, context: Context) {
        if uiView.url != config.url {
            uiView.loadAd(from: config.url)
        }
    }
    
    public class Coordinator: NSObject, InlineAdDelegate {
        var parent: InlineAdView
        init(_ parent: InlineAdView) {
            self.parent = parent
        }
        public func inlineAd(_ inlineAd: InlineAd, didReceiveEvent event: [String : Any]) {
            parent.onEvent?(inlineAd, event)
        }
    }
}
