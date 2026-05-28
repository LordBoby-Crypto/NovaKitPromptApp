import SwiftUI

@main
struct NovaKitPromptApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ConversationListView()
                .environmentObject(store)
        }
    }
}
