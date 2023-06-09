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
import SwiftUI
import Combine
import  mobile_offline_downloader_ios

public class DownloadableViewController: UIViewController, ErrorViewController {

    // MARK: - Properties -

    private let downloadsManager = OfflineDownloadsManager.shared
    private let storageManager = OfflineStorageManager.shared
    private let env = AppEnvironment.shared

    private var cancellables = Set<AnyCancellable>()
    private var course: Course?
    private var object: OfflineDownloadTypeProtocol?
    private var downloadsSubscriber: AnyCancellable?

    public var downloadButton: DownloadButton = {
        let downloadButton = DownloadButton()
        downloadButton.mainTintColor = .white
        downloadButton.currentState = .idle
        downloadButton.isHidden = true
        return downloadButton
    }()

    // MARK: - Lifecycle -

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }

    // MARK: - Configuration -

    public func setupObject(_ object: OfflineDownloadTypeProtocol?) {
        self.object = object
        observeDownloadsEvents()
        configure()
    }

    public func setupCourse(_ course: Course?) {
        self.course = course
    }

    public func configure() {
        layout()
        actions()
    }

    public func actions() {
        downloadButton.onTap = { [weak self] state in
            switch state {
            case .downloaded:
                self?.delete()
            case .idle:
                self?.download()
            default:
                break
            }
        }
    }

    private func observeDownloadsEvents() {
        downloadsSubscriber = downloadsManager
            .publisher
            .sink { [weak self] event in
                guard let self = self else {
                    return
                }
                switch event {
                case .statusChanged(object: let event):
                    switch event.status {
                    case .completed:
                        do {
                            let eventObjectId = try event.object.toOfflineModel().id
                            self.addOrUpdateCourse(deleting: false, downloadedId: eventObjectId.digits)
                        } catch {
                            self.showError(error)
                        }
                        self.downloadButton.currentState = .downloaded
                    case .active, .preparing, .initialized:
                        self.downloadButton.currentState = .downloading
                    case .removed:
                        guard let object = object else { return }
                        do {
                            let eventObjectId = try event.object.toOfflineModel().id
                            let objectId = try event.object.toOfflineModel().id
                            if eventObjectId == objectId {
                                self.addOrUpdateCourse(deleting: true, downloadedId: eventObjectId.digits)
                                self.downloadButton.currentState = .idle
                            }
                        } catch {
                            showError(error)
                        }
                    default:
                        self.downloadButton.currentState = .idle
                    }
                case .progressChanged(object: let event):
                    print(event.progress, "progress")
                    self.downloadButton.progress = Float(event.progress)
                }
            }
    }

    // MARK: - Layout -

    public func layout() {
        attachDownloadButton()
    }

    public func attachDownloadButton() {
        navigationItem.rightBarButtonItem = downloadBarButtonItem
    }

    // MARK: - Public Intents -

    public func isDownloaded(completion: @escaping(Bool) -> Void) {
        guard let object = object else {
            return
        }
        downloadsManager.isDownloaded(object: object) { [weak self] result in
            guard let self = self else {
                return
            }
            self.downloadButton.isHidden = false
            if case let .success(isSaved) = result {
                self.downloadButton.currentState = isSaved ? .downloaded : .idle
                completion(isSaved)
            } else {
                self.downloadButton.currentState = .idle
                completion(false)
            }
        }
    }

    public var downloadBarButtonItem: UIBarButtonItem {
        let rightBarButtonItem = UIBarButtonItem(customView: downloadButton)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return rightBarButtonItem
    }

    // MARK: - Private Intents -

    private func download() {
        guard  let object = object else {
            return
        }
        do {
            try downloadsManager.addAndStart(object: object)
            downloadButton.currentState = .waiting
        } catch {
            showError(error)
        }
    }

    private func addOrUpdateCourse(deleting: Bool, downloadedId: String) {
        guard let course = course else {
            return
        }
        storageManager.addOrUpdateCourse(
            course: course,
            deleting: deleting,
            downloadedId: downloadedId
        )
    }

    private func delete() {
        guard let object = object else {
            return
        }
        do {
            try downloadsManager.delete(object: object)
        } catch {
            showError(error)
        }
    }
}
