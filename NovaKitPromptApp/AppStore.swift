import Foundation
import SwiftUI

final class AppStore: ObservableObject {
    @Published var conversations: [Conversation] = [] {
        didSet { save() }
    }

    @Published var selectedID: UUID?

    private let storageKey = "NovaKitPromptApp.conversations.v1"

    init() {
        load()
        if conversations.isEmpty { createConversation() }
        selectedID = conversations.first?.id
    }

    var selectedConversation: Conversation? {
        get { conversations.first(where: { $0.id == selectedID }) }
        set {
            guard let newValue, let index = conversations.firstIndex(where: { $0.id == newValue.id }) else { return }
            conversations[index] = newValue
        }
    }

    func createConversation() {
        let c = Conversation(title: "New NovaKit Conversation")
        conversations.insert(c, at: 0)
        selectedID = c.id
    }

    func duplicate(_ conversation: Conversation) {
        var copy = conversation
        copy.id = UUID()
        copy.title += " Copy"
        copy.updatedAt = Date()
        conversations.insert(copy, at: 0)
        selectedID = copy.id
    }

    func delete(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if selectedID == conversation.id { selectedID = conversations.first?.id }
        if conversations.isEmpty { createConversation() }
    }

    func update(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        var updated = conversation
        updated.updatedAt = Date()
        conversations[idx] = updated
    }

    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(conversations) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    func importJSON(_ text: String) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = text.data(using: .utf8) else { return }
        let imported = try decoder.decode([Conversation].self, from: data)
        conversations = imported
        selectedID = conversations.first?.id
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Conversation].self, from: data) { conversations = decoded }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(conversations) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
}
