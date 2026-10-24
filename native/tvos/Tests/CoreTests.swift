import Foundation

@main struct CoreTests {
    static func main() throws {
        let search: [String: Any] = ["id": 123, "source": "alpha", "title": "影片", "episodes": ["https://example.com/1.m3u8"], "year": 2026, "desc": "<p>简介&nbsp;内容</p>"]
        let media = Media(search)
        precondition(media.id == "alpha+123" && media.year == "2026" && media.summary == "简介 内容")
        let stored = Media(["title": "影片", "index": 3, "play_time": 92.5, "total_time": 600, "save_time": 10], key: "alpha+id+extra")
        precondition(stored.videoID == "id+extra" && stored.episode == 2 && stored.position == 92.5)
        let record = media.recordBody(index: 2, time: 40, total: 300)
        precondition(record["index"] as? Int == 3 && record["total_episodes"] as? Int == 1)
        _ = try JSONSerialization.data(withJSONObject: record)
        let playlist = "#EXTM3U\n#EXTINF:-1 group-title=\"新闻\",新闻频道\nstreams/news.m3u8\n#EXTINF:-1,重复频道\nstreams/news.m3u8\n#EXTINF:-1,频道二\nhttps://example.com/two.m3u8\n#EXTINF:-1,无效频道\nfile:///etc/passwd\n"
        let channels = Channel.parse(playlist, relativeTo: URL(string: "https://example.com/list.m3u"))
        precondition(channels.count == 2 && channels[0].url.absoluteString == "https://example.com/streams/news.m3u8" && channels[0].group == "新闻")
        for width in [720.0, 1100.0, 1500.0, 1800.0] {
            let grid = PosterGridLayout(width: width, itemCount: 10)
            precondition(grid.columns >= 1 && grid.columns <= 6)
            let occupied = grid.cardWidth * Double(grid.columns) + PosterGridLayout.horizontalGap * Double(grid.columns - 1)
            precondition(occupied <= width && width - occupied < Double(grid.columns))
            precondition(grid.posterHeight == floor(grid.cardWidth * 1.5))
            precondition((0..<grid.rowCount).flatMap { Array(grid.indices(in: $0)) } == Array(0..<10))
        }
        let partial = PosterGridLayout(width: 1500, itemCount: 10)
        precondition(partial.columns == 6 && partial.rowCount == 2 && Array(partial.indices(in: 1)) == [6, 7, 8, 9])
        precondition(PosterGridLayout(width: 1500, itemCount: 0).rowCount == 0)
        var page = MediaPage()
        let first = (0..<20).map { Media(title: "影片\($0)") }
        page.append(first)
        precondition(page.items.count == 20 && page.offset == 20 && page.hasMore)
        page.append(Array(first.suffix(2)) + (20..<38).map { Media(title: "影片\($0)") })
        precondition(page.items.count == 38 && page.offset == 40 && page.hasMore)
        page.append([Media(title: "末页")])
        precondition(page.items.count == 39 && page.offset == 41 && !page.hasMore)
        var repeated = MediaPage(); repeated.append(first); repeated.append(first)
        precondition(repeated.items.count == 20 && repeated.offset == 40 && !repeated.hasMore)
        print("Uniform poster geometry, incomplete rows, pagination cursor, deduplication and end-of-data checks passed")
        print("Native model decoding, library keys, episode indexing, progress payloads and M3U parsing passed")
    }
}
