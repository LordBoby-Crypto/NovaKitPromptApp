import Foundation
import SwiftUI

final class AppStore: ObservableObject {
    @Published var conversations: [Conversation] = [] {
        didSet { save() }
    }

    @Published var folders: [ConversationFolder] = [] {
        didSet { save() }
    }

    @Published var selectedID: UUID?
    @Published var showingArchived = false

    private let storageKey = "NovaKitPromptApp.backupEnvelope.v2"
    private let legacyStorageKey = "NovaKitPromptApp.conversations.v1"

    init() {
        loadPreferences()
        load()
        if conversations.isEmpty { createConversation() }
        selectedID = visibleConversations.first?.id ?? conversations.first?.id
    }

    var visibleConversations: [Conversation] {
        conversations
            .filter { showingArchived ? $0.isArchived : !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
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
        if selectedID == conversation.id { selectedID = visibleConversations.first?.id ?? conversations.first?.id }
        if conversations.isEmpty { createConversation() }
    }

    func archive(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[idx].isArchived = true
        conversations[idx].updatedAt = Date()
        if selectedID == conversation.id { selectedID = visibleConversations.first?.id }
    }

    func unarchive(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[idx].isArchived = false
        conversations[idx].updatedAt = Date()
        selectedID = conversation.id
    }

    func update(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        var updated = BackupCodec.migrated(conversation)
        updated.updatedAt = Date()
        conversations[idx] = updated
    }

    func exportJSON() -> String {
        BackupCodec.export(conversations: conversations, folders: folders)
    }

    func importJSON(_ text: String) throws {
        let imported = try BackupCodec.import(text)
        conversations = imported.conversations
        folders = imported.folders
        selectedID = visibleConversations.first?.id ?? conversations.first?.id
        if conversations.isEmpty { createConversation() }
    }

    private func load() {
        if let text = UserDefaults.standard.string(forKey: storageKey), let imported = try? BackupCodec.import(text) {
            conversations = imported.conversations
            folders = imported.folders
            return
        }

        guard let data = UserDefaults.standard.data(forKey: legacyStorageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Conversation].self, from: data) {
            conversations = decoded.map(BackupCodec.migrated)
            folders = []
        }
    }

    private func save() {
        let text = BackupCodec.export(conversations: conversations, folders: folders)
        UserDefaults.standard.set(text, forKey: storageKey)
    }
}
