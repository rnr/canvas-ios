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
        let storageConfig = OfflineStorageConfig { model in
            let env = AppEnvironment.shared
            if model.type.lowercased().contains("page") {
                let json = model.json
                let data = model.json.data(using: .utf8)
                let dictionary = (try? JSONSerialization.jsonObject(with: data!) as? [String: Any]) ?? [:]
                let context = env.database.viewContext
                let predicate = NSPredicate(format: "%K == %@", #keyPath(Page.id), model.id)
                let page: Page = context.fetch(predicate).first ?? context.insert()

                if let url = dictionary["url"] as? String {
                    page.url = url
                }

                if let lastUpdatedInterval = dictionary["lastUpdated"] as? TimeInterval {
                    page.lastUpdated = Date(timeIntervalSince1970: lastUpdatedInterval)
                }

                if let isFrontPage = dictionary["isFrontPage"] as? Bool {
                    page.isFrontPage = isFrontPage
                }

                if let id = dictionary["id"] as? String {
                    page.id = id
                }

                if let title = dictionary["title"] as? String {
                    page.title = title
                }

                if let urlString = dictionary["htmlURL"] as? String {
                    page.htmlURL = URL(string: urlString)
                }

                if let published = dictionary["published"] as? Bool {
                    page.published = published
                }

                if let body = dictionary["body"] as? String {
                    page.body = body
                }

                if let roles = dictionary["editingRoles"] as? [String] {
                    page.editingRoles = roles
                }

                if let contextID = dictionary["contextID"] as? String {
                    page.contextID = contextID
                }

                return page
            }

            return nil
        } toDataBlock: { object in
            if let page = object as? Core.Page {
                let dictionary: [String: Any] = [
                    "url": page.url,
                    "lastUpdated": page.lastUpdated?.timeIntervalSince1970 ?? 0,
                    "isFrontPage": page.isFrontPage,
                    "id": page.id,
                    "title": page.title,
                    "htmlURL": page.htmlURL?.absoluteString ?? "",
                    "published": page.published,
                    "body": page.body,
                    "editingRoles": page.editingRoles,
                    "contextID": page.contextID
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return OfflineStorageDataModel(id: page.id, type: String(describing: type(of: page)), json: jsonString)
                }
            }
            return OfflineStorageDataModel(id: "", type: "", json: "")
        }
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
