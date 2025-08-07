import SwiftUI
import UIKit
import WebKit

public protocol InlineAdDelegate: AnyObject {
    @MainActor
    func inlineAd(_ inlineAd: InlineAd, didReceiveEvent event: InlineAdEvent)
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
        
        if let dict = message.body as? [String: Any] {
            if let event = InlineAdEvent.from(dict: dict) {
                switch event {
                case .initIframe:
                    ad.sendUpdateIframe()
                case .viewIframe, .clickIframe, .resizeIframe:
                    ad.adDelegate?.inlineAd(ad, didReceiveEvent: event)
                case .error(let message):
                    print("[InlineAd]: Error: \(message)")
                case .unknown(let data):
                    break
                }
            }
        }
    }
}

public class InlineAd: WKWebView {
    private let config: AdConfig
    private let webConfiguration = WKWebViewConfiguration()
    private var scriptHandler: InlineAdScriptMessageHandler?

    public weak var adDelegate: InlineAdDelegate?

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
        scriptHandler = nil

        MainActor.assumeIsolated {
            webConfiguration.userContentController.removeScriptMessageHandler(forName: "iframeMessage")
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
    private var onEvent: ((InlineAdEvent) -> Void)? = nil

    public init(config: AdConfig,
                onEvent: ((InlineAdEvent) -> Void)? = nil) {
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
        public func inlineAd(_ inlineAd: InlineAd, didReceiveEvent event: InlineAdEvent) {
            parent.onEvent?(event)
        }
    }
}
