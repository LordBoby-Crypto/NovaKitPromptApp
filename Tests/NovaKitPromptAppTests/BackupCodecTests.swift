import XCTest
@testable import NovaKitPromptAppCore

final class BackupCodecTests: XCTestCase {
    func testExportsVersionedEnvelopeAndImportsIt() throws {
        let conversation = Conversation(title: "Backup Test", tags: ["ios", "novakit"])
        let folder = ConversationFolder(name: "Active")

        let json = BackupCodec.export(conversations: [conversation], folders: [folder])
        XCTAssertTrue(json.contains("schemaVersion"))
        XCTAssertTrue(json.contains("conversations"))

        let imported = try BackupCodec.import(json)
        XCTAssertEqual(imported.schemaVersion, BackupCodec.currentSchemaVersion)
        XCTAssertEqual(imported.conversations.first?.title, "Backup Test")
        XCTAssertEqual(imported.conversations.first?.tags, ["ios", "novakit"])
        XCTAssertEqual(imported.folders.first?.name, "Active")
    }

    func testImportsLegacyConversationArray() throws {
        let legacy = """
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "title": "Legacy",
            "userGoal": "Old backup",
            "promptType": "General NovaKit Prompt",
            "entries": [],
            "updatedAt": "2026-05-28T00:00:00Z"
          }
        ]
        """

        let imported = try BackupCodec.import(legacy)
        XCTAssertEqual(imported.conversations.count, 1)
        XCTAssertEqual(imported.conversations[0].schemaVersion, BackupCodec.currentSchemaVersion)
        XCTAssertEqual(imported.conversations[0].title, "Legacy")
    }
}
