import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct SearchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SearchWidgetEntry {
        SearchWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SearchWidgetEntry) -> Void) {
        completion(SearchWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SearchWidgetEntry>) -> Void) {
        let entry = SearchWidgetEntry(date: .now)
        // Static widget — refresh once per day
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry

struct SearchWidgetEntry: TimelineEntry {
    let date: Date
}

// MARK: - Medium Widget View

struct SearchWidgetMediumView: View {
    var body: some View {
        VStack(spacing: 10) {
            // Search bar
            Link(destination: SearchAction.search.url) {
                HStack(spacing: 10) {
                    AppIcon(size: 28)
                    Text("Search privately")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }

            // Action buttons row
            HStack(spacing: 0) {
                Spacer()
                ActionButton(icon: "mic.fill", action: .voice)
                Spacer()
                ActionButton(icon: "photo.fill", action: .image)
                Spacer()
                ActionButton(icon: "plus", action: .newTab)
                Spacer()
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.15, green: 0.15, blue: 0.17)
        }
    }
}

// MARK: - Small Widget View

struct SearchWidgetSmallView: View {
    var body: some View {
        VStack(spacing: 8) {
            AppIcon(size: 40)
            Text("Search")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(SearchAction.search.url)
        .containerBackground(for: .widget) {
            Color(red: 0.15, green: 0.15, blue: 0.17)
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let action: SearchAction

    var body: some View {
        Link(destination: action.url) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

// MARK: - App Icon (Shield + Magnifying Glass)

struct AppIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.85, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color(red: 1.0, green: 0.4, blue: 0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "magnifyingglass")
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: -size * 0.03)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Lock Screen Widget

struct SearchLockScreenView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "shield.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.orange)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .widgetURL(SearchAction.search.url)
    }
}

// MARK: - Widget Configuration

struct BraveSearchWidget: Widget {
    let kind = "BraveSearchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SearchWidgetProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("PrivateSearch")
        .description("Quick access to private web search.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SearchWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SearchWidgetSmallView()
        case .systemMedium:
            SearchWidgetMediumView()
        case .accessoryCircular:
            SearchLockScreenView()
        default:
            SearchWidgetMediumView()
        }
    }
}

// MARK: - Widget Bundle

@main
struct BraveSearchWidgetBundle: WidgetBundle {
    var body: some Widget {
        BraveSearchWidget()
    }
}
