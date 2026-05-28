import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ConversationView: View {
    @EnvironmentObject var store: AppStore
    @Binding var conversation: Conversation
    @State private var starterGoal = ""
    @State private var composerText = ""
    @State private var optionalInstruction = ""
    @State private var showingOptionalInstruction = false
    @State private var pendingAttachments: [FileAttachment] = []
    @State private var showingFileImporter = false
    @State private var showingStarterSheet = false
    @State private var showingConversationSettings = false
    @State private var fileError: String?
    @State private var toastMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.black, Color(.systemGray6).opacity(0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().opacity(0.25)
                timeline
                composer
            }

            if let toastMessage {
                Text(toastMessage)
                    .font(.callout.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 122)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Nova Thread")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingStarterSheet = true } label: { Label("Starter", systemImage: "sparkles") }
                    .accessibilityLabel("Create starter prompt")
                Button { showingConversationSettings = true } label: { Label("Settings", systemImage: "slider.horizontal.3") }
                    .accessibilityLabel("Conversation settings")
            }
        }
        .sheet(isPresented: $showingStarterSheet) { starterSheet }
        .sheet(isPresented: $showingConversationSettings) { ConversationSettingsView(conversation: $conversation) }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            do {
                let urls = try result.get()
                for url in urls { try importAttachment(url: url) }
                showToast("Attached \(urls.count) file\(urls.count == 1 ? "" : "s")")
            } catch {
                fileError = error.localizedDescription
            }
        }
        .alert("File problem", isPresented: Binding(get: { fileError != nil }, set: { if !$0 { fileError = nil } })) {
            Button("OK", role: .cancel) { fileError = nil }
        } message: { Text(fileError ?? "") }
        .onAppear { starterGoal = conversation.userGoal }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Conversation title", text: $conversation.title)
                        .font(.title2.bold())
                        .accessibilityLabel("Conversation title")
                    Text("\(conversation.folderName) • \(conversation.entries.count) saved messages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Picker("Prompt Type", selection: $conversation.promptType) {
                        ForEach(PromptType.allCases) { type in Text(type.rawValue).tag(type) }
                    }
                } label: {
                    Label(conversation.promptType.rawValue, systemImage: "wand.and.stars")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Prompt type")
            }

            if !conversation.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(conversation.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.18), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.black.opacity(0.88))
    }

    private var timeline: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if conversation.entries.isEmpty {
                        EmptyThreadView { showingStarterSheet = true }
                            .padding(.top, 40)
                    } else {
                        ForEach(conversation.entries) { entry in
                            ChatEntryView(entry: entry, onCopy: copyToClipboard(_:), onToast: showToast(_:))
                                .id(entry.id)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 18)
            }
            .onChange(of: conversation.entries.count) { _ in
                if let last = conversation.entries.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if !pendingAttachments.isEmpty {
                AttachmentTray(attachments: $pendingAttachments)
            }

            if showingOptionalInstruction {
                TextField("Optional direction for the next prompt", text: $optionalInstruction, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Optional next direction")
            }

            HStack(alignment: .bottom, spacing: 10) {
                Button { showingFileImporter = true } label: {
                    Image(systemName: "paperclip")
                        .font(.title3)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Attach files")

                TextField("Paste the AI response here…", text: $composerText, axis: .vertical)
                    .lineLimit(2...7)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityLabel("AI response")

                Button { submitAIResponse() } label: {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                        .frame(width: 42, height: 42)
                        .foregroundStyle(.white)
                        .background(canSubmit ? Color.accentColor : Color.gray, in: Circle())
                }
                .disabled(!canSubmit)
                .accessibilityLabel("Submit AI response and generate NovaKit guidance")
            }

            Button {
                withAnimation { showingOptionalInstruction.toggle() }
                if !showingOptionalInstruction { optionalInstruction = "" }
            } label: {
                Label(showingOptionalInstruction ? "Hide optional instruction" : "Add optional next-step instruction", systemImage: "plus.bubble")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Add optional next step instruction")
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }

    private var starterSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Start a cleaner NovaKit thread")
                    .font(.title2.bold())
                Text("This creates the first copy-ready prompt. After that, the main screen behaves like a chat timeline: paste each AI response, attach files, and NovaKit generates the next guidance message.")
                    .foregroundStyle(.secondary)

                TextEditor(text: $starterGoal)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Starter goal")

                Picker("Prompt Type", selection: $conversation.promptType) {
                    ForEach(PromptType.allCases) { type in Text(type.rawValue).tag(type) }
                }

                Button {
                    conversation.userGoal = starterGoal
                    let prompt = PromptEngine.makeStarter(goal: starterGoal, type: conversation.promptType, preferences: store.preferences)
                    saveEntry(role: .starterPrompt, title: "Starter Prompt", text: prompt, attachments: [], suggestedPrompt: prompt, summary: "Copy this into your AI to start the thread.")
                    showingStarterSheet = false
                    showToast("Starter prompt created")
                } label: {
                    Label("Create Starter Prompt", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .padding()
            .navigationTitle("Starter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showingStarterSheet = false } } }
        }
    }

    private var canSubmit: Bool {
        !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pendingAttachments.isEmpty
    }

    private func submitAIResponse() {
        let clean = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = pendingAttachments
        saveEntry(role: .aiResponse, title: "AI Response", text: clean.isEmpty ? "[No pasted text; files only.]" : clean, attachments: attachments)

        var prompt = PromptEngine.makeFollowUp(conversation: conversation, newInstruction: optionalInstruction, latestAIResponse: clean, attachments: attachments, preferences: store.preferences)
        let guidance = PromptEngine.makeAIResponseGuidance(conversation: conversation, latestAIResponse: clean, attachments: attachments, preferences: store.preferences)
        if !optionalInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { prompt = PromptEngine.makeFollowUp(conversation: conversation, newInstruction: optionalInstruction, latestAIResponse: clean, attachments: attachments, preferences: store.preferences) }

        saveEntry(role: .novaGuidance, title: "NovaKit Guidance", text: guidance.fullText, attachments: attachments, suggestedPrompt: prompt, summary: guidance.summary)
        composerText = ""
        optionalInstruction = ""
        showingOptionalInstruction = false
        pendingAttachments = []
        showToast("Guidance generated")
    }

    private func saveEntry(role: ConversationEntry.Role, title: String, text: String, attachments: [FileAttachment], suggestedPrompt: String? = nil, summary: String? = nil) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        conversation.entries.append(ConversationEntry(role: role, title: title, text: clean, attachments: attachments, suggestedPrompt: suggestedPrompt, summary: summary))
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

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showToast("Copied")
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation { if toastMessage == message { toastMessage = nil } }
        }
    }
}

struct EmptyThreadView: View {
    var startAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 52))
                .foregroundStyle(.blue)
            Text("No prompt history yet")
                .font(.title2.bold())
            Text("Create a starter prompt, then paste each AI response at the bottom. NovaKit will keep the thread history and suggest the next prompt for you.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Create Starter Prompt", action: startAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }
}

