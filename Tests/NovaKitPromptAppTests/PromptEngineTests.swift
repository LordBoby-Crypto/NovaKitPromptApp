import XCTest
@testable import NovaKitPromptAppCore

final class PromptEngineTests: XCTestCase {
    func testAutoDetectsAppUpgradePrompt() {
        let prompt = PromptEngine.makeStarter(goal: "Upgrade this iOS app UI and TestFlight release flow", type: .auto)

        XCTAssertTrue(prompt.contains("app upgrade plan"))
        XCTAssertTrue(prompt.contains("Build/release/update strategy"))
    }

    func testGuidanceIncludesAttachmentsAndCopyReadyPrompt() {
        let attachment = FileAttachment(name: "Config.swift", sizeBytes: 42, textPreview: "let value = true")
        let conversation = Conversation(title: "Upgrade thread", userGoal: "Improve the app")

        let guidance = PromptEngine.makeAIResponseGuidance(
            conversation: conversation,
            latestAIResponse: "Here is the implementation.",
            attachments: [attachment]
        )

        XCTAssertTrue(guidance.summary.contains("Config.swift"))
        XCTAssertTrue(guidance.suggestedPrompt.contains("Attached file: Config.swift"))
        XCTAssertTrue(guidance.fullText.contains("Recommended NovaKit response prompt"))
    }

    func testBackupRoundTripKeepsSchemaAndPreferences() throws {
        let conversation = Conversation(title: "Backup", tags: ["ios"], folderName: "Release")
        let backup = ConversationBackup(conversations: [conversation], promptPreferences: PromptPreferences(maxHistoryEntries: 6))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ConversationBackup.self, from: data)

        XCTAssertEqual(decoded.backupVersion, ConversationBackup.currentBackupVersion)
        XCTAssertEqual(decoded.conversations.first?.schemaVersion, Conversation.currentSchemaVersion)
        XCTAssertEqual(decoded.conversations.first?.folderName, "Release")
        XCTAssertEqual(decoded.promptPreferences.maxHistoryEntries, 6)
    }

    func testLegacyConversationMigrationAddsDefaults() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "title": "Legacy",
          "updatedAt": "2026-05-28T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(Conversation.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.schemaVersion, Conversation.currentSchemaVersion)
        XCTAssertEqual(decoded.folderName, "Inbox")
        XCTAssertFalse(decoded.isArchived)
    }
}
