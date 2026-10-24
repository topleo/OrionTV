import SwiftUI

struct DetailView: View {
    let original: Media
    @EnvironmentObject private var session: LunaSession
    @State private var variants: [Media] = []
    @State private var selectedID = ""
    @State private var records: [Media] = []
    @State private var favoriteIDs = Set<String>()
    @State private var loading = true
    @State private var saving = false
    @State private var error: String?
    @State private var playback: PlaybackState?
    private var current: Media? { variants.first { $0.id == selectedID } ?? variants.first }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .top, spacing: 48) {
                    AsyncImage(url: session.images(current?.poster ?? original.poster)) { image in image.resizable().scaledToFill() }
                    placeholder: { Rectangle().fill(.quaternary).overlay { Image(systemName: "film").font(.largeTitle) } }
                    .frame(width: 280, height: 420).clipped().clipShape(RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 26) {
                        Text(current?.title ?? original.title).font(.largeTitle.bold())
                        if let item = current {
                            Text([item.year, item.sourceName, "\(item.episodes.count) 集"].filter { !$0.isEmpty }.joined(separator: " · ")).foregroundStyle(.secondary)
                            HStack(spacing: 30) {
                                Button(resumeLabel(item), systemImage: "play.fill") { play(item, index: nil) }.buttonStyle(.borderedProminent).disabled(item.episodes.isEmpty)
                                Button(favoriteIDs.contains(item.id) ? "取消收藏" : "加入收藏", systemImage: favoriteIDs.contains(item.id) ? "heart.fill" : "heart") {
                                    Task { await toggleFavorite(item) }
                                }.disabled(saving)
                            }
                            if variants.count > 1 {
                                Picker("播放来源", selection: $selectedID) {
                                    ForEach(variants) { source in Text("\(source.sourceName.isEmpty ? source.source : source.sourceName) · \(source.episodes.count) 集").tag(source.id) }
                                }.pickerStyle(.menu)
                            }
                            if !item.summary.isEmpty { Text(item.summary).font(.body).foregroundStyle(.secondary).lineLimit(7) }
                        }
                        if loading { ProgressView("正在查找可播放来源…") }
                        if let error { Text(error).foregroundStyle(.orange).font(.callout) }
                        if !loading && variants.isEmpty { Button("重新查找") { Task { await load() } } }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if let item = current, !item.episodes.isEmpty {
                    Text("选集").font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 32)], spacing: 32) {
                        ForEach(item.episodes.indices, id: \.self) { index in
                            Button { play(item, index: index) } label: {
                                Text("第 \(index + 1) 集")
                                    .font(.system(size: 24, weight: .medium)).monospacedDigit()
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("episode-\(index + 1)")
                        }
                    }.padding(.vertical, 20)
                }
            }.padding(64)
        }
        .task { await load() }
        .fullScreenCover(item: $playback, onDismiss: { Task { records = (try? await session.library("/api/playrecords")) ?? records } }) { state in
            NativePlayerView(state: state)
        }
    }
    private func resumeLabel(_ item: Media) -> String {
        if let record = records.first(where: { $0.id == item.id }), record.position > 0 { return "继续观看 · 第 \(record.episode + 1) 集" }
        return "播放"
    }
    private func play(_ item: Media, index: Int?) {
        let record = records.first { $0.id == item.id }
        let episode = min(max(0, index ?? record?.episode ?? 0), max(0, item.episodes.count - 1))
        playback = PlaybackState(media: item, episode: episode, resume: index == nil ? record?.position ?? 0 : 0, session: session)
    }
    private func toggleFavorite(_ item: Media) async {
        saving = true; error = nil
        do {
            if favoriteIDs.contains(item.id) { try await session.removeFavorite(item); favoriteIDs.remove(item.id) }
            else { try await session.saveFavorite(item); favoriteIDs.insert(item.id) }
        } catch { self.error = error.localizedDescription }; saving = false
    }
    private func updateVariants(_ results: [Media]) {
        let exact = results.filter { $0.title == original.title }
        var seen = Set<String>()
        variants = (exact.isEmpty ? results : exact).filter { !$0.episodes.isEmpty && seen.insert($0.id).inserted }
    }
    private func load() async {
        loading = true; error = nil
        do {
            favoriteIDs = Set(((try? await session.library("/api/favorites")) ?? []).map(\.id))
            records = (try? await session.library("/api/playrecords")) ?? []
            var results: [Media] = []
            if !original.source.isEmpty { results = (try? await session.search(original.title, source: original.source)) ?? [] }
            if results.isEmpty { results = try await session.search(original.title) }
            try Task.checkCancellation()
            updateVariants(results)
            selectedID = variants.first(where: { $0.id == original.id })?.id ?? variants.first?.id ?? ""
            loading = false
            if !original.source.isEmpty, let others = try? await session.search(original.title) {
                try Task.checkCancellation(); updateVariants(results + others)
            }
            if variants.isEmpty { error = "暂时没有可播放来源。请稍后重试，或用其他关键词搜索。" }
        } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
        if !Task.isCancelled { loading = false }
    }
}
