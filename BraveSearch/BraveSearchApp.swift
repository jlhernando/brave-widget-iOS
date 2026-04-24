import SwiftUI

@main
struct BraveSearchApp: App {
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var searchMode: SearchMode = .web
    @State private var triggerVoice = false

    var body: some Scene {
        WindowGroup {
            SearchView(
                searchText: $searchText,
                showSettings: $showSettings,
                searchMode: $searchMode,
                triggerVoice: $triggerVoice
            )
            .onOpenURL { url in
                if let action = SearchAction.from(url: url) {
                    handleAction(action)
                }
            }
        }
    }

    private func handleAction(_ action: SearchAction) {
        switch action {
        case .search, .ai:
            searchText = ""
            searchMode = .web
        case .voice:
            searchText = ""
            searchMode = .web
            triggerVoice = true
        case .image:
            searchMode = .images
        case .newTab:
            searchText = ""
            searchMode = .web
        }
    }
}

enum SearchMode {
    case web
    case images
}
