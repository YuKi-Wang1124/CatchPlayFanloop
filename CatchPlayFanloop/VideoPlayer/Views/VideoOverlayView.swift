//
//  VideoOverlayView.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/2.
//

import Foundation
import UIKit

// MARK: - VideoOverlayView
class VideoOverlayView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize)
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
