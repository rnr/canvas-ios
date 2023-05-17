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

public struct DownloaderClient {
    public static func setup() {
        let storageConfig = OfflineStorageConfig()
        storageConfig.helpers = [PageHelper()]
        OfflineStorageManager.shared.setConfig(config: storageConfig)

        let env = AppEnvironment.shared

        var pages: Store<GetPage>?
        let downloaderConfig = OfflineDownloaderConfig(
            preparationBlock: { entry, completionHandler in
                if entry.dataModel.type.lowercased().contains("page") {
                    if let page = OfflineStorageManager.shared.object(from: entry.dataModel, for: Page.self),
                       let context = Context(canvasContextID: page.contextID) {

                        pages = env.subscribe(GetPage(context: context, url: page.url)) {}

                        pages?.refresh(force: true, callback: {[weak entry] page in
                            if let body = page?.body {
                                let fullHTML = CoreWebView().html(for: body)
                                entry?.parts.removeAll()
                                entry?.addHtmlPart(fullHTML, baseURL: page?.html_url.absoluteString)
                            }
                            completionHandler()
                        })
                        return
                    }
                }
                completionHandler()
            }
        )
        OfflineDownloadsManager.shared.setConfig(downloaderConfig)
    }
}