struct ChatEntryView: View {
    var entry: ConversationEntry
    var onCopy: (String) -> Void
    var onToast: (String) -> Void

    var body: some View {
        HStack(alignment: .top) {
            if isUserEntry { Spacer(minLength: 36) }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(entry.title, systemImage: iconName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let summary = entry.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.callout)
                } else {
                    Text(entry.text)
                        .font(.callout)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                }

                if !entry.attachments.isEmpty {
                    AttachmentPreviewGrid(attachments: entry.attachments)
                }

                if let suggestedPrompt = entry.suggestedPrompt, !suggestedPrompt.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Copy-ready NovaKit prompt")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(suggestedPrompt)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(8)
                            .textSelection(.enabled)
                            .padding(10)
                            .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                HStack {
                    Button { onCopy(entry.suggestedPrompt ?? entry.text) } label: { Label("Copy", systemImage: "doc.on.doc") }
                    ShareLink(item: entry.suggestedPrompt ?? entry.text) { Label("Share", systemImage: "square.and.arrow.up") }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(14)
            .frame(maxWidth: 620, alignment: .leading)
            .background(bubbleColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityElement(children: .contain)

            if !isUserEntry { Spacer(minLength: 36) }
        }
    }

    private var isUserEntry: Bool { entry.role == .aiResponse }
    private var bubbleColor: Color { isUserEntry ? Color.accentColor.opacity(0.28) : Color(.secondarySystemBackground) }
    private var iconName: String {
        switch entry.role {
        case .starterPrompt: return "sparkles"
        case .aiResponse: return "person.crop.circle"
        case .followUpPrompt: return "arrowshape.turn.up.right"
        case .novaGuidance: return "wand.and.stars"
        }
    }
}

struct AttachmentTray: View {
    @Binding var attachments: [FileAttachment]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    HStack(spacing: 6) {
                        Image(systemName: attachment.isLikelyText ? "doc.text" : "doc")
                        Text(attachment.name).lineLimit(1)
                        Button { attachments.removeAll { $0.id == attachment.id } } label: { Image(systemName: "xmark.circle.fill") }
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
    }
}

struct AttachmentPreviewGrid: View {
    var attachments: [FileAttachment]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                VStack(alignment: .leading, spacing: 4) {
                    Label(attachment.name, systemImage: attachment.isLikelyText ? "doc.text" : "doc")
                        .font(.caption.bold())
                    Text("\(attachment.sizeBytes) bytes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(attachment.textPreview)
                        .font(.caption2.monospaced())
                        .lineLimit(3)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct ConversationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var conversation: Conversation
    @State private var tagsText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Organization") {
                    TextField("Folder", text: $conversation.folderName)
                    TextField("Tags separated by commas", text: $tagsText)
                        .onSubmit { applyTags() }
                    Toggle("Archived", isOn: $conversation.isArchived)
                }

                Section("Prompt Mode") {
                    Picker("Prompt Type", selection: $conversation.promptType) {
                        ForEach(PromptType.allCases) { type in Text(type.rawValue).tag(type) }
                    }
                }
            }
            .navigationTitle("Thread Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { applyTags(); dismiss() } } }
            .onAppear { tagsText = conversation.tags.joined(separator: ", ") }
        }
    }

    private func applyTags() {
        conversation.tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.sorted()
        conversation.updatedAt = Date()
    }
}
