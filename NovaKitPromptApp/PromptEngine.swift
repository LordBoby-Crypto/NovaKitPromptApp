import Foundation

enum PromptEngine {
    static func makeStarter(goal: String, type: PromptType, preferences: PromptPreferences = PromptPreferences()) -> String {
        let cleanGoal = normalized(goal, fallback: "Help me turn this into a clear, useful next step.")
        let selected = type == .auto ? inferType(from: cleanGoal) : type
        let template = PromptTemplate.builtIns.first { $0.id == preferences.preferredTemplateID }

        switch selected {
        case .minecraftPluginPlan:
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Use the NovaKit v3.1 utilities as needed, especially:
- Spechammer / Architect's Anvil for turning the idea into a practical design brief.
- Constraints Analysis Procedure for limits, risks, dependencies, and tradeoffs.
- Response Reviewer before final output.

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
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Review the supplied code, files, or plugin idea with hard-nosed realism. Use Response Reviewer before final output.

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
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Use Spechammer and Constraints Analysis to expand this into a clean feature design:
\(cleanGoal)

Return a structured implementation brief with feature scope, user flow, config needs, commands, permissions, data model, edge cases, and build phases.
"""
        case .bugFix:
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Analyze this bug or issue:
\(cleanGoal)

Return likely causes, what evidence is needed, how to reproduce, exact fixes to try, what files/logs should be inspected next, and how to verify the fix.
"""
        case .projectPlan:
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Turn this into an implementation-ready project plan:
\(cleanGoal)

Use Constraints Analysis, Spechammer, and Response Reviewer. Return scope, milestones, file/module plan, commands, risks, acceptance criteria, and a short first-pass task list.
"""
        case .researchBrief:
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Create a research brief for:
\(cleanGoal)

Separate known facts, assumptions, open questions, sources needed, likely failure modes, and a copy-ready research prompt for the next AI pass.
"""
        case .appUpgrade:
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Create an app upgrade plan for:
\(cleanGoal)

Return:
1. Product/design diagnosis.
2. Better user flow.
3. Data model changes.
4. UI screens/components.
5. Build/release/update strategy.
6. Tests to add.
7. Migration risks.
8. A copy-ready implementation prompt.
"""
        case .general, .auto:
            return baseHeader(task: cleanGoal, template: template) + """

Run NovaKit v3.1 as Nova.

Turn this request into the strongest useful output:
\(cleanGoal)

Use the relevant NovaKit v3.1 utility or mode, explain which one you used briefly, then produce the answer in a clean, practical format.
"""
        }
    }

    static func makeAIResponseGuidance(conversation: Conversation, latestAIResponse: String, attachments: [FileAttachment], preferences: PromptPreferences = PromptPreferences()) -> (summary: String, suggestedPrompt: String, fullText: String) {
        let cleanResponse = normalized(latestAIResponse, fallback: "No pasted AI response was provided.")
        let attachmentSummary = summarizeAttachments(attachments)
        let recentContext = conversation.entries.suffix(preferences.maxHistoryEntries).map { entry in
            "## \(entry.role.rawValue) - \(entry.title)\n\(truncate(entry.text, max: 2500))"
        }.joined(separator: "\n\n")

        let summary = """
I saved the AI response and \(attachments.count) attachment\(attachments.count == 1 ? "" : "s"). \(attachmentSummary.shortExplanation)
""".trimmingCharacters(in: .whitespacesAndNewlines)

        let suggestedPrompt = """
Run NovaKit v3.1 as Nova.

Continue this exact work thread using the pasted AI response and attached file context below. First explain what the AI response and files mean in practical terms, then produce the best next response or implementation step.

# Current project goal
\(normalized(conversation.userGoal, fallback: conversation.title))

# Recent saved history
\(recentContext.isEmpty ? "No prior saved history." : recentContext)

# AI response I received
\(truncate(cleanResponse, max: 12000))

# Attached files and captured content
\(attachmentSummary.promptBlock)

# Required NovaKit behavior
- Use Response Reviewer before final output.
- Explain what changed, what the files are for, and what I should do next.
- If files are code/config, treat them as source context and call out contradictions.
- If anything is missing, list the exact missing files or details.
- End with one copy-ready prompt or action block I can use next.
"""

        let fullText = """
## What this AI response means
\(plainLanguageExplanation(cleanResponse, attachments: attachments))

## Attachment readout
\(attachmentSummary.longExplanation)

## Recommended NovaKit response prompt
\(suggestedPrompt)
"""

        return (summary, suggestedPrompt, fullText)
    }

    static func makeFollowUp(conversation: Conversation, newInstruction: String, latestAIResponse: String, attachments: [FileAttachment], preferences: PromptPreferences = PromptPreferences()) -> String {
        let guidance = makeAIResponseGuidance(conversation: conversation, latestAIResponse: latestAIResponse, attachments: attachments, preferences: preferences)
        let cleanInstruction = newInstruction.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanInstruction.isEmpty else { return guidance.suggestedPrompt }

        return guidance.suggestedPrompt + """

# Extra instruction from me
\(cleanInstruction)
"""
    }

    private static func baseHeader(task: String, template: PromptTemplate?) -> String {
        """
# NovaKit v3.1 Prompt
You are receiving a user request that should be handled with NovaKit v3.1 behavior.
User request: \(task)
Preferred template: \(template?.name ?? "Auto")
Template note: \(template?.instructions ?? "Infer the best NovaKit utility for the job.")
"""
    }

    private static func inferType(from text: String) -> PromptType {
        let lower = text.lowercased()
        if lower.contains("minecraft") || lower.contains("paper plugin") || lower.contains("plugin") { return .minecraftPluginPlan }
        if lower.contains("bug") || lower.contains("error") || lower.contains("crash") || lower.contains("fix") { return .bugFix }
        if lower.contains("review") || lower.contains("check") { return .codeReview }
        if lower.contains("research") || lower.contains("source") || lower.contains("investigate") { return .researchBrief }
        if lower.contains("ios") || lower.contains("app") || lower.contains("ui") || lower.contains("testflight") || lower.contains("upgrade") { return .appUpgrade }
        if lower.contains("plan") || lower.contains("roadmap") || lower.contains("project") { return .projectPlan }
        if lower.contains("add") || lower.contains("feature") || lower.contains("expand") { return .featureExpansion }
        return .general
    }

    private static func summarizeAttachments(_ attachments: [FileAttachment]) -> (shortExplanation: String, longExplanation: String, promptBlock: String) {
        guard !attachments.isEmpty else {
            return (
                "No files were attached, so the next prompt focuses on the pasted response and conversation history.",
                "No attachments were submitted with this step.",
                "No files were attached."
            )
        }

        let rows = attachments.map { file in
            let type = file.isLikelyText ? "text captured" : "binary/unsupported preview"
            return "- \(file.name) (\(file.sizeBytes) bytes, \(type))"
        }.joined(separator: "\n")

        let promptBlock = attachments.map { file in
            """
### Attached file: \(file.name)
Size: \(file.sizeBytes) bytes
Captured text:
\(truncate(file.textPreview, max: 12000))
"""
        }.joined(separator: "\n\n")

        return (
            "I found these files: \(attachments.map(\.name).joined(separator: ", ")).",
            rows,
            promptBlock
        )
    }

    private static func plainLanguageExplanation(_ response: String, attachments: [FileAttachment]) -> String {
        let responseLength = response.trimmingCharacters(in: .whitespacesAndNewlines).count
        var parts: [String] = []
        if responseLength == 0 {
            parts.append("There was no pasted AI response to analyze, so this step depends mainly on attachments and prior context.")
        } else {
            parts.append("The pasted AI response has been stored as part of this conversation. The next NovaKit prompt should ask Nova to verify the response, connect it to the files, and turn it into the next concrete action.")
        }

        if attachments.isEmpty {
            parts.append("No files were attached, so there is no file evidence for Nova to inspect yet.")
        } else {
            parts.append("The attached files should be treated as source evidence, not just notes. Nova should explain what each file is for and whether the pasted response matches the file contents.")
        }

        return parts.joined(separator: " ")
    }

    private static func normalized(_ text: String, fallback: String) -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }

    private static func truncate(_ text: String, max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max)) + "\n...[truncated]"
    }
}
