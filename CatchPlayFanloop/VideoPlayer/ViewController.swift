//
//  ViewController.swift
//  CatchPlayFanloop
//
//  Created by 王昱淇 on 2025/4/29.
//

import UIKit
import AVKit
import Combine

// MARK: - VideoOverlayView
class VideoOverlayView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textColor = .white
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .white
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let muteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var isExpanded = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
     
        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading

        addSubview(stack)
        addSubview(muteButton)

        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -36),
            stack.trailingAnchor.constraint(equalTo: muteButton.leadingAnchor, constant: -8),

            muteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            muteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -36),
            muteButton.widthAnchor.constraint(equalToConstant: 24),
            muteButton.heightAnchor.constraint(equalToConstant: 24)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleExpandToggle))
        titleLabel.addGestureRecognizer(tapGesture)
        descriptionLabel.addGestureRecognizer(tapGesture)

        configureUIState()
    }

    @objc private func handleExpandToggle() {
        isExpanded.toggle()
        configureUIState()
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    private func configureUIState() {
        titleLabel.numberOfLines = isExpanded ? 0 : 1
        descriptionLabel.numberOfLines = isExpanded ? 0 : 1
    }

    func setCollapsed() {
        isExpanded = false
        configureUIState()
    }
}


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

// MARK: -
class VideoPlayerCell: UICollectionViewCell {
    private let overlayView = VideoOverlayView()
    let viewModel = VideoPlayerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    var muteToggleHandler: ((Bool) -> Void)?
    
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

    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        viewModel.isMuted = UserDefaults.standard.bool(forKey: "MuteSetting")
        overlayView.setCollapsed()
        updateMuteIcon(for: viewModel.isMuted)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        viewModel.updateLayout(frame: contentView.bounds)
    }
    
    private func updateMuteIcon(for isMuted: Bool) {
        overlayView.muteButton.setImage(
            UIImage(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"),
            for: .normal
        )
    }
    
    func configure(with video: Video, isMuted: Bool) {
        overlayView.titleLabel.text = video.title
        overlayView.descriptionLabel.text = video.description

        viewModel.onReadyToPlay = { [weak self] layer in
            guard let self = self else { return }
            self.contentView.layer.insertSublayer(layer, below: self.overlayView.layer)
            layer.frame = self.contentView.bounds
        }

        // Always use the latest persisted mute setting
        let globalMuted = UserDefaults.standard.bool(forKey: "MuteSetting")
        viewModel.configure(with: video, isMuted: globalMuted)

        cancellables.removeAll()

        viewModel.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMuted in
                self?.updateMuteIcon(for: isMuted)
            }
            .store(in: &cancellables)

        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { isPlaying in
                print("isPlaying:", isPlaying)
            }
            .store(in: &cancellables)

        updateMuteIcon(for: globalMuted)
    }
    
    @objc private func toggleMute() {
        let newState = !viewModel.isMuted
        viewModel.isMuted = newState
        UserDefaults.standard.set(newState, forKey: "MuteSetting")
        muteToggleHandler?(newState)
    }
    
    func syncMuteIcon() {
        updateMuteIcon(for: viewModel.isMuted)
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

// MARK: - VideoListViewController
class VideoListViewController: UIViewController {
    private var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "MuteSetting") }
        set { UserDefaults.standard.set(newValue, forKey: "MuteSetting") }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.bounces = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(VideoPlayerCell.self, forCellWithReuseIdentifier: "VideoPlayerCell")
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let firstIndexPath = IndexPath(item: 0, section: 0)
        
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: firstIndexPath, at: .top, animated: false)
        }
        
        guard let video = viewModel.video(at: 0) else { return }
        if let cell = collectionView.cellForItem(at: firstIndexPath) as? VideoPlayerCell {
            cell.configure(with: video, isMuted: isMuted)
            cell.muteToggleHandler = { [weak self] newMutedState in
                self?.isMuted = newMutedState
                self?.collectionView.visibleCells.forEach { visibleCell in
                    guard let videoCell = visibleCell as? VideoPlayerCell else { return }
                    videoCell.viewModel.isMuted = newMutedState
                    videoCell.syncMuteIcon()
                }
            }
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
        
        cell.configure(with: video, isMuted: isMuted)
        cell.muteToggleHandler = { [weak self] newMutedState in
            self?.isMuted = newMutedState
            self?.collectionView.visibleCells.forEach { visibleCell in
                guard let videoCell = visibleCell as? VideoPlayerCell else { return }
                videoCell.viewModel.isMuted = newMutedState
                videoCell.syncMuteIcon()
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoPlayerCell else { return }
        videoCell.viewModel.isMuted = isMuted
        videoCell.syncMuteIcon()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension VideoListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}
