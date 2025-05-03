//
//  VideoPlayerCell.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/2.
//

import Foundation
import UIKit
import Combine

// MARK: - VideoPlayerCell
class VideoPlayerCell: UICollectionViewCell {
    static let identifier = "\(VideoPlayerCell.self)"
    
    private lazy var overlayView: VideoOverlayView = {
        let overlayView = VideoOverlayView()
        overlayView.muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        return overlayView
    }()
    
    let viewModel = VideoPlayerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    var muteToggleHandler: ((Bool) -> Void)?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        viewModel.isMuted = UserDefaults.standard.isMuted
        overlayView.setCollapsed()
        updateMuteIcon(for: viewModel.isMuted)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        viewModel.updateLayout(frame: contentView.bounds)
    }
    
    private func setupCellUI() {
        contentView.clipsToBounds = true
        contentView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func updateMuteIcon(for isMuted: Bool) {
        overlayView.muteButton.setImage(
            UIImage(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"),
            for: .normal
        )
    }
    
    func configure(with video: Video) {
        overlayView.titleLabel.text = video.title
        overlayView.descriptionLabel.text = video.description

        viewModel.onReadyToPlay = { [weak self] layer in
            guard let self = self else { return }
            self.contentView.layer.insertSublayer(layer, below: self.overlayView.layer)
            layer.frame = self.contentView.bounds
        }

        let globalMuted = UserDefaults.standard.isMuted
        viewModel.configure(with: video, isMuted: globalMuted)

        bindViewModel()
    }
    
    @objc private func toggleMute() {
        let newState = !viewModel.isMuted
        viewModel.isMuted = newState
        UserDefaults.standard.isMuted = newState
        muteToggleHandler?(newState)
    }
    
    func syncMuteIcon() {
        updateMuteIcon(for: viewModel.isMuted)
    }
    
    private func bindViewModel() {
        cancellables.removeAll()

        viewModel.$isMuted
            .prepend(viewModel.isMuted)
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
    }
}
