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

struct OfflineHTMLLinksExtractor: OfflineLinksExtractorProtocol, OfflineHTMLLinksExtractorProtocol {

    var html: String
    var baseURL: String

    func links() async throws -> [OfflineDownloaderLink] {
        /*
        if Task.isCancelled { throw URLError(.cancelled) }
        do {
            let doc: Document = try SwiftSoup.parse(html)
            var links: [HTMLLink] = []
            for tag in sourceTags {
                let tagLinks = try linksForTag(tag, in: doc)
                links.append(contentsOf: tagLinks)
            }
            return HTMLLinksStorage(links: links)
        } catch {
            throw HTMLLinksExtractorError.soupError(error: error)
        }
         */
        return []
    }
/*
    private func linksForTag(_ name: String, in doc: Document) throws -> [HTMLLink] {
        var links: [HTMLLink] = []
        let tags = try doc.getElementsByTag(name)
        for tag in tags {
            for attr in sourceAttributes {
                if let link = try? tag.attr(attr),
                    !link.isEmpty,
                    canLoad(link: link, for: name) {
                    let htmlLink = HTMLLink(
                        document: doc,
                        element: tag,
                        attribute: attr,
                        link: link.fixLink(with: baseURL)
                    )
                    links.append(htmlLink)
                }
            }

            // get youtube or vimeo link
            if name.lowercased() == "video" {
                let attr = "data-setup"
                if let jsonString = try? tag.attr(attr),
                    let jsonData = jsonString.data(using: .utf8),
                    let pluginObject = try? JSONDecoder().decode(
                        HTMLVideoVimeoAndYoutubePluginObject.self,
                        from: jsonData
                    ),
                    let source = pluginObject.sources.first {
                    let link = source.src
                    let htmlLink = HTMLLink(
                        document: doc,
                        element: tag,
                        attribute: attr,
                        link: link.fixLink(with: baseURL)
                    )
                    links.append(htmlLink)
                }
            }
        }
        return links
    }

    private func canLoad(link: String, for tagName: String) -> Bool {
        if link.range(of: "data:(.*?)base64", options: .regularExpression) != nil {
            return false
        }

        if tagName.lowercased() == "a" {
            if let url = URL(string: link) {
                let fileName = url.path.lowercased()
                let fileExtension = fileName.components(separatedBy: ".").last ?? fileName
                return documentExtensions.contains(fileExtension)
            } else {
                return false
            }
        }

        return true
    }
    */
}
/*
extension HTMLLinksExtractor {
    enum HTMLLinksExtractorError: Error, LocalizedError {
        case soupError(error: Error)

        var errorDescription: String? {
            switch self {
            case .soupError(error: let error):
                return "HTMLLinksExtractor got an error: \(error)"
            }
        }
    }
}
*/
