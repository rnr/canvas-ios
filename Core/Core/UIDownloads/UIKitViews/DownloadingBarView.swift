//
// This file is part of Canvas.
// Copyright (C) 2023-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

public class DownloadingBarView: UIView {

    public var onTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.text = "Downloading"
        return titleLabel
    }()

    private let subtitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.text = "Demo page 2.0"
        return titleLabel
    }()

    private let progressView = CustomCircleProgressView(frame: .zero)

    public convenience init() {
        self.init(frame: .zero)
    }

    public func attach(tabBar: UITabBar, in superview: UIView) {
        backgroundColor = .tertiarySystemGroupedBackground

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: tabBar.topAnchor).isActive = true
        heightAnchor.constraint(equalToConstant: 50).isActive = true

        attachProgressView()
        attachLabels()
    }

    private func attachProgressView() {
        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        progressView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true

        progressView.progress = 0.8
        progressView.mainTintColor = Brand.shared.linkColor
    }

    private func attachLabels() {
        [titleLabel, subtitleLabel].forEach(addSubview)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.topAnchor.constraint(equalTo: progressView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true

        subtitleLabel.bottomAnchor.constraint(equalTo: progressView.bottomAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: 10).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true
    }

    @objc
    private func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        onTap?()
    }
}
