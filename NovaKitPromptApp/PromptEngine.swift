import Foundation

struct PromptGuidance: Equatable {
    var explanation: String
    var responsePrompt: String
    var inferredType: PromptType
}

enum PromptEngine {
    static func makeStarter(goal: String, type: PromptType, config: PromptTemplateConfig = .default) -> String {
        let cleanGoal = cleaned(goal, fallback: "Help me define the next useful NovaKit task.")
        let selected = type == .auto ? inferType(from: cleanGoal) : type
        let utilities = utilityBlock(config: config)

        switch selected {
        case .minecraftPluginPlan:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Create a practical plan sheet for building this Minecraft plugin:

\(cleanGoal)

The output must include:
1. Plugin concept summary.
2. Target server version and assumptions.
3. Player-facing features.
4. Admin commands and permissions.
5. Config files and example config sections.
6. Event/listener systems needed.
7. Data storage needs.
8. Compatibility concerns for Paper, Java 21, Maven, Lombok, and optional Oraxen integration.
9. Development phases in build order.
10. Testing checklist.
11. Risks, edge cases, and things to clarify before coding.

Do not write code yet unless code is specifically requested. Make the plan clear enough that a developer can build from it.
"""
        case .codeReview:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Review the supplied code, files, or plugin idea with hard-nosed realism.

Goal:
\(cleanGoal)

Return:
1. What is working.
2. What is broken or risky.
3. Missing files or missing context.
4. Exact recommended fixes.
5. Full replacement files only when needed.
6. A short next-action checklist.
"""
        case .featureExpansion:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Use Spechammer and Constraints Analysis to expand this into a clean feature design:
\(cleanGoal)

Return a structured implementation brief with feature scope, user flow, config needs, commands, permissions, data model, edge cases, and build phases.
"""
        case .bugFix:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Analyze this bug or issue:
\(cleanGoal)

Return likely causes, evidence needed, reproduction steps, exact fixes to try, files/logs to inspect next, and a verification checklist.
"""
        case .releasePlan:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Create an update/release plan for:
\(cleanGoal)

Include versioning, migration risks, build commands, signing/distribution steps, rollback plan, user-facing release notes, and post-release checks.
"""
        case .appStorePrep:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Prepare this iOS app/TestFlight/App Store task:
\(cleanGoal)

Return metadata, signing requirements, privacy notes, screenshots/assets needed, GitHub Actions/Fastlane checks, and exact next setup actions.
"""
        case .architecturePlan:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Create an architecture plan for:
\(cleanGoal)

Include modules, data flow, persistence, UI flow, test strategy, migration strategy, risks, and build phases.
"""
        case .fileExplanation:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Explain the supplied AI-created files and response for this task:
\(cleanGoal)

Return what each file likely does, how they work together, what to copy/use next, and the safest next prompt to send.
"""
        case .general, .auto:
            return baseHeader(task: cleanGoal, config: config) + """

Run NovaKit v3.1 as Nova.

\(utilities)

Turn this request into the strongest useful output:
\(cleanGoal)

Use the relevant NovaKit v3.1 utility or mode, explain which one you used briefly, then produce the answer in a clean, practical format.
"""
        }
    }

