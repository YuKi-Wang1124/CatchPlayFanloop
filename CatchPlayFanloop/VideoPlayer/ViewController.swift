//
//  ViewController.swift
//  CatchPlayFanloop
//
//  Created by 王昱淇 on 2025/4/29.
//

import UIKit
import AVKit
import Combine

// MARK: -
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

// MARK: -
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


// MARK: -
class VideoPlayerViewModel: NSObject {
    private(set) var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?

    var onReadyToPlay: ((AVPlayerLayer) -> Void)?

    @Published var isMuted: Bool = false
    @Published private(set) var isPlaying: Bool = false
    private var cancellables = Set<AnyCancellable>()

    func configure(with video: Video, isMuted: Bool) {
        self.isMuted = isMuted
        guard let url = video.url else { return }

        let asset = AVAsset(url: url)
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

// MARK: -
class VideoPlayerCell: UICollectionViewCell {
    private let overlayView = VideoOverlayView()
    let viewModel = VideoPlayerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.clipsToBounds = true
        contentView.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: 120)
        ])
        overlayView.muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        viewModel.updateLayout(frame: contentView.bounds)
    }
    
    func configure(with video: Video, isMuted: Bool) {
        overlayView.titleLabel.text = video.title
        overlayView.descriptionLabel.text = video.description
        
        viewModel.onReadyToPlay = { [weak self] layer in
            guard let self = self else { return }
            self.contentView.layer.insertSublayer(layer, below: self.overlayView.layer)
            layer.frame = self.contentView.bounds
        }
        
        viewModel.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMuted in
                self?.overlayView.muteButton.setImage(
                    UIImage(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"),
                    for: .normal
                )
            }
            .store(in: &cancellables)
        
        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { isPlaying in
                print("isPlaying:", isPlaying)
            }
            .store(in: &cancellables)
        
        viewModel.configure(with: video, isMuted: isMuted)
    }
    
    @objc private func toggleMute() {
        viewModel.isMuted.toggle()
        viewModel.player?.isMuted = viewModel.isMuted
    }
}

// MARK: -
class VideoListViewModel {
    @Published private(set) var videos: [Video] = []
    
    func loadVideoData() {
        DispatchQueue.global().async {
            guard let url = Bundle.main.url(forResource: "video_data", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([Video].self, from: data) else {
                print("Failed to load video_data.json")
                return
            }
            
            DispatchQueue.main.async {
                self.videos = decoded
            }
        }
    }
    
    func video(at index: Int) -> Video? {
        guard index >= 0 && index < videos.count else { return nil }
        return videos[index]
    }
    
    var videoCount: Int {
        return videos.count
    }
}

class VideoListViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let viewModel = VideoListViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var currentPlayingIndexPath: IndexPath?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        viewModel.$videos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.loadVideoData()
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VideoPlayerCell.self, forCellWithReuseIdentifier: "VideoPlayerCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let firstIndexPath = IndexPath(item: 0, section: 0)
        
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: firstIndexPath, at: .top, animated: false)
        
        guard let video = viewModel.video(at: 0) else { return }
        if let cell = collectionView.cellForItem(at: firstIndexPath) as? VideoPlayerCell {
            cell.configure(with: video, isMuted: false)
        }
        currentPlayingIndexPath = IndexPath(item: 0, section: 0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let targetIndexPath = findMostVisibleCellIndexPath() else { return }

        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let videoCell = cell as? VideoPlayerCell else { continue }

            if indexPath == targetIndexPath {
                videoCell.viewModel.player?.play()
            } else {
                videoCell.viewModel.player?.pause()
            }
        }

        currentPlayingIndexPath = targetIndexPath
    }

    private func findMostVisibleCellIndexPath() -> IndexPath? {
        var maxVisibleHeight: CGFloat = 0
        var targetIndexPath: IndexPath?

        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            let cellFrame = collectionView.convert(cell.frame, to: view)
            let intersection = cellFrame.intersection(view.bounds)
            let visibleHeight = intersection.height

            if visibleHeight > maxVisibleHeight && visibleHeight >= view.bounds.height * 0.5 {
                maxVisibleHeight = visibleHeight
                targetIndexPath = indexPath
            }
        }

        return targetIndexPath
    }
}

// MARK: - CollectionView: Delegate, DataSource
extension VideoListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.videoCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let video = viewModel.video(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoPlayerCell", for: indexPath) as? VideoPlayerCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: video, isMuted: false)
        return cell
    }
}
