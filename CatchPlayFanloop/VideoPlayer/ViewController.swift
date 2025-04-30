//
//  ViewController.swift
//  CatchPlayFanloop
//
//  Created by 王昱淇 on 2025/4/29.
//

import UIKit
import AVKit

class VideoOverlayView: UIView {
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let muteButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 2

        muteButton.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        muteButton.tintColor = .white

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading

        addSubview(stack)
        addSubview(muteButton)

        stack.translatesAutoresizingMaskIntoConstraints = false
        muteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stack.trailingAnchor.constraint(equalTo: muteButton.leadingAnchor, constant: -8),

            muteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            muteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            muteButton.widthAnchor.constraint(equalToConstant: 24),
            muteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

struct Video: Codable {
    let id: Int
    let filename: String
    let title: String
    let description: String
    let hashId: String

    var url: URL? {
        Bundle.main.url(forResource: filename.replacingOccurrences(of: ".mp4", with: ""), withExtension: "mp4")
    }
}

class VideoPlayerCell: UICollectionViewCell {
    private let overlayView = VideoOverlayView()
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with video: Video, isMuted: Bool) {
        overlayView.titleLabel.text = video.title
        overlayView.descriptionLabel.text = video.description

        if let url = video.url {
            player = AVPlayer(url: url)
            player?.isMuted = isMuted
            playerLayer?.removeFromSuperlayer()

            let layer = AVPlayerLayer(player: player)
            layer.frame = contentView.bounds
            layer.videoGravity = .resizeAspectFill
            contentView.layer.insertSublayer(layer, below: overlayView.layer)
            playerLayer = layer

            player?.play()
        }
    }
}

class VideoListViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        return collectionView
    }()
    
    private var videos: [Video] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadVideoData()
        view.addSubview(collectionView)

        collectionView.frame = view.bounds
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VideoPlayerCell.self, forCellWithReuseIdentifier: "VideoPlayerCell")
    }
    
    private func loadVideoData() {
        guard let url = Bundle.main.url(forResource: "video_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Video].self, from: data) else {
            print("❌ Failed to load video_data.json")
            return
        }
        self.videos = decoded
        self.collectionView.reloadData()
    }
}


extension VideoListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoPlayerCell", for: indexPath) as? VideoPlayerCell else {
            return UICollectionViewCell()
        }

        let video = videos[indexPath.item]
        cell.configure(with: video, isMuted: false)
        return cell
    }
}
