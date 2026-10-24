import Foundation

struct NativeError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

struct Media: Identifiable, Hashable {
    var videoID = ""
    var source = ""
    var title: String
    var poster = ""
    var year = ""
    var sourceName = ""
    var summary = ""
    var rating = ""
    var episodes: [String] = []
    var episode = 0
    var position: Double = 0
    var duration: Double = 0
    var saved: Double = 0
    var id: String { source.isEmpty ? title : source + "+" + videoID }
    init(title: String) { self.title = title }
    init(_ json: [String: Any], key: String? = nil) {
        title = Self.text(json["title"])
        videoID = Self.text(json["id"])
        source = Self.text(json["source"])
        if let key, let split = key.firstIndex(of: "+") {
            source = String(key[..<split]); videoID = String(key[key.index(after: split)...])
        }
        poster = Self.text(json["poster"] ?? json["cover"])
        year = Self.text(json["year"])
        sourceName = Self.text(json["source_name"])
        summary = Self.text(json["desc"]).replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&amp;", with: "&")
        rating = Self.text(json["rate"])
        episodes = json["episodes"] as? [String] ?? []
        episode = max(0, (json["index"] as? Int ?? 1) - 1)
        position = (json["play_time"] as? NSNumber)?.doubleValue ?? 0
        duration = (json["total_time"] as? NSNumber)?.doubleValue ?? 0
        saved = (json["save_time"] as? NSNumber)?.doubleValue ?? 0
    }
    static func text(_ value: Any?) -> String { (value as? String) ?? (value as? NSNumber)?.stringValue ?? "" }
    var favoriteBody: [String: Any] {
        ["cover": poster, "title": title, "source_name": sourceName, "total_episodes": episodes.count,
         "search_title": title, "year": year]
    }
    func recordBody(index: Int, time: Double, total: Double) -> [String: Any] {
        ["cover": poster, "title": title, "source_name": sourceName, "total_episodes": episodes.count,
         "index": index + 1, "play_time": time, "total_time": total, "year": year]
    }
}

struct BrowseCategory: Identifiable {
    let id: String
    let title: String
    let type: String
    let tags: [String]
    var symbol: String {
        switch id {
        case "hot": return "flame.fill"
        case "movie": return "film.fill"
        case "series": return "tv"
        case "variety": return "sparkles.tv"
        default: return "star.fill"
        }
    }
    static let all: [BrowseCategory] = [
        .init(id: "hot", title: "热门剧集", type: "tv", tags: ["热门"]),
        .init(id: "movie", title: "电影", type: "movie", tags: ["热门", "最新", "经典", "豆瓣高分", "华语", "欧美", "韩国", "日本", "动作", "喜剧", "爱情", "科幻", "悬疑", "恐怖"]),
        .init(id: "series", title: "电视剧", type: "tv", tags: ["国产剧", "美剧", "英剧", "韩剧", "日剧", "港剧", "日本动画", "动画"]),
        .init(id: "variety", title: "综艺", type: "tv", tags: ["综艺"]),
        .init(id: "top", title: "豆瓣 Top250", type: "movie", tags: ["top250"])
    ]
}

struct Channel: Identifiable, Hashable {
    var title: String
    var url: URL
    var group: String
    var id: String { url.absoluteString }
    static func parse(_ text: String, relativeTo base: URL? = nil) -> [Channel] {
        var title: String?, group = "其他频道"
        var result: [Channel] = [], seen = Set<String>()
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("#EXTINF:") {
                title = line.split(separator: ",", maxSplits: 1).last.map(String.init)
                if let range = line.range(of: "group-title=\"([^\"]*)\"", options: .regularExpression) {
                    group = String(line[range]).replacingOccurrences(of: "group-title=\"", with: "").dropLast().description
                } else { group = "其他频道" }
            } else if !line.isEmpty && !line.hasPrefix("#"), let name = title,
                      let url = URL(string: line, relativeTo: base)?.absoluteURL,
                      ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                if seen.insert(url.absoluteString).inserted { result.append(.init(title: name, url: url, group: group)) }
                title = nil
            }
        }
        return result
    }
}

// Uniform metrics are shared by every poster and every focus row.
struct PosterGridLayout {
    static let horizontalGap = 44.0
    static let verticalGap = 42.0
    let columns: Int
    let cardWidth: Double
    let itemCount: Int
    init(width: Double, itemCount: Int) {
        let width = max(1, width)
        columns = max(1, min(6, Int((width + Self.horizontalGap) / (210 + Self.horizontalGap))))
        cardWidth = floor((width - Double(columns - 1) * Self.horizontalGap) / Double(columns))
        self.itemCount = max(0, itemCount)
    }
    var posterHeight: Double { floor(cardWidth * 1.5) }
    var cellHeight: Double { posterHeight + 24 + 62 + 28 }
    var rowCount: Int { (itemCount + columns - 1) / columns }
    func indices(in row: Int) -> Range<Int> {
        let start = min(itemCount, max(0, row) * columns)
        return start..<min(start + columns, itemCount)
    }
}

struct MediaPage {
    static let pageSize = 20
    private(set) var items: [Media] = []
    private(set) var offset = 0
    private(set) var hasMore = true
    mutating func append(_ page: [Media]) {
        var seen = Set(items.map(\.id))
        let fresh = page.filter { seen.insert($0.id).inserted }
        items += fresh
        offset += page.count
        // A repeated page must not turn automatic pagination into a request loop.
        hasMore = page.count >= Self.pageSize && !fresh.isEmpty
    }
}
