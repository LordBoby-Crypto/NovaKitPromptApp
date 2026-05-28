import Foundation

struct FileAttachment: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var sizeBytes: Int
    var textPreview: String
    var capturedAt = Date()

    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension.lowercased()
    }

    var isLikelyText: Bool {
        !textPreview.hasPrefix("[Binary or unsupported text encoding")
    }
}

struct ConversationEntry: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case starterPrompt
        case aiResponse
        case followUpPrompt
        case novaGuidance
    }

    var id = UUID()
    var role: Role
    var title: String
    var text: String
    var attachments: [FileAttachment] = []
    var createdAt = Date()

    var suggestedPrompt: String?
    var summary: String?
}

struct Conversation: Identifiable, Codable, Equatable {
    static let currentSchemaVersion = 2

    var id = UUID()
    var schemaVersion: Int = currentSchemaVersion
    var title: String
    var userGoal: String = ""
    var promptType: PromptType = .auto
    var entries: [ConversationEntry] = []
    var updatedAt = Date()
    var createdAt = Date()
    var tags: [String] = []
    var folderName: String = "Inbox"
    var isArchived: Bool = false
    var pinnedPromptTemplateID: String?

    init(
        id: UUID = UUID(),
        schemaVersion: Int = Conversation.currentSchemaVersion,
        title: String,
        userGoal: String = "",
        promptType: PromptType = .auto,
        entries: [ConversationEntry] = [],
        updatedAt: Date = Date(),
        createdAt: Date = Date(),
        tags: [String] = [],
        folderName: String = "Inbox",
        isArchived: Bool = false,
        pinnedPromptTemplateID: String? = nil
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.title = title
        self.userGoal = userGoal
        self.promptType = promptType
        self.entries = entries
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.tags = tags
        self.folderName = folderName
        self.isArchived = isArchived
        self.pinnedPromptTemplateID = pinnedPromptTemplateID
    }

    private enum CodingKeys: String, CodingKey {
        case id, schemaVersion, title, userGoal, promptType, entries, updatedAt, createdAt, tags, folderName, isArchived, pinnedPromptTemplateID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        title = try container.decode(String.self, forKey: .title)
        userGoal = try container.decodeIfPresent(String.self, forKey: .userGoal) ?? ""
        promptType = try container.decodeIfPresent(PromptType.self, forKey: .promptType) ?? .auto
        entries = try container.decodeIfPresent([ConversationEntry].self, forKey: .entries) ?? []
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? updatedAt
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        folderName = try container.decodeIfPresent(String.self, forKey: .folderName) ?? "Inbox"
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        pinnedPromptTemplateID = try container.decodeIfPresent(String.self, forKey: .pinnedPromptTemplateID)

        migrateIfNeeded()
    }

    mutating func migrateIfNeeded() {
        if schemaVersion < Conversation.currentSchemaVersion {
            if folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { folderName = "Inbox" }
            tags = Array(Set(tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted()
            schemaVersion = Conversation.currentSchemaVersion
        }
    }
}

enum PromptType: String, CaseIterable, Identifiable, Codable {
    case auto = "Auto Select"
    case minecraftPluginPlan = "Minecraft Plugin Plan Sheet"
    case codeReview = "Code / Plugin Review"
    case featureExpansion = "Feature Expansion"
    case bugFix = "Bug Fix Plan"
    case projectPlan = "Project Plan"
    case researchBrief = "Research Brief"
    case appUpgrade = "App Upgrade Plan"
    case general = "General NovaKit Prompt"

    var id: String { rawValue }
}

struct PromptTemplate: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var type: PromptType
    var instructions: String

    static let builtIns: [PromptTemplate] = [
        PromptTemplate(id: "novakit-general", name: "NovaKit General", type: .general, instructions: "Use the strongest fitting NovaKit utility and produce a practical answer."),
        PromptTemplate(id: "app-upgrade", name: "App Upgrade", type: .appUpgrade, instructions: "Use product design, implementation planning, testing, release, and update-risk checks."),
        PromptTemplate(id: "minecraft-plan", name: "Minecraft Plugin", type: .minecraftPluginPlan, instructions: "Prefer Paper API, Java 21, Maven, Lombok, and Oraxen-aware design when relevant."),
        PromptTemplate(id: "bug-fix", name: "Bug Fix", type: .bugFix, instructions: "Focus on reproduction, root causes, evidence, exact fixes, and verification."),
        PromptTemplate(id: "code-review", name: "Code Review", type: .codeReview, instructions: "Use hard-nosed realism and Response Reviewer before final output.")
    ]
}

struct PromptPreferences: Codable, Equatable {
    var preferredTemplateID: String = PromptTemplate.builtIns.first?.id ?? "novakit-general"
    var includeAttachmentAnalysis: Bool = true
    var includeStepByStepPlan: Bool = true
    var includeCopyReadyPrompt: Bool = true
    var maxHistoryEntries: Int = 10
}

struct ConversationBackup: Codable, Equatable {
    static let currentBackupVersion = 2

    var backupVersion: Int = ConversationBackup.currentBackupVersion
    var exportedAt: Date = Date()
    var appName: String = "NovaKit Prompt App"
    var conversations: [Conversation]
    var promptPreferences: PromptPreferences = PromptPreferences()
}
