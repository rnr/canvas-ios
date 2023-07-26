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
import mobile_offline_downloader_ios

public class DownloadableItemProvider {
    public static var shared: DownloadableItemProvider = .init()

    private(set) var userInfo: String?
    private(set) var assetType: String?
    private(set) var object: OfflineDownloadTypeProtocol?
    private(set) var course: Course?

    func set(
        userInfo: String,
        assetType: String,
        object: OfflineDownloadTypeProtocol,
        course: Course
    ) {
        self.userInfo = userInfo
        self.assetType = assetType
        self.object = object
        self.course = course
    }

    func update(object: OfflineDownloadTypeProtocol) {
        self.object = object
    }
}

public class DownloadableViewController: UIViewController, ErrorViewController {

    deinit {
        print("☠️ Deinitialized -> \(String.init(describing: self))☠️")
    }

    // MARK: - Properties -

    private let downloadsManager = OfflineDownloadsManager.shared
    private let storageManager = OfflineStorageManager.shared
    private let downloadableItemProvider = DownloadableItemProvider.shared

    private let imageDownloader = ImageDownloader()
    private let env = AppEnvironment.shared

    private var course: Course? {
        downloadableItemProvider.course
    }
    private var object: OfflineDownloadTypeProtocol? {
        downloadableItemProvider.object
    }
    private var userInfo: String? {
        downloadableItemProvider.userInfo
    }
    private var assetType: String? {
        downloadableItemProvider.assetType
    }

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

    public func configure() {
        layout()
        actions()
        observeDownloadsEvents()
    }

    public func actions() {
        downloadButton.onTap = { [weak self] state in
            guard let self = self else {
                return
            }
            switch state {
            case .downloaded:
                self.delete()
            case .waiting, .downloading:
                self.pause()
            case .retry:
                do {
                    try self.object.flatMap {
                        try self.downloadsManager.resume(object: $0)
                    }
                } catch {
                    showError(error)
                }
            case .idle:
                self.download()
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

    public var downloadBarButtonItem: UIBarButtonItem {
        let rightBarButtonItem = UIBarButtonItem(customView: downloadButton)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return rightBarButtonItem
    }

    // MARK: - Private Intents -

    private func download() {
        guard  let object = self.object,
                let userInfo = self.userInfo,
                let assetType = self.assetType,
                let url = URL(string: userInfo)
        else { return }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = assetType
        do {
            try downloadsManager.start(
                object: object,
                userInfo: components?.url?.absoluteString
            )
            addOrUpdateCourse()
            downloadButton.currentState = .waiting
        } catch {
            showError(error)
        }
    }

    private func observeDownloadsEvents() {
        downloadsSubscriber = downloadsManager
            .publisher
            .sink { [weak self] event in
                switch event {
                case .statusChanged(object: let event):
                    self?.statusChanged(event)
                case .progressChanged(object: let event):
                    self?.progressChanged(event)
                }
            }

        object.flatMap {
            downloadsManager.eventObject(for: $0) { [weak self] result in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    result.success { event in
                        self.statusChanged(event)
                    }
                    self.downloadButton.isHidden = false
                }
            }
        }
    }

    private func statusChanged(_ event: OfflineDownloadsManagerEventObject) {
        guard let object = object else {
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
                downloadButton.currentState = .downloaded
            case .initialized, .preparing:
                downloadButton.currentState = .waiting
            case .active:
                downloadButton.currentState = .downloading
                downloadButton.progress = Float(event.progress)
            case .removed:
                downloadButton.currentState = .idle
            case .failed, .paused:
                downloadButton.currentState = .retry
            default:
                downloadButton.currentState = .idle
            }
        } catch {
            showError(error)
        }
    }

    private func progressChanged(_ event: OfflineDownloadsManagerEventObject) {
        guard let object = object else {
            return
        }
        do {
            let eventObjectId = try event.object.toOfflineModel().id
            let objectId = try object.toOfflineModel().id
            guard eventObjectId == objectId else {
                return
            }
            if event.progress == 0.0 {
                return
            }
            downloadButton.progress = Float(event.progress)
        } catch {
            showError(error)
        }
    }

    private func addOrUpdateCourse() {
        guard let course = course else {
            return
        }

        let courseStorageDataModel = CourseStorageDataModel(
            course: course
        )
        if let imageDownloadURL = course.imageDownloadURL {
            imageDownloader.downloadImage(from: imageDownloadURL)
        }

        if course.courseColor == nil {
            course.courseColor = course.contextColor?.color.hexString
        }

        storageManager.save(courseStorageDataModel) { result in
            result.success {
                print("success")
            }
            result.failure { _ in
                print("failure")
            }
        }
    }

    private func pause() {
        guard let object = object else {
            return
        }
        do {
            try downloadsManager.pause(object: object)
        } catch {
            showError(error)
        }
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
