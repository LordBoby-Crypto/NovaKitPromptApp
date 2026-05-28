import Foundation

enum PromptEngine {
    static func makeStarter(goal: String, type: PromptType) -> String {
        let cleanGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        let selected = type == .auto ? inferType(from: cleanGoal) : type

        switch selected {
        case .minecraftPluginPlan:
            return baseHeader(task: cleanGoal) + """

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
            return baseHeader(task: cleanGoal) + """

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
            return baseHeader(task: cleanGoal) + """

Run NovaKit v3.1 as Nova.

Use Spechammer and Constraints Analysis to expand this into a clean feature design:
\(cleanGoal)

Return a structured implementation brief with feature scope, user flow, config needs, commands, permissions, data model, edge cases, and build phases.
"""
        case .bugFix:
            return baseHeader(task: cleanGoal) + """

Run NovaKit v3.1 as Nova.

Analyze this bug or issue:
\(cleanGoal)

Return likely causes, what evidence is needed, how to reproduce, exact fixes to try, and what files/logs should be inspected next.
"""
        case .general, .auto:
            return baseHeader(task: cleanGoal) + """

Run NovaKit v3.1 as Nova.

Turn this request into the strongest useful output:
\(cleanGoal)

Use the relevant NovaKit v3.1 utility or mode, explain which one you used briefly, then produce the answer in a clean, practical format.
"""
        }
    }

    static func makeFollowUp(conversation: Conversation, newInstruction: String, latestAIResponse: String, attachments: [FileAttachment]) -> String {
        let previousPrompts = conversation.entries.suffix(8).map { entry in
            "## \(entry.role.rawValue) - \(entry.title)\n\(truncate(entry.text, max: 4000))"
        }.joined(separator: "\n\n")

        let attachmentBlock = attachments.isEmpty ? "No files were attached." : attachments.map { file in
            """
            ### Attached file: \(file.name)
            Size: \(file.sizeBytes) bytes
            Captured text:
            \(truncate(file.textPreview, max: 12000))
            """
        }.joined(separator: "\n\n")

        return """
        Run NovaKit v3.1 as Nova.

        Continue the same work thread. Use the prior prompt history, the AI response I pasted, and the attached file contents together. Do not ignore attached files.

        # My next instruction
        \(newInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Continue from the AI response and attached files. Identify the best next step and produce the next useful output." : newInstruction)

        # Recent saved prompt/history context
        \(previousPrompts.isEmpty ? "No previous prompt history was saved." : previousPrompts)

        # AI response I received
        \(latestAIResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No pasted AI response was provided." : latestAIResponse)

        # Files produced by the AI / attached for this step
        \(attachmentBlock)

        # Required behavior
        - Base the response on both the pasted AI response and the attached files.
        - If code/config files are attached, inspect them as actual source context.
        - Point out contradictions between the response and the files.
        - Give the next prompt/output in a practical format.
        - If continuing a Minecraft plugin task, prefer Java 21, Paper API, Maven, Lombok, and Oraxen-aware design when relevant.
        - If files are missing, say exactly what is missing.
        """
    }

    private static func baseHeader(task: String) -> String {
        """
        # NovaKit v3.1 Prompt
        You are receiving a user request that should be handled with NovaKit v3.1 behavior.
        User request: \(task)
        """
    }

    private static func inferType(from text: String) -> PromptType {
        let lower = text.lowercased()
        if lower.contains("minecraft") || lower.contains("paper plugin") || lower.contains("plugin") { return .minecraftPluginPlan }
        if lower.contains("bug") || lower.contains("error") || lower.contains("crash") || lower.contains("fix") { return .bugFix }
        if lower.contains("review") || lower.contains("check") { return .codeReview }
        if lower.contains("add") || lower.contains("feature") || lower.contains("expand") { return .featureExpansion }
        return .general
    }

    private static func truncate(_ text: String, max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max)) + "\n...[truncated]"
    }
}
