//
//  VideoPlayerViewModel.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/2.
//

import Foundation
import AVKit
import Combine

// MARK: - VideoPlayerViewModel
class VideoPlayerViewModel: NSObject {
    private(set) var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?

    var onReadyToPlay: ((AVPlayerLayer) -> Void)?

    @Published var isMuted: Bool = false {
        didSet {
            player?.isMuted = isMuted
        }
    }
    @Published private(set) var isPlaying: Bool = false
    private var cancellables = Set<AnyCancellable>()

    func configure(with video: Video, isMuted: Bool) {
        let globalMuted = UserDefaults.standard.bool(forKey: "MuteSetting")
        self.isMuted = globalMuted
        guard let url = video.url else { return }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        let queuePlayer = AVQueuePlayer()
        self.player = queuePlayer
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.playerLayer = AVPlayerLayer(player: queuePlayer)
        self.playerLayer?.videoGravity = .resizeAspectFill

        queuePlayer.isMuted = isMuted

        queuePlayer.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .map { $0 == .playing }
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

        if let layer = playerLayer {
            onReadyToPlay?(layer)
        }
        queuePlayer.play()
    }

    func updateLayout(frame: CGRect) {
        playerLayer?.frame = frame
    }

    deinit {
        player?.pause()
    }
}
