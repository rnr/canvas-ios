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

import mobile_offline_downloader_ios

extension ModuleItemCell {

    func prepareForDownload() {
        guard let item = item, let course = course else {
            return
        }
        addDownloadButton()
        downloadButtonHelper.update(
            object: item,
            course: course,
            userInfo: "ModuleItem://courses/\(course.id)/modules"
        )
        downloadButtonHelper.status(
            for: item,
            onState: {  [weak self] state, eventObjectId in
                guard let self = self, eventObjectId == self.item?.id else {
                    return
                }
                self.downloadButton.currentState = state
                if state == .waiting {
                    self.downloadButton.waitingView.startSpinning()
                }
            },
            onProgress: { [weak self] progress, eventObjectId in
                guard let self = self, eventObjectId == self.item?.id  else {
                    return
                }
                self.downloadButton.progress = Float(progress)
            }
        )
    }

    func addDownloadButton() {
        if !hStackView.arrangedSubviews.contains(where: { $0.tag == 777 }) {
            downloadButton.tag = 777
            hStackView.addArrangedSubview(downloadButton)
            downloadButton.translatesAutoresizingMaskIntoConstraints = false
            downloadButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
            downloadButton.onTap = { [weak self] state in
                guard let self = self, let item = self.item else {
                    return
                }
                switch state {
                case .downloaded:
                    self.downloadButtonHelper.delete(object: item)
                case .idle:
                    self.downloadButtonHelper.download(object: item)
                default:
                    break
                }
            }
        }
    }

    func addSavedImage() {
        if !hStackView.arrangedSubviews.contains(where: { $0.tag == 888 }) {
            let imageView = UIImageView(image: .init(systemName: "checkmark.icloud"))
            imageView.tag = 888
            hStackView.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        }
    }

    func removeSavedImage() {
        if let imageView = hStackView.arrangedSubviews.first(where: { $0.tag == 888 }) {
            imageView.removeFromSuperview()
        }
    }

    func addActivityIndicator() -> UIActivityIndicatorView {
        if let activityIndicator = hStackView.arrangedSubviews.first(where: { $0.tag == 555 }) as? UIActivityIndicatorView {
            return activityIndicator
        } else {
            let activityIndicator = UIActivityIndicatorView()
            activityIndicator.color = .lightGray
            activityIndicator.tag = 555
            hStackView.addArrangedSubview(activityIndicator)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.widthAnchor.constraint(equalToConstant: 25).isActive = true
            return activityIndicator
        }
    }

    func removeActivityIndicator() {
        if let activityIndicator = hStackView.arrangedSubviews.first(where: { $0.tag == 555 }) {
            activityIndicator.removeFromSuperview()
        }
    }
}
