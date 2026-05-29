import XCTest
@testable import NovaKitPromptAppCore

final class PromptEngineTests: XCTestCase {
    func testAutoDetectsAppStorePrep() {
        let prompt = PromptEngine.makeStarter(goal: "Fix TestFlight signing and Fastlane upload", type: .auto)
        XCTAssertTrue(prompt.contains("App Store"))
        XCTAssertTrue(prompt.contains("Fastlane"))
    }

    func testGuidanceIncludesAttachmentsAndHistory() {
        var conversation = Conversation(title: "Plugin Work", userGoal: "Build a Minecraft plugin", promptType: .auto)
        conversation.entries.append(ConversationEntry(role: .starterPrompt, title: "Starter", text: "Plan the plugin"))
        let attachment = FileAttachment(name: "plugin.yml", sizeBytes: 42, textPreview: "name: TestPlugin")

        let guidance = PromptEngine.makeGuidance(
            conversation: conversation,
            latestAIResponse: "I created the plugin.yml file.",
            attachments: [attachment]
        )

        XCTAssertEqual(guidance.inferredType, .minecraftPluginPlan)
        XCTAssertTrue(guidance.explanation.contains("plugin.yml"))
        XCTAssertTrue(guidance.responsePrompt.contains("name: TestPlugin"))
        XCTAssertTrue(guidance.responsePrompt.contains("Plan the plugin"))
    }

    func testBuildWordDoesNotTripAppUpgradeHeuristic() {
        XCTAssertEqual(
            PromptEngine.inferType(from: "Build a Minecraft plugin"),
            .minecraftPluginPlan
        )
    }
}
