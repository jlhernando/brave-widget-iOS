import Foundation

struct BraveSearchAPI {
    static var apiKey: String {
        KeychainHelper.loadAPIKey()
    }

    static let baseURL = "https://api.search.brave.com/res/v1"

    // MARK: - Web Search

    static func search(query: String, count: Int = 10) async throws -> SearchResponse {
        guard !apiKey.isEmpty else { throw SearchError.noAPIKey }
        var components = URLComponents(string: "\(baseURL)/web/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "count", value: "\(count)")
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SearchError.httpError(code)
        }
        return try JSONDecoder().decode(SearchResponse.self, from: data)
    }

    // MARK: - Suggestions

    static func suggest(query: String) async throws -> [String] {
        guard !apiKey.isEmpty else { throw SearchError.noAPIKey }
        var components = URLComponents(string: "\(baseURL)/suggest/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        let suggestResponse = try JSONDecoder().decode(SuggestResponse.self, from: data)
        return suggestResponse.results.map(\.query)
    }
}

// MARK: - Models

struct SearchResponse: Codable {
    let query: QueryInfo?
    let web: WebResults?
}

struct QueryInfo: Codable {
    let original: String?
}

struct WebResults: Codable {
    let results: [WebResult]?
}

struct WebResult: Codable, Identifiable {
    let title: String
    let url: String
    let description: String?

    var id: String { url }

    var displayURL: String {
        URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? url
    }

    var faviconURL: URL? {
        guard let host = URL(string: url)?.host else { return nil }
        return URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico")
    }
}

struct SuggestResponse: Codable {
    let results: [SuggestResult]
}

struct SuggestResult: Codable {
    let query: String
}

enum SearchError: LocalizedError {
    case noAPIKey
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Add your Brave Search API key in Settings."
        case .httpError(let code):
            return "Search failed (HTTP \(code))"
        }
    }
}
