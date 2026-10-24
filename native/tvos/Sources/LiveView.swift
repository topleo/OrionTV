import SwiftUI

struct LiveView: View {
    @EnvironmentObject private var session: LunaSession
    @AppStorage("native.liveURL") private var address = ""
    @State private var channels: [Channel] = []
    @State private var loading = false
    @State private var error: String?
    @State private var playback: PlaybackState?
    private var groups: [String] { Array(Set(channels.map(\.group))).sorted() }
    var body: some View {
        Group {
            if address.isEmpty { EmptyState(title: "添加直播频道", subtitle: "在设置中填写 M3U 订阅地址，即可在这里观看。", symbol: "tv") }
            else if loading { ProgressView("正在加载频道…") }
            else if let error {
                VStack { EmptyState(title: "无法加载频道", subtitle: error, symbol: "wifi.exclamationmark"); Button("重试") { Task { await load() } } }
            } else {
                List {
                    ForEach(groups, id: \.self) { group in
                        Section(group) {
                            ForEach(channels.filter { $0.group == group }) { channel in
                                Button(channel.title) {
                                    var media = Media(title: channel.title); media.episodes = [channel.url.absoluteString]
                                    playback = PlaybackState(media: media, episode: 0, resume: 0, session: session)
                                }
                            }
                        }
                    }
                    if channels.isEmpty { Text("订阅中没有找到可播放频道。") }
                }
            }
        }.navigationTitle("直播").task(id: address) { await load() }
        .fullScreenCover(item: $playback) { NativePlayerView(state: $0) }
    }
    private func load() async {
        guard !address.isEmpty else { channels = []; return }
        loading = true; error = nil
        do {
            guard let url = URL(string: address), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { throw NativeError(message: "订阅地址无效。") }
            let (data, response) = try await session.client.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let text = String(data: data, encoding: .utf8) else { throw NativeError(message: "订阅没有返回有效的 M3U 内容。") }
            try Task.checkCancellation(); channels = Channel.parse(text, relativeTo: url)
        } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
        if !Task.isCancelled { loading = false }
    }
}
