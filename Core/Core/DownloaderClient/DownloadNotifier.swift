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

import Foundation
import mobile_offline_downloader_ios
import Combine

final class DownloadNotifier {

    private var downloadsManager: OfflineDownloadsManager = .shared
    private var cancellables: [AnyCancellable] = []

    init() {
        addObservers()
    }

    private func addObservers() {
        downloadsManager.queuePublisher
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .completed(let success):
                    notifyAboutDownloadCompletion(success: success)
                }
            }
            .store(in: &cancellables)
    }

    private func notifyAboutDownloadCompletion(success: Bool) {
        DispatchQueue.main.async {
            let content = UNMutableNotificationContent()
            content.title = "Download Finished"
            content.body = success
            ? "Modules have been saved and are available offline."
            : "An error occured while downloading"
            content.sound = UNNotificationSound.default

            let request = UNNotificationRequest(
                identifier: Foundation.UUID().uuidString,
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request)
        }
    }
}
