import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ConversationListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingImport = false
    @State private var showingArchived = false
    @State private var importError: String?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.black, Color(.systemBlue).opacity(0.12)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        folderSummary
                        conversationsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("NovaKit")
            .searchable(text: $searchText, prompt: "Search conversations, tags, or folders")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: store.exportJSON(), preview: SharePreview("NovaKit Backup")) {
                        Label("Export backup", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export versioned backup")
                    Button { showingImport = true } label: { Label("Import backup", systemImage: "square.and.arrow.down") }
                        .accessibilityLabel("Import backup")
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        store.createConversation()
                    } label: { Label("New conversation", systemImage: "plus") }
                    .accessibilityLabel("New conversation")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let binding = bindingForConversation(id) {
                    ConversationView(conversation: binding)
                } else {
                    MissingConversationView()
                }
            }
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json, .text], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                    let text = try String(contentsOf: url, encoding: .utf8)
                    try store.importJSON(text)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } catch {
                    importError = error.localizedDescription
                }
            }
            .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("OK", role: .cancel) { importError = nil }
            } message: { Text(importError ?? "") }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Prompt workspace")
                .font(.caption.bold())
                .foregroundStyle(.blue)
                .textCase(.uppercase)
            Text("Build, continue, and update NovaKit threads without the crowded one-page form.")
                .font(.title2.bold())
            Text("Open a thread, create a starter prompt, then paste each AI response at the bottom like a chat app. Backups are versioned for future upgrades.")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var folderSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                SummaryPill(title: "Active", value: "\(store.activeConversations.count)", systemImage: "bubble.left.and.bubble.right")
                SummaryPill(title: "Archived", value: "\(store.archivedConversations.count)", systemImage: "archivebox")
                SummaryPill(title: "Folders", value: "\(store.folders.count)", systemImage: "folder")
                Button { showingArchived.toggle() } label: {
                    Label(showingArchived ? "Hide Archive" : "Show Archive", systemImage: showingArchived ? "eye.slash" : "eye")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }

    private var conversationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(showingArchived ? "Archived Conversations" : "Saved Conversations")
                .font(.headline)
                .foregroundStyle(.secondary)

            let conversations = filteredConversations
            if conversations.isEmpty {
                NoConversationsView()
                    .padding(.vertical, 40)
            } else {
                ForEach(conversations) { conversation in
                    NavigationLink(value: conversation.id) {
                        ConversationCard(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { store.duplicate(conversation) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                        if conversation.isArchived {
                            Button { store.restore(conversation) } label: { Label("Restore", systemImage: "arrow.up.bin") }
                        } else {
                            Button { store.archive(conversation) } label: { Label("Archive", systemImage: "archivebox") }
                        }
                        Button(role: .destructive) { store.delete(conversation) } label: { Label("Delete", systemImage: "trash") }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.delete(conversation) } label: { Label("Delete", systemImage: "trash") }
                        Button { store.duplicate(conversation) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                    }
                    .swipeActions(edge: .leading) {
                        if conversation.isArchived {
                            Button { store.restore(conversation) } label: { Label("Restore", systemImage: "arrow.up.bin") }
                        } else {
                            Button { store.archive(conversation) } label: { Label("Archive", systemImage: "archivebox") }
                        }
                    }
                }
            }
        }
    }

    private var filteredConversations: [Conversation] {
        let source = showingArchived ? store.archivedConversations : store.activeConversations
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return source }
        return source.filter { conversation in
            conversation.title.lowercased().contains(query)
            || conversation.folderName.lowercased().contains(query)
            || conversation.tags.joined(separator: " ").lowercased().contains(query)
            || conversation.entries.contains { $0.text.lowercased().contains(query) }
        }
    }

    private func bindingForConversation(_ id: UUID) -> Binding<Conversation>? {
        guard let index = store.conversations.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(get: { store.conversations[index] }, set: { store.conversations[index] = $0 })
    }
}

struct ConversationCard: View {
    var conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(conversation.folderName) • \(conversation.updatedAt, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 10) {
                Label("\(conversation.entries.count) messages", systemImage: "text.bubble")
                Label(conversation.promptType.rawValue, systemImage: "wand.and.stars")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !conversation.tags.isEmpty {
                HStack {
                    ForEach(conversation.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.16), in: Capsule())
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SummaryPill: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline)
                Text(title).font(.caption2).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
    }
}

struct MissingConversationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Conversation not found")
                .font(.headline)
        }
    }
}

struct NoConversationsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No conversations")
                .font(.headline)
            Text("Tap + to create a new NovaKit thread.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
