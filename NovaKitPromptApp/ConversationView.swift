import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct ConversationView: View {
    @Binding var conversation: Conversation
    @State private var aiResponse = ""
    @State private var nextInstruction = ""
    @State private var pendingAttachments: [FileAttachment] = []
    @State private var showingFileImporter = false
    @State private var showingStarter = false
    @State private var showingSettings = false
    @State private var fileError: String?
    @State private var copiedMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.purple.opacity(0.15), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            conversationHeader

                            if conversation.entries.isEmpty {
                                welcomeCard
                            } else {
                                ForEach(conversation.entries) { entry in
                                    ChatTurnView(entry: entry) { text in
                                        copy(text)
                                    }
                                    .id(entry.id)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: conversation.entries.count) { _ in
                        if let last = conversation.entries.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }

                ComposerView(
                    aiResponse: $aiResponse,
                    nextInstruction: $nextInstruction,
                    attachments: $pendingAttachments,
                    attachAction: { showingFileImporter = true; Haptics.tap() },
                    submitAction: submitAITurn
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .navigationTitle("NovaKit Thread")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingStarter = true; Haptics.tap() } label: { Image(systemName: "sparkles") }
                    .accessibilityLabel("Create starter prompt")
                Button { showingSettings = true; Haptics.tap() } label: { Image(systemName: "slider.horizontal.3") }
                    .accessibilityLabel("Conversation settings")
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            do {
                let urls = try result.get()
                for url in urls { try importAttachment(url: url) }
                Haptics.success()
            } catch {
                fileError = error.localizedDescription
                Haptics.error()
            }
        }
        .alert("File problem", isPresented: Binding(get: { fileError != nil }, set: { if !$0 { fileError = nil } })) {
            Button("OK", role: .cancel) { fileError = nil }
        } message: { Text(fileError ?? "") }
        .overlay(alignment: .top) {
            if let copiedMessage {
                Text(copiedMessage)
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingStarter) {
            StarterPromptSheet(conversation: $conversation) { text in copy(text) }
        }
        .sheet(isPresented: $showingSettings) {
            ConversationSettingsSheet(conversation: $conversation)
        }
    }

    private var conversationHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(conversation.title)
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(.white)
            Text("\(conversation.folderName) • \(conversation.promptType.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !conversation.tags.isEmpty {
                FlowTags(tags: conversation.tags)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("New NovaKit thread", systemImage: "sparkles")
                .font(.headline)
            Text("Use the sparkle button for the first starter prompt. After that, paste each AI answer in the bottom composer, attach any files, and submit it as the next chat turn.")
                .foregroundStyle(.secondary)
            Button("Create starter prompt") { showingStarter = true; Haptics.tap() }
                .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.08)))
    }

    private func submitAITurn() {
        let clean = aiResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty || !pendingAttachments.isEmpty else { return }

        let responseText = clean.isEmpty ? "[No pasted text. Files were attached for this turn.]" : clean
        saveEntry(role: .aiResponse, title: "AI Response", text: responseText, attachments: pendingAttachments)

        let guidance = PromptEngine.makeGuidance(
            conversation: conversation,
            latestAIResponse: responseText,
            attachments: pendingAttachments,
            optionalInstruction: nextInstruction
        )
        saveEntry(role: .guidance, title: "NovaKit Guidance + Response Prompt", text: guidance.explanation + "\n\n--- NEXT PROMPT ---\n" + guidance.responsePrompt, attachments: pendingAttachments)

        aiResponse = ""
        nextInstruction = ""
        pendingAttachments.removeAll()
        Haptics.success()
    }

    private func saveEntry(role: ConversationEntry.Role, title: String, text: String, attachments: [FileAttachment]) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        conversation.entries.append(ConversationEntry(role: role, title: title, text: clean, attachments: attachments))
        conversation.updatedAt = Date()
    }

    private func importAttachment(url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16)
            ?? "[Binary or unsupported text encoding. Filename and size captured only.]"
        let capped = String(text.prefix(120_000))
        pendingAttachments.append(FileAttachment(name: url.lastPathComponent, sizeBytes: data.count, textPreview: capped))
    }

    private func copy(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
        Haptics.success()
        withAnimation { copiedMessage = "Copied" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation { copiedMessage = nil }
        }
    }
}

struct ComposerView: View {
    @Binding var aiResponse: String
    @Binding var nextInstruction: String
    @Binding var attachments: [FileAttachment]
    var attachAction: () -> Void
    var submitAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paste the AI reply")
                .font(.headline)
            TextEditor(text: $aiResponse)
                .frame(minHeight: 92, maxHeight: 140)
                .padding(6)
                .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.10)))
                .accessibilityLabel("AI response text")

            DisclosureGroup("Optional instruction") {
                TextEditor(text: $nextInstruction)
                    .frame(minHeight: 54, maxHeight: 90)
                    .padding(6)
                    .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Optional next instruction")
            }
            .font(.callout)

            if !attachments.isEmpty { AttachmentStrip(attachments: $attachments) }

            HStack {
                Button { attachAction() } label: { Label("Files", systemImage: "paperclip") }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Attach files")
                Spacer()
                Button { submitAction() } label: { Label("Submit Turn", systemImage: "arrow.up.circle.fill") }
                    .buttonStyle(.borderedProminent)
                    .disabled(aiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty)
                    .accessibilityLabel("Submit AI response turn")
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
    }
}

