//
//  ViewController.swift
//  CatchPlayFanloop
//
//  Created by 王昱淇 on 2025/4/29.
//

import UIKit
import AVKit
import Combine

// MARK: - VideoListViewController
class VideoListViewController: UIViewController {
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
        collectionView.register(VideoPlayerCell.self, forCellWithReuseIdentifier: VideoPlayerCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private var isMuted: Bool {
        get { UserDefaults.standard.isMuted }
        set { UserDefaults.standard.isMuted = newValue }
    }
    
    private let viewModel = VideoListViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var currentPlayingIndexPath: IndexPath?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
  
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModelBinding()
        viewModel.loadVideoData()
        setupCollectionView()
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
    
    private func setupViewModelBinding() {
        viewModel.$videos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
                DispatchQueue.main.async {
                    guard let self = self,
                          let firstIndexPath = self.findMostVisibleCellIndexPath(),
                          let cell = self.collectionView.cellForItem(at: firstIndexPath) as? VideoPlayerCell,
                          let video = self.viewModel.video(at: firstIndexPath.item) else { return }

                    cell.configure(with: video)
                    cell.viewModel.player?.play()
                    self.currentPlayingIndexPath = firstIndexPath
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCollectionView() {
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
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension VideoListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.videoCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let video = viewModel.video(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        
        guard let cell = collectionView.dequeueCell(ofType: VideoPlayerCell.self, for: indexPath) else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: video)
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

