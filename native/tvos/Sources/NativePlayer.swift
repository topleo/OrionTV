import SwiftUI
import AVKit
import AVFoundation

@MainActor final class PlaybackState: ObservableObject, Identifiable {
    let id = UUID()
    let media: Media
    let player = AVPlayer()
    let session: LunaSession
    @Published var episode: Int
    @Published var error: String?
    private var resume: Double
    private var periodic: Any?
    private var status: NSKeyValueObservation?
    private var ended: NSObjectProtocol?
    private var active = false
    init(media: Media, episode: Int, resume: Double, session: LunaSession) {
        self.media = media; self.episode = episode; self.resume = resume; self.session = session
    }
    func start() {
        guard !active else { return }; active = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        installEpisode()
        periodic = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 20, preferredTimescale: 600), queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.save() }
        }
    }
    private func installEpisode() {
        status?.invalidate(); status = nil
        if let ended { NotificationCenter.default.removeObserver(ended) }; ended = nil
        guard media.episodes.indices.contains(episode), let url = URL(string: media.episodes[episode]), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            error = "播放地址无效，请返回详情页更换来源。"; return
        }
        let item = AVPlayerItem(url: url)
        let seek = resume; resume = 0
        status = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.player.currentItem === item else { return }
                if item.status == .failed { self.error = "此来源暂时无法播放。请返回详情页更换来源。" }
                if item.status == .readyToPlay && seek > 0 && seek.isFinite {
                    let duration = item.duration.seconds
                    if duration.isFinite && seek < duration - 10 { self.player.seek(to: CMTime(seconds: seek, preferredTimescale: 600)) }
                    self.status?.invalidate(); self.status = nil
                }
            }
        }
        ended = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }; await self.save()
                if self.episode + 1 < self.media.episodes.count { self.episode += 1; self.installEpisode() }
            }
        }
        player.replaceCurrentItem(with: item); player.play()
    }
    func save() async {
        guard let item = player.currentItem else { return }
        await session.saveProgress(media, episode: episode, time: player.currentTime().seconds, duration: item.duration.seconds)
    }
    func stop() {
        guard active else { return }; active = false
        player.pause()
        let seconds = player.currentTime().seconds, duration = player.currentItem?.duration.seconds ?? 0, index = episode
        Task { await session.saveProgress(media, episode: index, time: seconds, duration: duration) }
        if let periodic { player.removeTimeObserver(periodic) }; periodic = nil
        status?.invalidate(); status = nil
        if let ended { NotificationCenter.default.removeObserver(ended) }; ended = nil
    }
}

private struct SystemVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController(); controller.player = player; controller.showsPlaybackControls = true
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) { controller.player = player }
}
struct NativePlayerView: View {
    @ObservedObject var state: PlaybackState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SystemVideoPlayer(player: state.player).ignoresSafeArea()
            .overlay {
                if let error = state.error {
                    VStack(spacing: 32) {
                        Text("无法播放").font(.title.bold())
                        Text(error).font(.body).multilineTextAlignment(.center)
                        Button("返回") { dismiss() }
                    }.padding(60).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            .onAppear { state.start() }.onDisappear { state.stop() }
            .onExitCommand { dismiss() }
    }
}
