import Foundation

struct FileAttachment: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var sizeBytes: Int
    var textPreview: String
    var capturedAt = Date()
}

struct ConversationEntry: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case starterPrompt
        case aiResponse
        case followUpPrompt
    }

    var id = UUID()
    var role: Role
    var title: String
    var text: String
    var attachments: [FileAttachment] = []
    var createdAt = Date()
}

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var userGoal: String = ""
    var promptType: PromptType = .auto
    var entries: [ConversationEntry] = []
    var updatedAt = Date()
}

enum PromptType: String, CaseIterable, Identifiable, Codable {
    case auto = "Auto Select"
    case minecraftPluginPlan = "Minecraft Plugin Plan Sheet"
    case codeReview = "Code / Plugin Review"
    case featureExpansion = "Feature Expansion"
    case bugFix = "Bug Fix Plan"
    case general = "General NovaKit Prompt"

    var id: String { rawValue }
}
