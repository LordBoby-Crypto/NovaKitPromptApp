import SwiftUI
import UniformTypeIdentifiers

struct ConversationView: View {
    @Binding var conversation: Conversation
    @State private var starterOutput = ""
    @State private var aiResponse = ""
    @State private var nextInstruction = ""
    @State private var followUpOutput = ""
    @State private var pendingAttachments: [FileAttachment] = []
    @State private var showingFileImporter = false
    @State private var fileError: String?
    @State private var copiedMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GroupBox("Conversation") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Title", text: $conversation.title)
                            .textFieldStyle(.roundedBorder)
                        Picker("Prompt Type", selection: $conversation.promptType) {
                            ForEach(PromptType.allCases) { type in Text(type.rawValue).tag(type) }
                        }
                        .pickerStyle(.menu)
                    }
                }

                GroupBox("Starter Prompt") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Type what you want Nova to help with.").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $conversation.userGoal)
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25)))
                        Button("Generate Starter Prompt") {
                            starterOutput = PromptEngine.makeStarter(goal: conversation.userGoal, type: conversation.promptType)
                            saveEntry(role: .starterPrompt, title: "Starter Prompt", text: starterOutput, attachments: [])
                        }
                        .buttonStyle(.borderedProminent)
                        OutputBox(title: "Generated starter prompt", text: $starterOutput)
                    }
                }

                GroupBox("AI / Nova Response + Files") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Paste what the AI replied with, then attach any files it created.").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $aiResponse)
                            .frame(minHeight: 150)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25)))
                        HStack {
                            Button("Attach Files") { showingFileImporter = true }
                                .buttonStyle(.bordered)
                            Button("Save AI Response") {
                                saveEntry(role: .aiResponse, title: "AI Response", text: aiResponse, attachments: pendingAttachments)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        if !pendingAttachments.isEmpty {
                            AttachmentList(attachments: $pendingAttachments)
                        }
                    }
                }

                GroupBox("Next Reply Prompt") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tell the app what you want to do next, or leave this blank and it will ask Nova for the best next step.").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $nextInstruction)
                            .frame(minHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25)))
                        Button("Generate Follow-Up Prompt") {
                            followUpOutput = PromptEngine.makeFollowUp(conversation: conversation, newInstruction: nextInstruction, latestAIResponse: aiResponse, attachments: pendingAttachments)
                            saveEntry(role: .followUpPrompt, title: "Follow-Up Prompt", text: followUpOutput, attachments: pendingAttachments)
                        }
                        .buttonStyle(.borderedProminent)
                        OutputBox(title: "Generated follow-up prompt", text: $followUpOutput)
                    }
                }

                if !conversation.entries.isEmpty {
                    GroupBox("Saved History") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(conversation.entries.reversed()) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.title).font(.headline)
                                    Text(entry.createdAt, style: .time).font(.caption).foregroundStyle(.secondary)
                                    Text(entry.text).font(.caption).lineLimit(5)
                                    if !entry.attachments.isEmpty { Text("\(entry.attachments.count) attachment(s)").font(.caption2).foregroundStyle(.secondary) }
                                }
                                .padding(8)
                                .background(.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Prompt Builder")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            do {
                let urls = try result.get()
                for url in urls { try importAttachment(url: url) }
            } catch {
                fileError = error.localizedDescription
            }
        }
        .alert("File problem", isPresented: Binding(get: { fileError != nil }, set: { if !$0 { fileError = nil } })) {
            Button("OK", role: .cancel) { fileError = nil }
        } message: { Text(fileError ?? "") }
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
}

struct OutputBox: View {
    var title: String
    @Binding var text: String

    var body: some View {
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Copy") { UIPasteboard.general.string = text }
                        .buttonStyle(.bordered)
                }
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct AttachmentList: View {
    @Binding var attachments: [FileAttachment]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(attachment.name).font(.subheadline).bold()
                        Text("\(attachment.sizeBytes) bytes").font(.caption).foregroundStyle(.secondary)
                        Text(attachment.textPreview).font(.caption2).lineLimit(3)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        attachments.removeAll { $0.id == attachment.id }
                    } label: { Image(systemName: "xmark.circle") }
                }
                .padding(8)
                .background(.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Button("Clear Attachments") { attachments.removeAll() }
                .buttonStyle(.bordered)
        }
    }
}
