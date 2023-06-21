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

extension ModuleItem: OfflineDownloadTypeProtocol {
    public static func canDownload(entry: OfflineDownloaderEntry) -> Bool {
        guard let item = try? fromOfflineModel(entry.dataModel) else { return false }
        if case .externalTool = item.type {
            return true
        }
        return false
    }

    public static func prepareForDownload(entry: OfflineDownloaderEntry) async throws {
        let item = try fromOfflineModel(entry.dataModel)
        if case let .externalTool(toolID, url) = item.type {
            let tools = LTITools(
                context: .course(item.courseID),
                id: toolID,
                url: url,
                launchType: .module_item,
                moduleID: item.moduleID,
                moduleItemID: item.id
            )

            let url: URL = try await withCheckedThrowingContinuation { continuation in
                tools.getSessionlessLaunch { response in
                    guard let response = response else {
                        continuation.resume(throwing: ModuleItemError.wrongSession)
                        return
                    }

                    let url = response.url.appendingQueryItems(URLQueryItem(name: "platform", value: "mobile"))
                    if response.name == "Google Apps" {
                        continuation.resume(throwing: ModuleItemError.unsupported)
                    } else {
                        continuation.resume(returning: url)
                    }
                }
            }

            let extractor = await OfflineHTMLDynamicsLinksExtractor(url: url)
            try await extractor.fetch()
            if let latestURL = await extractor.latestRedirectURL {
                let downloader = OfflineLinkDownloader()
                let cookieString = await extractor.cookies().cookieString
                downloader.additionCookies = cookieString
                let ltiContents = try await downloader.contents(urlString: latestURL.absoluteString)
                entry.addHtmlPart(ltiContents, baseURL: nil, cookieString: cookieString)
            }
        }
    }

    public func downloaderEntry() throws -> OfflineDownloaderEntry {
        let model = try self.toOfflineModel()
        return OfflineDownloaderEntry(dataModel: model, parts: [])
    }
}

extension ModuleItem {
    enum ModuleItemError: Error, LocalizedError {
        case wrongSession
        case unsupported

        var errorDescription: String? {
            switch self {
            case .wrongSession:
                return "Can't get sessionless launch."
            case .unsupported:
                return "Unsupported type"
            }
        }
    }
}
