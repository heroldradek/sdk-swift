import Foundation
import SwiftUI

// Example
public struct ChatView: View {
    @State private var adsProvider: AdsProvider
    @State private var messages: [ChatMessage] = []
    @State private var messageAds: [[AdConfig]] = [[]]

    public init(publisherToken: String, userId: String, conversationId: String) {
        self._adsProvider = State(initialValue: AdsProvider(
            messages: [],
            publisherToken: publisherToken,
            userId: userId,
            conversationId: conversationId,
            enabledPlacementCodes: ["placement1"]
        ))
    }
    
    public var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages, id: \.id) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.content)
                                .padding()
                                .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)

                            if message.role == .assistant {
                               let adConfigs = messageAds.filter { $0.first?.messageId == message.id }.first ?? []
                                ForEach(adConfigs, id: \.messageId) { config in
                                    InlineAdView(config: config) { event in
                                        handleAdEvent(event, for: message.id)
                                    }
                                    .frame(height: 200)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            Button("Send Message") {
                sendMessage()
            }
            .padding()
        }
    }
    
    private func handleAdEvent(_ event: InlineAdEvent, for messageId: String) {
        switch event {
        case .viewIframe(let viewData):
            print("Ad viewed for message \(messageId) - ID: \(viewData.id)")
            // Track ad view analytics
            
        case .clickIframe(let clickData):
            print("Ad clicked for message \(messageId) - ID: \(clickData.id)")
            // Handle ad click - open URL, track analytics
            
        case .resizeIframe(let resizeData):
            print("Ad resized for message \(messageId) to height: \(resizeData.height)")
            // Update web view height if needed
            
        default: break
        }
    }

    private func sendMessage() {
        // Simulate user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: "Hello, how are you?"
        )


        Task {
            await MainActor.run {
                messages.append(userMessage)
            }
            let _ = await adsProvider.addMessage(userMessage)
            // Simulate assistant response
            try await Task.sleep(for: .seconds(1))
            self.handleAssistantResponse()
        }
    }

    private func handleAssistantResponse() {
        // Simulate assistant message
        let assistantMessage = ChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: "I'm doing well, thank you for asking!"
        )

        // Load ads
        Task {
            await MainActor.run {
                messages.append(assistantMessage)
            }
            if let data = await adsProvider.addMessage(assistantMessage) {
                await MainActor.run {
                    messageAds.append(data)
                }
            }
        }
    }
}
