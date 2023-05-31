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

public class DownloadableViewController: UIViewController {

    // MARK: - Properties -

    private let downloadsManager = OfflineDownloadsManager.shared
    private let storageManager = OfflineStorageManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var course: Course?
    private var object: OfflineDownloadTypeProtocol?

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
    }

    public func setupCourse(_ course: Course?) {
        self.course = course
    }

    public func configure() {
        layout()
        actions()
    }

    func actions() {
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

    // MARK: - Layout -

    public func layout() {
        attachDownloadButton()
    }

    public func attachDownloadButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: downloadButton)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
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
                if isSaved {
                    self.addOrUpdateCourse()
                }
                completion(isSaved)
            } else {
                self.downloadButton.currentState = .idle
                completion(false)
            }
        }
    }

    // MARK: - Private Intents -

    private func download() {
        guard  let object = object else {
            return
        }
        do {
            try downloadsManager.addAndStart(object: object)
            downloadButton.currentState = .waiting
            downloadsManager
                .publisher
                .sink { [weak self] event in
                    guard let self = self else {
                        return
                    }
                    switch event {
                    case .statusChanged(object: let event):
                        switch event.status {
                        case .completed:
                            self.downloadButton.currentState = .downloaded
                        case .active, .preparing, .initialized:
                            self.downloadButton.currentState = .downloading
                        case .removed:
                            do {
                                if try event.object.toOfflineModel().id == object.toOfflineModel().id {
                                    self.downloadButton.currentState = .idle
                                }
                            } catch {
                                self.showAlet(title: "Error", message: error.localizedDescription)
                            }
                        default:
                            self.downloadButton.currentState = .idle
                        }
                    case .progressChanged(object: let event):
                        print(event.progress, "progress")
                        self.downloadButton.progress = Float(event.progress)
                    }
                }.store(in: &cancellables)
        } catch {
            showAlet(title: "Error", message: error.localizedDescription)
        }
    }

    private func addOrUpdateCourse() {
        guard let course = course else {
            return
        }
        storageManager.save(course) { _ in }
    }

    private func delete() {
        guard let object = object else {
            return
        }
        do {
            try downloadsManager.delete(object: object)
        } catch {
            showAlet(title: "Error", message: error.localizedDescription)
        }
    }
}

extension DownloadableViewController {
    func showAlet(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
