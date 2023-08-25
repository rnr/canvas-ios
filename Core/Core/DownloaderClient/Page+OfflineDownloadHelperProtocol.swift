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

extension Page: OfflineDownloadTypeProtocol {
    public static func canDownload(entry: OfflineDownloaderEntry) -> Bool {
        return entry.dataModel.type.lowercased().contains(OfflineContentType.page.rawValue)
    }

    public static func prepareForDownload(entry: OfflineDownloaderEntry) async throws {
        try await withCheckedThrowingContinuation({[weak entry] continuation in
            guard let entry = entry else { return }
            let env = AppEnvironment.shared
            var pages: Store<GetPage>?
            if entry.dataModel.type == OfflineContentType.page.rawValue {
                let dataModel = entry.dataModel
                if let page = try? Page.fromOfflineModel(dataModel),
                   let context = Context(canvasContextID: page.contextID) {

                    pages = env.subscribe(GetPage(context: context, url: page.url)) {}

                    pages?.refresh(force: true, callback: {[entry] page in
                        DispatchQueue.main.async {
                            if let body = page?.body {
                                let fullHTML = CoreWebView().html(for: body)
                                entry.parts.removeAll()
                                entry.addHtmlPart(fullHTML, baseURL: page?.html_url.absoluteString)
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: PageError.cantGetPage(data: entry.dataModel))
                            }
                        }
                    })
                    return
                }
            }
            continuation.resume(throwing: PageError.cantGetPage(data: entry.dataModel))
        })
    }

    public func downloaderEntry() throws -> OfflineDownloaderEntry {
        let model = try self.toOfflineModel()
        return OfflineDownloaderEntry(dataModel: model, parts: [])
    }

    public static func isCritical(error: Error) -> Bool {
        switch error {
        case PageError.cantGetPage,
            OfflineEntryPartDownloaderError.cantDownloadHTMLPart:
            return true
        default:
            return false
        }
    }

    public static func replaceHTML(tag: String?) async -> String? {
        await DownloaderClient.replaceHtml(for: tag)
    }
}

extension Page {
    enum PageError: Error, LocalizedError {
        case cantGetPage(data: OfflineStorageDataModel)

        var errorDescription: String? {
            switch self {
            case let .cantGetPage(data):
                return "Can't get page: \(data.json)."
            }
        }
    }
}
