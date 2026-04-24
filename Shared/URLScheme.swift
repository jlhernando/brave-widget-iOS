import Foundation

enum SearchAction: String {
    case search = "search"
    case ai = "ai"
    case voice = "voice"
    case image = "image"
    case newTab = "new"

    var urlString: String {
        "bravesearch://\(rawValue)"
    }

    var url: URL {
        URL(string: urlString)!
    }

    static func from(url: URL) -> SearchAction? {
        guard url.scheme == "bravesearch" else { return nil }
        return SearchAction(rawValue: url.host ?? "")
    }
}
