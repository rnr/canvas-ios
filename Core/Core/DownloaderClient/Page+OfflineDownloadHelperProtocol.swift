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
        return entry.dataModel.type.lowercased().contains("page")
    }

    public static func prepareForDownload(entry: OfflineDownloaderEntry) async throws {
        try await withCheckedThrowingContinuation({[weak entry] continuation in
            let env = AppEnvironment.shared
            var pages: Store<GetPage>?
            if entry?.dataModel.type.lowercased().contains("page") == true {
                if let dataModel = entry?.dataModel, let page = Page.fromOfflineModel(dataModel),
                   let context = Context(canvasContextID: page.contextID) {

                    pages = env.subscribe(GetPage(context: context, url: page.url)) {}

                    pages?.refresh(force: true, callback: {[entry] page in
                        DispatchQueue.main.async {
                            if let body = page?.body {
                                let fullHTML = CoreWebView().html(for: body)
                                entry?.parts.removeAll()
                                entry?.addHtmlPart(fullHTML, baseURL: page?.html_url.absoluteString)
                            }
                            continuation.resume()
                        }
                    })
                    return
                }
            }
            continuation.resume()
        })
    }
}
