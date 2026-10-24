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
        print("Native model decoding, library keys, episode indexing, progress payloads and M3U parsing passed")
    }
}
