# KontextSDK

A Swift SDK for integrating ads into chat applications with seamless iframe support and type-safe event handling.

## Overview

KontextSDK provides a robust solution for integrating ads into chat applications. It handles the preloading of ad data, manages race conditions between user and assistant messages, and provides a type-safe event system for iframe interactions.

## Key Features

- **🔄 Race Condition Handling**: Automatically waits for preload responses when assistant messages arrive too quickly
- **⚡ Async/Await Support**: Modern Swift concurrency with proper timeout handling
- **🎯 Type-Safe Events**: Enum-based event system with structured data objects
- **📱 SwiftUI Integration**: Native SwiftUI components for displaying ads
- **🛡️ Error Handling**: Comprehensive error logging and automatic retry mechanisms
- **🎨 Theme Support**: Light and dark theme support for ads
- **📊 Event Tracking**: Built-in support for ad view and click tracking

## Installation

Add KontextSDK to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/kontextso/sdk-swift", from: "1.0.0")
]
```

## Quick Start

### Basic Setup

```swift
import KontextSDK

let adsProvider = AdsProvider(
    messages: [],
    publisherToken: "your-publisher-token",
    userId: "user-123",
    conversationId: "conversation-456",
    enabledPlacementCodes: ["placement1", "placement2"],
    theme: .light
)
```

### Simple Usage

```swift
// Send user message (triggers preload)
let userMessage = ChatMessage(
    id: UUID().uuidString,
    role: .user,
    content: "Hello"
)
await adsProvider.addMessage(userMessage)

// Receive assistant message (waits for preload if needed)
let assistantMessage = ChatMessage(
    id: UUID().uuidString,
    role: .assistant,
    content: "Hi there!"
)
if let adConfigs = await adsProvider.addMessage(assistantMessage) {
    // Display ads
    displayAds(adConfigs)
}
```

## Core Components

### AdsProvider

The main class that manages ad preloading and configuration generation.

```swift
public class AdsProvider {
    // Add message and get ad configurations
    public func addMessage(_ message: ChatMessage) async -> [AdConfig]?
}
```

### InlineAd

A WKWebView-based component for displaying ads with type-safe event handling.

```swift
public class InlineAd: WKWebView {
    public weak var adDelegate: InlineAdDelegate?
}
```

### InlineAdEvent

A comprehensive enum-based event system for handling iframe interactions.

```swift
public enum InlineAdEvent {
    case viewIframe(ViewIframeData)
    case clickIframe(ClickIframeData)
    case resizeIframe(ResizeIframeData)
}
```

## Event System

### Structured Event Data

Each event type has its own structured data object:

```swift
// View event data
public struct ViewIframeData {
    public let id: String
    public let content: String
    public let messageId: String
    public let url: String
}

// Click event data
public struct ClickIframeData {
    public let id: String
    public let content: String
}

// Resize event data
public struct ResizeIframeData {
    public let height: CGFloat
}
```

### Event Handling

```swift
InlineAdView(config: config) { event in
    switch event {
    case .viewIframe(let viewData):
        print("Ad viewed - ID: \(viewData.id), URL: \(viewData.url)")
        
    case .clickIframe(let clickData):
        print("Ad clicked - ID: \(clickData.id)")
        // Open URL in browser
        
    case .resizeIframe(let resizeData):
        print("Ad resized to height: \(resizeData.height)")
        // Update web view height if needed
    }
}
```

### Event Properties

Access event data through convenient properties:

```swift
let bidId = event.bidId
let messageId = event.messageId
let url = event.url
let height = event.height
let content = event.content
let errorMessage = event.errorMessage
```

## SwiftUI Integration

### Basic Chat View

```swift
import SwiftUI

struct ChatView: View {
    @State private var adsProvider: AdsProvider
    @State private var messages: [ChatMessage] = []
    @State private var messageAds: [[AdConfig]] = [[]]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages, id: \.id) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            // Message content
                            Text(message.content)
                                .padding()
                                .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            
                            // Ads for assistant messages
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
            
        case .clickIframe(let clickData):
            print("Ad clicked for message \(messageId) - ID: \(clickData.id)")
            
        case .resizeIframe(let resizeData):
            print("Ad resized for message \(messageId) to height: \(resizeData.height)")
            
        default: break
        }
    }
    
    private func sendMessage() {
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
        let assistantMessage = ChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: "I'm doing well, thank you for asking!"
        )
        
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
```

## Configuration

### AdsProvider Initialization

```swift
let adsProvider = AdsProvider(
    messages: [],                    // Initial messages
    publisherToken: "token",         // Your publisher token
    userId: "user-id",              // Unique user identifier
    conversationId: "conv-id",      // Conversation identifier
    enabledPlacementCodes: ["code"], // Enabled ad placements
    character: character,            // Optional character info
    variantId: "variant",           // Optional variant ID
    advertisingId: "ad-id",         // Optional advertising ID
    vendorId: "vendor-id",          // Optional vendor ID
    sessionId: "session-id",        // Optional session ID
    isDisabled: false,              // Disable ads if needed
    adServerUrl: "https://serverURL.com", // Custom server URL
    theme: .light                   // Theme for ads
)
```

### Theme Configuration

```swift
adsProvider.theme = .dark // or .light
```

## Race Condition Solution

The SDK automatically handles the race condition where assistant messages arrive before the preload API call completes:

1. **Automatic Waiting**: When `addMessage` is called with an assistant message, it waits for the preload response
2. **Timeout Protection**: 5-second timeout prevents infinite waiting
3. **Immediate Response**: If preload is already complete, ad configs are returned immediately
4. **Error Handling**: Failed preloads are logged and handled gracefully

## Error Handling

The SDK provides comprehensive error handling:

- **Automatic Logging**: All errors are logged with `[AdsProvider]` prefix
- **Server Reporting**: Errors are automatically sent to the server
- **Graceful Degradation**: Failed preloads don't crash the app
- **Timeout Protection**: Prevents infinite waiting for responses

## Event Types

### View Events
- **Trigger**: When an ad is viewed by the user
- **Data**: Bid ID, content, message ID, and URL
- **Use Case**: Analytics tracking, impression counting

### Click Events
- **Trigger**: When an ad is clicked by the user
- **Data**: Bid ID and content
- **Use Case**: Click tracking, URL opening

### Resize Events
- **Trigger**: When the iframe height changes
- **Data**: New height in points
- **Use Case**: Dynamic web view sizing

## Support

For support and questions, please refer to the documentation or create an issue in the repository. 