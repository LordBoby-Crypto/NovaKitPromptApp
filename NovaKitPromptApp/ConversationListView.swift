import SwiftUI
import UniformTypeIdentifiers

struct ConversationListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingImport = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.conversations) { conversation in
                        NavigationLink(value: conversation.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title).font(.headline)
                                Text(conversation.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                                Text("\(conversation.entries.count) saved entries").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { store.delete(conversation) } label: { Label("Delete", systemImage: "trash") }
                            Button { store.duplicate(conversation) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                        }
                    }
                } header: {
                    Text("Saved Conversations")
                }
            }
            .navigationTitle("NovaKit")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: store.exportJSON(), preview: SharePreview("NovaKit Backup")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button { showingImport = true } label: { Image(systemName: "square.and.arrow.down") }
                    Button { store.createConversation() } label: { Image(systemName: "plus") }
                }
            }
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
                    let text = try String(contentsOf: url, encoding: .utf8)
                    try store.importJSON(text)
                } catch {
                    importError = error.localizedDescription
                }
            }
            .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("OK", role: .cancel) { importError = nil }
            } message: { Text(importError ?? "") }
        }
    }

    private func bindingForConversation(_ id: UUID) -> Binding<Conversation>? {
        guard let index = store.conversations.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(get: { store.conversations[index] }, set: { store.conversations[index] = $0 })
    }
}
