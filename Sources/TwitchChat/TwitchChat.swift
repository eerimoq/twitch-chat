import Foundation
import os

public final class TwitchChat {
    public init(token: String, nick: String, name: String) {
        messages = ChatMessageStream { continuation in
            let session = APIDataSession(token: token, nick: nick, name: name)
            Task.detached {
                for try await line in session.lines {
                    let message = try Message(string: line)

                    if let chatMessage = ChatMessage(message) {
                        continuation.yield(chatMessage)
                    } else if message.command == .ping {
                        try await session.send("PONG \(message.parameters.joined(separator: " "))")
                    } else {
                        Logger().debug("twitch-chat: Unknown message \(line)")
                    }
                }
                continuation.finish()
            }
        }
    }

    public typealias ChatMessageStream = AsyncThrowingStream<ChatMessage, Error>
    public let messages: ChatMessageStream
}
