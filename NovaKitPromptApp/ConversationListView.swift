import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct ConversationListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingImport = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.black, Color.blue.opacity(0.18), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        Picker("Conversation filter", selection: $store.showingArchived) {
                            Text("Active").tag(false)
                            Text("Archived").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Conversation filter")

                        if store.visibleConversations.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(store.visibleConversations) { conversation in
                                    NavigationLink(value: conversation.id) {
                                        ConversationCard(conversation: conversation)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button { store.duplicate(conversation) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                                        if conversation.isArchived {
                                            Button { store.unarchive(conversation) } label: { Label("Unarchive", systemImage: "tray.and.arrow.up") }
                                        } else {
                                            Button { store.archive(conversation) } label: { Label("Archive", systemImage: "archivebox") }
                                        }
                                        Button(role: .destructive) { store.delete(conversation) } label: { Label("Delete", systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .navigationDestination(for: UUID.self) { id in
                if let binding = bindingForConversation(id) {
                    ConversationView(conversation: binding)
                } else {
                    Text("Conversation not found")
                }
            }
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json, .text], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                    let text = try String(contentsOf: url, encoding: .utf8)
                    try store.importJSON(text)
                    Haptics.success()
                } catch {
                    importError = error.localizedDescription
                    Haptics.error()
                }
            }
            .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("OK", role: .cancel) { importError = nil }
            } message: { Text(importError ?? "") }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NovaKit")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Prompt conversations that feel more like an AI chat history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: store.showingArchived ? "archivebox" : "sparkles")
                .font(.system(size: 42))
                .foregroundStyle(.blue)
            Text(store.showingArchived ? "No archived conversations" : "Start a cleaner NovaKit thread")
                .font(.title3.bold())
            Text(store.showingArchived ? "Archived conversations will appear here." : "Create a thread, paste AI replies as turns, attach files, and copy the generated NovaKit response prompt.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !store.showingArchived {
                Button("New Conversation") { store.createConversation(); Haptics.tap() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            ShareLink(item: store.exportJSON(), preview: SharePreview("NovaKit Versioned Backup")) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Export versioned backup")

            Button { showingImport = true; Haptics.tap() } label: { Image(systemName: "square.and.arrow.down") }
                .accessibilityLabel("Import backup")

            Button { store.createConversation(); Haptics.tap() } label: { Image(systemName: "plus") }
                .accessibilityLabel("Create conversation")
        }
    }

    private func bindingForConversation(_ id: UUID) -> Binding<Conversation>? {
        guard let index = store.conversations.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(get: { store.conversations[index] }, set: { store.conversations[index] = $0 })
    }
}

struct ConversationCard: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(conversation.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                Text(conversation.updatedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label("\(conversation.entries.count) turns", systemImage: "bubble.left.and.bubble.right")
                    Label(conversation.folderName, systemImage: "folder")
                    if !conversation.tags.isEmpty { Label(conversation.tags.prefix(2).joined(separator: ", "), systemImage: "tag") }
                    if conversation.isArchived { Label("Archived", systemImage: "archivebox") }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.08)))
        .accessibilityElement(children: .combine)
    }
}

enum Haptics {
    static func tap() {
#if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    static func success() {
#if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }

    static func error() {
#if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif
    }
}
