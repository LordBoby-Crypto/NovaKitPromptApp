import Foundation

struct NovaKitBackupEnvelope: Codable, Equatable {
    var schemaVersion: Int = 2
    var exportedAt: Date = Date()
    var appName: String = "NovaKit Prompt App"
    var conversations: [Conversation]
    var folders: [ConversationFolder] = []
}

enum BackupCodec {
    static let currentSchemaVersion = 2

    static func export(conversations: [Conversation], folders: [ConversationFolder]) -> String {
        let envelope = NovaKitBackupEnvelope(
            schemaVersion: currentSchemaVersion,
            exportedAt: Date(),
            conversations: conversations.map(migrated),
            folders: folders
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(envelope) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func `import`(_ text: String) throws -> NovaKitBackupEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = Data(text.utf8)

        if let envelope = try? decoder.decode(NovaKitBackupEnvelope.self, from: data) {
            return normalized(envelope)
        }

        let legacyConversations = try decoder.decode([Conversation].self, from: data)
        return normalized(NovaKitBackupEnvelope(conversations: legacyConversations))
    }

    static func migrated(_ conversation: Conversation) -> Conversation {
        var migrated = conversation
        migrated.schemaVersion = currentSchemaVersion
        migrated.tags = Array(Set(migrated.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted()
        migrated.templateConfig.maxHistoryEntries = max(1, migrated.templateConfig.maxHistoryEntries)
        migrated.templateConfig.maxHistoryCharacters = max(500, migrated.templateConfig.maxHistoryCharacters)
        migrated.templateConfig.maxAttachmentCharacters = max(1_000, migrated.templateConfig.maxAttachmentCharacters)
        return migrated
    }

    private static func normalized(_ envelope: NovaKitBackupEnvelope) -> NovaKitBackupEnvelope {
        var normalized = envelope
        normalized.schemaVersion = currentSchemaVersion
        normalized.conversations = deduplicated(normalized.conversations.map(migrated))
        normalized.folders = deduplicatedFolders(normalized.folders)
        return normalized
    }

    private static func deduplicated(_ conversations: [Conversation]) -> [Conversation] {
        var seen = Set<UUID>()
        return conversations.map { conversation in
            var copy = conversation
            if seen.contains(copy.id) { copy.id = UUID() }
            seen.insert(copy.id)
            return copy
        }
    }

    private static func deduplicatedFolders(_ folders: [ConversationFolder]) -> [ConversationFolder] {
        var seen = Set<UUID>()
        return folders.map { folder in
            var copy = folder
            if seen.contains(copy.id) { copy.id = UUID() }
            seen.insert(copy.id)
            return copy
        }
    }
}
