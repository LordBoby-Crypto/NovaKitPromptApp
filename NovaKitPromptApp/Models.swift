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
        case guidance
    }

    var id = UUID()
    var role: Role
    var title: String
    var text: String
    var attachments: [FileAttachment] = []
    var createdAt = Date()
}

struct ConversationFolder: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var colorName: String = "blue"
    var createdAt = Date()
}

struct PromptTemplateConfig: Codable, Equatable {
    var includeNovaKitHeader: Bool = true
    var includeResponseReviewer: Bool = true
    var includeConstraintsAnalysis: Bool = true
    var preferMinecraftDefaults: Bool = true
    var maxHistoryEntries: Int = 10
    var maxHistoryCharacters: Int = 4_000
    var maxAttachmentCharacters: Int = 14_000

    static let `default` = PromptTemplateConfig()
}

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var schemaVersion: Int = 2
    var title: String
    var userGoal: String = ""
    var promptType: PromptType = .auto
    var entries: [ConversationEntry] = []
    var tags: [String] = []
    var folderName: String = "Inbox"
    var folderID: UUID?
    var isArchived: Bool = false
    var templateConfig: PromptTemplateConfig = .default
    var createdAt = Date()
    var updatedAt = Date()

    init(
        id: UUID = UUID(),
        schemaVersion: Int = 2,
        title: String,
        userGoal: String = "",
        promptType: PromptType = .auto,
        entries: [ConversationEntry] = [],
        tags: [String] = [],
        folderName: String = "Inbox",
        folderID: UUID? = nil,
        isArchived: Bool = false,
        templateConfig: PromptTemplateConfig = .default,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.title = title
        self.userGoal = userGoal
        self.promptType = promptType
        self.entries = entries
        self.tags = tags
        self.folderName = folderName
        self.folderID = folderID
        self.isArchived = isArchived
        self.templateConfig = templateConfig
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, schemaVersion, title, userGoal, promptType, entries, tags, folderName, folderID, isArchived, templateConfig, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Imported NovaKit Conversation"
        userGoal = try container.decodeIfPresent(String.self, forKey: .userGoal) ?? ""
        promptType = try container.decodeIfPresent(PromptType.self, forKey: .promptType) ?? .auto
        entries = try container.decodeIfPresent([ConversationEntry].self, forKey: .entries) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        folderName = try container.decodeIfPresent(String.self, forKey: .folderName) ?? "Inbox"
        folderID = try container.decodeIfPresent(UUID.self, forKey: .folderID)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        templateConfig = try container.decodeIfPresent(PromptTemplateConfig.self, forKey: .templateConfig) ?? .default
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        schemaVersion = 2
    }
}

enum PromptType: String, CaseIterable, Identifiable, Codable {
    case auto = "Auto Select"
    case minecraftPluginPlan = "Minecraft Plugin Plan Sheet"
    case codeReview = "Code / Plugin Review"
    case featureExpansion = "Feature Expansion"
    case bugFix = "Bug Fix Plan"
    case releasePlan = "Release / Update Plan"
    case appStorePrep = "App Store / TestFlight Prep"
    case architecturePlan = "Architecture Plan"
    case fileExplanation = "Explain AI Files"
    case general = "General NovaKit Prompt"

    var id: String { rawValue }
}
