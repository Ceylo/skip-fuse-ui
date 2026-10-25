// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipBridge
import SkipUI

public class INImage {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    init(Java_image: SkipUI.INImage) {
        self.url = Java_image.bridgedURL
    }

    var Java_image: SkipUI.INImage {
        return SkipUI.INImage(url: url)
    }
}

public enum INPersonHandleType : Int, Sendable {
    case unknown = 0
    case emailAddress = 1
    case phoneNumber = 2
}

public class INPersonHandle {
    public let value: String?
    public let type: INPersonHandleType

    public init(value: String?, type: INPersonHandleType) {
        self.value = value
        self.type = type
    }
}

public enum INPersonSuggestionType : Int, Sendable {
    case none = 0
    case socialProfile = 1
    case instantMessageAddress = 2
}

public class INPerson {
    public let personHandle: INPersonHandle?
    public let nameComponents: PersonNameComponents?
    public let displayName: String
    public let image: INImage?
    public let contactIdentifier: String?
    public let customIdentifier: String?
    public let isMe: Bool
    public let suggestionType: INPersonSuggestionType

    public init(personHandle: INPersonHandle, nameComponents: PersonNameComponents?, displayName: String?, image: INImage?, contactIdentifier: String?, customIdentifier: String?, isMe: Bool, suggestionType: INPersonSuggestionType) {
        self.personHandle = personHandle
        self.nameComponents = nameComponents
        self.displayName = displayName ?? personHandle.value ?? ""
        self.image = image
        self.contactIdentifier = contactIdentifier
        self.customIdentifier = customIdentifier
        self.isMe = isMe
        self.suggestionType = suggestionType
    }

    init(Java_person: SkipUI.INPerson) {
        self.personHandle = INPersonHandle(value: Java_person.bridgedHandleValue, type: .unknown)
        self.nameComponents = nil
        self.displayName = Java_person.displayName
        self.image = Java_person.image.map { INImage(Java_image: $0) }
        self.contactIdentifier = nil
        self.customIdentifier = Java_person.customIdentifier
        self.isMe = Java_person.isMe
        self.suggestionType = .none
    }

    func Java_person(image: INImage?) -> SkipUI.INPerson {
        return SkipUI.INPerson(handleValue: personHandle?.value, displayName: displayName, image: image?.Java_image, customIdentifier: customIdentifier, isMe: isMe)
    }
}

public class INSpeakableString {
    public let spokenPhrase: String

    public init(spokenPhrase: String) {
        self.spokenPhrase = spokenPhrase
    }
}

public class INSendMessageAttachment {
    private init() {
    }
}

public class INIntent {
}

public class INIntentResponse {
}

public enum INOutgoingMessageType : Int, Sendable {
    case unknown = 0
    case outgoingMessageText = 1
    case outgoingMessageAudio = 2
}

public class INSendMessageIntent : INIntent, UNNotificationContentProviding {
    public let recipients: [INPerson]?
    public let outgoingMessageType: INOutgoingMessageType
    public let content: String?
    public let speakableGroupName: INSpeakableString?
    public let conversationIdentifier: String?
    public let serviceName: String?
    public let sender: INPerson?
    public let attachments: [INSendMessageAttachment]?
    private var senderImage: INImage?

    public init(recipients: [INPerson]?, outgoingMessageType: INOutgoingMessageType, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?, attachments: [INSendMessageAttachment]?) {
        self.recipients = recipients
        self.outgoingMessageType = outgoingMessageType
        self.content = content
        self.speakableGroupName = speakableGroupName
        self.conversationIdentifier = conversationIdentifier
        self.serviceName = serviceName
        self.sender = sender
        self.attachments = attachments
    }

    init(Java_intent: SkipUI.INSendMessageIntent) {
        self.recipients = Java_intent.recipients?.map { INPerson(Java_person: $0) }
        self.outgoingMessageType = .outgoingMessageText
        self.content = Java_intent.content
        self.speakableGroupName = nil
        self.conversationIdentifier = Java_intent.conversationIdentifier
        self.serviceName = nil
        self.sender = Java_intent.sender.map { INPerson(Java_person: $0) }
        self.attachments = nil
    }

    public func setImage<Value>(_ image: INImage?, forParameterNamed parameterKeyPath: KeyPath<INSendMessageIntent, Value>) {
        if parameterKeyPath == \INSendMessageIntent.sender {
            senderImage = image
        }
    }

    var Java_intent: SkipUI.INSendMessageIntent {
        return SkipUI.INSendMessageIntent(recipients: recipients?.map { $0.Java_person(image: $0.image) }, content: content, conversationIdentifier: conversationIdentifier, sender: sender?.Java_person(image: senderImage ?? sender?.image))
    }
}

public enum INInteractionDirection : Int, Sendable {
    case unspecified = 0
    case outgoing = 1
    case incoming = 2
}

public class INInteraction {
    public let intent: INIntent
    public let intentResponse: INIntentResponse?
    public var direction: INInteractionDirection = .unspecified

    public init(intent: INIntent, response: INIntentResponse?) {
        self.intent = intent
        self.intentResponse = response
    }

    /// A message intent becomes the long-lived shortcut of its conversation; other intents are ignored.
    public func donate() async throws {
        guard let intent = intent as? INSendMessageIntent else {
            return
        }
        let interaction = SkipUI.INInteraction(intent: intent.Java_intent)
        interaction.bridgedDirection = direction.rawValue
        try await interaction.donate()
    }
}
