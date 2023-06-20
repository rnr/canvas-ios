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

import Combine
import mobile_offline_downloader_ios

extension ModuleItemCell {

    func isDownloaded(_ item: ModuleItem) {
        OfflineDownloadsManager.shared.eventObject(for: item) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { event in
                self.statusChanged(event, item: item)
            }
            result.failure {  _ in
                self.removeSavedImage()
                self.removeActivityIndicator()
            }
        }

        cancellable = OfflineDownloadsManager.shared
            .publisher
            .sink { [weak self] event in
                switch event {
                case .statusChanged(object: let event):
                    self?.statusChanged(event, item: item)
                default:
                    break
                }
            }
    }

    private func statusChanged(_ event: OfflineDownloadsManagerEventObject, item: ModuleItem) {
        guard let object = self.item else {
            return
        }
        do {
            let eventObjectId = try event.object.toOfflineModel().id
            let objectId = try object.toOfflineModel().id
            guard eventObjectId == objectId else {
                return
            }
            switch event.status {
            case .completed:
                addSavedImage()
                removeActivityIndicator()
            case .initialized, .preparing, .active:
                removeSavedImage()
                let activityIndicator = self.addActivityIndicator()
                activityIndicator.startAnimating()
            default:
                removeSavedImage()
                removeActivityIndicator()
            }
        } catch {
            removeSavedImage()
            removeActivityIndicator()
        }
    }

    func addSavedImage() {
        if !hStackView.arrangedSubviews.contains(where: { $0.tag == 888 }) {
            let imageView = UIImageView(image: .init(systemName: "cloud"))
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