    static func makeGuidance(conversation: Conversation, latestAIResponse: String, attachments: [FileAttachment], optionalInstruction: String = "") -> PromptGuidance {
        let cleanResponse = cleaned(latestAIResponse, fallback: "No pasted AI response was provided.")
        let cleanInstruction = optionalInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let inferred = conversation.promptType == .auto ? inferType(from: conversation.userGoal + "\n" + cleanResponse + "\n" + attachments.map(\.name).joined(separator: " ")) : conversation.promptType
        let config = conversation.templateConfig
        let historyLimit = max(1, config.maxHistoryEntries)
        let historyMax = max(500, config.maxHistoryCharacters)
        let attachmentMax = max(1_000, config.maxAttachmentCharacters)

        let previousPrompts = conversation.entries.suffix(historyLimit).map { entry in
            "## \(entry.role.rawValue) - \(entry.title)\n\(truncate(entry.text, max: historyMax))"
        }.joined(separator: "\n\n")

        let attachmentBlock = attachments.isEmpty ? "No files were attached." : attachments.map { file in
            """
            ### Attached file: \(file.name)
            Size: \(file.sizeBytes) bytes
            Captured text:
            \(truncate(file.textPreview, max: attachmentMax))
            """
        }.joined(separator: "\n\n")

        let explanation = makeLocalExplanation(response: cleanResponse, attachments: attachments, inferredType: inferred)
        let utilities = utilityBlock(config: config)
        let responsePrompt = """
        Run NovaKit v3.1 as Nova.

        Continue the same work thread. Use the prior prompt history, the AI response I pasted, and the attached file contents together. Do not ignore attached files.

        \(utilities)

        # My next instruction
        \(cleanInstruction.isEmpty ? "Explain what the AI response and attached files mean, identify what I should use next, and produce the best next response prompt/output." : cleanInstruction)

        # Conversation goal
        \(cleaned(conversation.userGoal, fallback: conversation.title))

        # Recent saved prompt/history context
        \(previousPrompts.isEmpty ? "No previous prompt history was saved." : previousPrompts)

        # AI response I received
        \(cleanResponse)

        # Files produced by the AI / attached for this step
        \(attachmentBlock)

        # Required behavior
        - Explain what changed and what the attached files appear to mean.
        - Tell me exactly what to copy, save, run, or ask next.
        - Base the response on both the pasted AI response and the attached files.
        - If code/config files are attached, inspect them as actual source context.
        - Point out contradictions between the response and the files.
        - If files are missing, say exactly what is missing.
        - End with one polished next prompt I can send back if another round is needed.
        \(config.preferMinecraftDefaults ? "- If continuing a Minecraft plugin task, prefer Java 21, Paper API, Maven, Lombok, and Oraxen-aware design when relevant." : "")
        """

        return PromptGuidance(explanation: explanation, responsePrompt: responsePrompt, inferredType: inferred)
    }

    static func inferType(from text: String) -> PromptType {
        let lower = text.lowercased()
        if lower.contains("testflight") || lower.contains("app store") || lower.contains("fastlane") || lower.contains("signing") { return .appStorePrep }
        if lower.contains("release") || lower.contains("update") || lower.contains("upgrade") || lower.contains("version") { return .releasePlan }
        if lower.contains("architecture") || lower.contains("data model") || lower.contains("schema") || lower.contains("migration") { return .architecturePlan }
        if lower.contains("minecraft") || lower.contains("paper plugin") || lower.contains("plugin") { return .minecraftPluginPlan }
        if lower.contains("attach") || lower.contains("file") || lower.contains("explain") { return .fileExplanation }
        if lower.contains("bug") || lower.contains("error") || lower.contains("crash") || lower.contains("fix") { return .bugFix }
        if lower.contains("review") || lower.contains("check") { return .codeReview }
        if lower.contains("add") || lower.contains("feature") || lower.contains("expand") { return .featureExpansion }
        return .general
    }

    private static func makeLocalExplanation(response: String, attachments: [FileAttachment], inferredType: PromptType) -> String {
        let attachmentSummary: String
        if attachments.isEmpty {
            attachmentSummary = "No files are attached for this turn. The next prompt will rely on the pasted AI response and saved conversation history."
        } else {
            let fileLines = attachments.map { file in
                "- \(file.name) (\(file.sizeBytes) bytes): \(file.textPreview.isEmpty ? "No readable preview captured." : "Readable text preview captured for NovaKit context.")"
            }.joined(separator: "\n")
            attachmentSummary = "Attached files captured for the next NovaKit round:\n\(fileLines)"
        }

        return """
        Saved this AI turn and prepared a NovaKit-ready response prompt.

        Detected mode: \(inferredType.rawValue)
        Response captured: \(response.count) characters

        \(attachmentSummary)

        What to do next:
        1. Review the generated NovaKit response prompt below.
        2. Copy or share it into your AI chat.
        3. Paste the next AI answer back here with any new files it creates.

        This keeps the workflow like a chat history instead of making you reuse separate starter/response/follow-up boxes.
        """
    }

    private static func baseHeader(task: String, config: PromptTemplateConfig) -> String {
        guard config.includeNovaKitHeader else { return "User request: \(task)" }
        return """
        # NovaKit v3.1 Prompt
        You are receiving a user request that should be handled with NovaKit v3.1 behavior.
        User request: \(task)
        """
    }

    private static func utilityBlock(config: PromptTemplateConfig) -> String {
        var lines = ["Use the NovaKit v3.1 utilities as needed."]
        if config.includeConstraintsAnalysis { lines.append("- Use Constraints Analysis for limits, risks, dependencies, and tradeoffs.") }
        if config.includeResponseReviewer { lines.append("- Use Response Reviewer before final output.") }
        lines.append("- Prefer direct, practical output with clear next actions.")
        return lines.joined(separator: "\n")
    }

    private static func cleaned(_ text: String, fallback: String) -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }

    private static func truncate(_ text: String, max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max)) + "\n...[truncated]"
    }
}
