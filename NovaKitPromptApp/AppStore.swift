import Foundation
import SwiftUI

final class AppStore: ObservableObject {
    @Published var conversations: [Conversation] = [] {
        didSet { save() }
    }

    @Published var selectedID: UUID?
    @Published var preferences = PromptPreferences() {
        didSet { savePreferences() }
    }

    private let storageKey = "NovaKitPromptApp.conversations.v2"
    private let legacyStorageKey = "NovaKitPromptApp.conversations.v1"
    private let preferencesKey = "NovaKitPromptApp.preferences.v1"

    init() {
        loadPreferences()
        load()
        if conversations.isEmpty { createConversation() }
        selectedID = activeConversations.first?.id ?? conversations.first?.id
    }

    var activeConversations: [Conversation] {
        conversations.filter { !$0.isArchived }
    }

    var archivedConversations: [Conversation] {
        conversations.filter { $0.isArchived }
    }

    var folders: [String] {
        Array(Set(conversations.map { $0.folderName.isEmpty ? "Inbox" : $0.folderName })).sorted()
    }

    var selectedConversation: Conversation? {
        get { conversations.first(where: { $0.id == selectedID }) }
        set {
            guard let newValue, let index = conversations.firstIndex(where: { $0.id == newValue.id }) else { return }
            conversations[index] = newValue
        }
    }

    func createConversation(folderName: String = "Inbox") {
        let c = Conversation(title: "New NovaKit Conversation", folderName: folderName)
        conversations.insert(c, at: 0)
        selectedID = c.id
    }

    func duplicate(_ conversation: Conversation) {
        var copy = conversation
        copy.id = UUID()
        copy.title += " Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.entries = copy.entries.map { entry in
            var copiedEntry = entry
            copiedEntry.id = UUID()
            copiedEntry.attachments = copiedEntry.attachments.map { attachment in
                var copiedAttachment = attachment
                copiedAttachment.id = UUID()
                return copiedAttachment
            }
            return copiedEntry
        }
        conversations.insert(copy, at: 0)
        selectedID = copy.id
    }

    func delete(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if selectedID == conversation.id { selectedID = activeConversations.first?.id ?? conversations.first?.id }
        if conversations.isEmpty { createConversation() }
    }

    func archive(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[idx].isArchived = true
        conversations[idx].updatedAt = Date()
        if selectedID == conversation.id { selectedID = activeConversations.first?.id }
    }

    func restore(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[idx].isArchived = false
        conversations[idx].updatedAt = Date()
        selectedID = conversation.id
    }

    func update(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        var updated = conversation
        updated.migrateIfNeeded()
        updated.updatedAt = Date()
        conversations[idx] = updated
    }

    func exportJSON() -> String {
        let backup = ConversationBackup(conversations: conversations, promptPreferences: preferences)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(backup) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func importJSON(_ text: String) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = text.data(using: .utf8) else { return }

        if let backup = try? decoder.decode(ConversationBackup.self, from: data) {
            conversations = backup.conversations.map { conversation in
                var migrated = conversation
                migrated.migrateIfNeeded()
                return migrated
            }
            preferences = backup.promptPreferences
        } else {
            let imported = try decoder.decode([Conversation].self, from: data)
            conversations = imported.map { conversation in
                var migrated = conversation
                migrated.migrateIfNeeded()
                return migrated
            }
        }

        selectedID = activeConversations.first?.id ?? conversations.first?.id
        if conversations.isEmpty { createConversation() }
    }

    private func load() {
        let data = UserDefaults.standard.data(forKey: storageKey) ?? UserDefaults.standard.data(forKey: legacyStorageKey)
        guard let data else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let backup = try? decoder.decode(ConversationBackup.self, from: data) {
            conversations = backup.conversations.map { conversation in
                var migrated = conversation
                migrated.migrateIfNeeded()
                return migrated
            }
            preferences = backup.promptPreferences
        } else if let decoded = try? decoder.decode([Conversation].self, from: data) {
            conversations = decoded.map { conversation in
                var migrated = conversation
                migrated.migrateIfNeeded()
                return migrated
            }
        }
    }

    private func save() {
        let backup = ConversationBackup(conversations: conversations, promptPreferences: preferences)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(backup) { UserDefaults.standard.set(data, forKey: storageKey) }
    }

    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: preferencesKey) else { return }
        if let decoded = try? JSONDecoder().decode(PromptPreferences.self, from: data) { preferences = decoded }
    }

    private func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) { UserDefaults.standard.set(data, forKey: preferencesKey) }
    }
}
