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

enum OfflineDownloaderStatus {
    case initialized, preparing, paused, active, partialy, completed

    var canResume: Bool {
        return self == .paused
    }

    var canStart: Bool {
        return self == .initialized || self == .paused
    }
}

public class OfflineDownloaderEntry {
    public var dataModel: OfflineStorageDataModel
    var parts: [OfflineDownloaderEntryPart]
    var percent: CGFloat = 0
    var status: OfflineDownloaderStatus {
        // TODO: go throught parts and check status then return part
        return .initialized
    }

    init(dataModel: OfflineStorageDataModel, parts: [OfflineDownloaderEntryPart]) {
        self.dataModel = dataModel
        self.parts = parts
    }

    public func addHtmlPart(_ html: String, baseURL: String?) {
        let part = OfflineDownloaderEntryPart(value: .html(html: html, baseURL: baseURL))
        parts.append(part)
    }

    public func addURLPart(_ link: String) {
        let part = OfflineDownloaderEntryPart(value: .url(link))
        parts.append(part)
    }
}
