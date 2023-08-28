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

final class OfflineAnalyticsMananger {
    func contentType(for url: String) -> String {
        var contentType: String = ""
        if url.contains("/pages/") {
            contentType = "page"
        } else if url.contains("/files/") {
            contentType = "file"
        } else if url.contains("/external_tools/") {
            contentType = "external_tools"
        } else if url.contains("/modules/") {
            contentType = "module"
        } else {
            contentType = "undefined"
        }
        return contentType
    }
    func logEventForState(_ buttonState: Core.DownloadButton.State, itemURL: String) {
        let contentType = contentType(for: itemURL)
        switch buttonState {
        case .downloaded:
            Analytics.shared.logEvent("offline_mode_deleted", parameters: ["content_type": contentType])
        case .downloading, .waiting:
            Analytics.shared.logEvent("offline_mode_paused", parameters: ["content_type": contentType])
        case .retry:
            Analytics.shared.logEvent("offline_mode_resumed", parameters: ["content_type": contentType])
        case .idle:
            Analytics.shared.logEvent("offline_mode_started", parameters: ["content_type": contentType])
        }
    }
    func logEventForStatus(_ entryStatus: OfflineDownloaderStatus, itemURL: String) {
        let contentType = contentType(for: itemURL)
        switch entryStatus {
        case .initialized, .active, .preparing:
            Analytics.shared.logEvent("offline_mode_paused", parameters: ["content_type": contentType])
        case .paused, .failed:
            Analytics.shared.logEvent("offline_mode_resumed", parameters: ["content_type": contentType])
        default:
            Analytics.shared.logEvent("offline_mode_resumed", parameters: ["content_type": contentType])
        }
    }
    func logDeleteAll() {
        Analytics.shared.logEvent("offline_mode_deletedAll")
    }
    func logCompleted() {
        Analytics.shared.logEvent("offline_mode_completed")
    }
    func logError() {
        Analytics.shared.logEvent("offline_mode_error")
    }
}