struct ChatTurnView: View {
    let entry: ConversationEntry
    var copyAction: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(entry.title, systemImage: iconName)
                    .font(.headline)
                Spacer()
                Text(entry.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(entry.text)
                .font(.system(.callout, design: entry.role == .guidance || entry.role == .starterPrompt ? .monospaced : .default))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(entry.role == .aiResponse ? 10 : nil)

            if !entry.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.attachments) { attachment in
                        Label("\(attachment.name) • \(attachment.sizeBytes) bytes", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Button { copyAction(entry.text) } label: { Label("Copy", systemImage: "doc.on.doc") }
                    .buttonStyle(.bordered)
                ShareLink(item: entry.text) { Label("Share", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered)
            }
            .font(.caption)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch entry.role {
        case .starterPrompt: return "sparkles"
        case .aiResponse: return "bubble.left.fill"
        case .followUpPrompt: return "arrowshape.turn.up.right.fill"
        case .guidance: return "wand.and.stars"
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch entry.role {
        case .aiResponse: return AnyShapeStyle(.ultraThinMaterial)
        case .guidance: return AnyShapeStyle(Color.blue.opacity(0.18))
        case .starterPrompt, .followUpPrompt: return AnyShapeStyle(Color.purple.opacity(0.16))
        }
    }
}

struct StarterPromptSheet: View {
    @Binding var conversation: Conversation
    var copyAction: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draftGoal = ""
    @State private var generated = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("What should Nova help with first?") {
                    TextEditor(text: $draftGoal)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Starter goal")
                    Picker("Prompt type", selection: $conversation.promptType) {
                        ForEach(PromptType.allCases) { type in Text(type.rawValue).tag(type) }
                    }
                }

                Section {
                    Button("Generate Starter Prompt") {
                        conversation.userGoal = draftGoal
                        generated = PromptEngine.makeStarter(goal: draftGoal, type: conversation.promptType, config: conversation.templateConfig)
                        conversation.entries.append(ConversationEntry(role: .starterPrompt, title: "Starter Prompt", text: generated))
                        conversation.updatedAt = Date()
                        Haptics.success()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !generated.isEmpty {
                    Section("Generated") {
                        Text(generated)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        Button("Copy Prompt") { copyAction(generated) }
                        ShareLink(item: generated) { Label("Share Prompt", systemImage: "square.and.arrow.up") }
                    }
                }
            }
            .navigationTitle("Starter Prompt")
            .toolbar { Button("Done") { dismiss() } }
            .onAppear { draftGoal = conversation.userGoal }
        }
    }
}

struct ConversationSettingsSheet: View {
    @Binding var conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var tagText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Conversation") {
                    TextField("Title", text: $conversation.title)
                    TextField("Folder", text: $conversation.folderName)
                    Picker("Prompt Type", selection: $conversation.promptType) {
                        ForEach(PromptType.allCases) { type in Text(type.rawValue).tag(type) }
                    }
                    Toggle("Archived", isOn: $conversation.isArchived)
                }

                Section("Tags") {
                    TextField("Comma separated tags", text: $tagText)
                        .textInputAutocapitalization(.never)
                    FlowTags(tags: conversation.tags)
                }

                Section("Prompt Template") {
                    Toggle("NovaKit header", isOn: $conversation.templateConfig.includeNovaKitHeader)
                    Toggle("Response Reviewer", isOn: $conversation.templateConfig.includeResponseReviewer)
                    Toggle("Constraints Analysis", isOn: $conversation.templateConfig.includeConstraintsAnalysis)
                    Toggle("Minecraft defaults", isOn: $conversation.templateConfig.preferMinecraftDefaults)
                    Stepper("History turns: \(conversation.templateConfig.maxHistoryEntries)", value: $conversation.templateConfig.maxHistoryEntries, in: 1...20)
                }
            }
            .navigationTitle("Thread Settings")
            .toolbar { Button("Done") { applyTags(); dismiss() } }
            .onAppear { tagText = conversation.tags.joined(separator: ", ") }
        }
    }

    private func applyTags() {
        conversation.tags = tagText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        conversation.updatedAt = Date()
    }
}

struct AttachmentStrip: View {
    @Binding var attachments: [FileAttachment]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                        VStack(alignment: .leading) {
                            Text(attachment.name).lineLimit(1)
                            Text("\(attachment.sizeBytes) bytes").font(.caption2).foregroundStyle(.secondary)
                        }
                        Button { attachments.removeAll { $0.id == attachment.id } } label: { Image(systemName: "xmark.circle.fill") }
                            .accessibilityLabel("Remove \(attachment.name)")
                    }
                    .font(.caption)
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }
}

struct FlowTags: View {
    let tags: [String]

    var body: some View {
        HStack {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.18), in: Capsule())
            }
        }
    }
}
