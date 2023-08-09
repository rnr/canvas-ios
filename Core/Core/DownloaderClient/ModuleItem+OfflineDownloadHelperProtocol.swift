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
import SwiftSoup

extension ModuleItem: OfflineDownloadTypeProtocol {
    public static func canDownload(entry: OfflineDownloaderEntry) -> Bool {
        guard let item = try? fromOfflineModel(entry.dataModel) else { return false }
        if case .externalTool = item.type {
            return true
        }
        if case .page = item.type {
            return true
        }
        if case .file = item.type {
            return true
        }
        return false
    }

    public static func getItem(with dataModel: OfflineStorageDataModel) async throws -> ModuleItem {
        try await withCheckedThrowingContinuation({ continuation in
            DispatchQueue.main.async {
                do {
                    let item = try fromOfflineModel(dataModel)
                    continuation.resume(returning: item)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
    }

    public static func prepareForDownload(entry: OfflineDownloaderEntry) async throws {
        let item = try await getItem(with: entry.dataModel)
        if case let .externalTool(toolID, url) = item.type {
            try await prepareLTI(entry: entry, toolID: toolID, url: url)
        } else if case let .page(url) = item.type {
            try await preparePage(entry: entry, url: url, courseID: item.courseID)
        } else if case let .file(fileId) = item.type {
            try await prepareFile(entry: entry, item: item, fileId: fileId)
        }
    }

    static func preparePage(entry: OfflineDownloaderEntry, url: String, courseID: String) async throws {
        let context = Context(.course, id: courseID)
        try await withCheckedThrowingContinuation({[weak entry] continuation in
            var pages: Store<GetPage>?

            pages = AppEnvironment.shared.subscribe(GetPage(context: context, url: url)) {}

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
        })
    }

    public static func prepareFile(entry: OfflineDownloaderEntry, item: ModuleItem, fileId: String) async throws {
        guard let url = item.url, let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw ModuleItemError.unsupported
        }

        let fileID = urlComponents.queryItems?.first(where: { $0.name == "preview" })?.value ?? fileId

        var context = Context(path: url.path)
        if let courseID = urlComponents.queryItems?.first(where: { $0.name == "courseID" })?.value {
            context = Context(.course, id: courseID)
        }

        return try await withCheckedThrowingContinuation({[weak entry] continuation in
            let files: Store<GetFile> = AppEnvironment.shared.subscribe(GetFile(context: context, fileID: fileID)) {}
            files.refresh(force: true, callback: {[entry] file in
                if let url = file?.url?.rawValue {
                    entry?.parts.removeAll()
                    entry?.addURLPart(url.absoluteString)
                }
                continuation.resume()
            })
        })
    }

    static func getLtiURL(from item: ModuleItem, toolID: String, url: URL) async throws -> URL {
        let tools = LTITools(
            context: .course(item.courseID),
            id: toolID,
            url: url,
            launchType: .module_item,
            moduleID: item.moduleID,
            moduleItemID: item.id
        )

        return try await withCheckedThrowingContinuation { continuation in
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
    }

    static func prepareLTI(entry: OfflineDownloaderEntry, toolID: String, url: URL) async throws {
        let item = try fromOfflineModel(entry.dataModel)

        let url: URL = try await getLtiURL(from: item, toolID: toolID, url: url)

        let extractor = await OfflineHTMLDynamicsLinksExtractor(
            url: url,
            linksHandler: OfflineDownloadsManager.shared.config.linksHandler
        )
        try await extractor.fetch()
        if let latestURL = await extractor.latestRedirectURL, let html = await extractor.html {
            if html.contains(latestURL.absoluteString) {
                let downloader = OfflineLinkDownloader()
                let cookieString = await extractor.cookies().cookieString
                downloader.additionCookies = cookieString
                let ltiContents = try await downloader.contents(urlString: latestURL.absoluteString)
                entry.addHtmlPart(ltiContents, baseURL: latestURL.absoluteString, cookieString: cookieString)
            } else {
                let html = try prepare(html: html)
                let cookieString = await extractor.cookies().cookieString
                entry.addHtmlPart(html, baseURL: latestURL.absoluteString, cookieString: cookieString)
            }
        }
    }

    static func prepare(html: String) throws -> String {
        let document = try SwiftSoup.parse(html)
        let videoTags = try document.getElementsByTag("video")
        for tag in videoTags where tag.hasClass("vjs-tech") {
            try tag.attr("controls", "true")
            try tag.attr("width", "100%")
            try tag.removeAttr("crossorigin")
            if let app = try document.getElementById("app") {
                try app.replaceWith(tag)
            }
        }
        return try document.html()
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
