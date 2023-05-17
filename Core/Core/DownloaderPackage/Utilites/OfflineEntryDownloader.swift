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
class OfflineEntryDownloader {
    var config: OfflineDownloaderConfig
    var entry: OfflineDownloaderEntry
    private var task: Task<(), Never>?

    init(entry: OfflineDownloaderEntry, config: OfflineDownloaderConfig) {
        self.entry = entry
        self.config = config
    }

    func start() {
        task = Task {
            do {
                await prepare()
                for part in entry.parts {
                    switch part.value {
                    case let .html(html, baseURL):
                        if part.links.isEmpty {
                            let links = try await OfflineHTMLLinksExtractor(html: html, baseURL: baseURL ?? "").links()
                            part.append(links: links)
                        }
                        
                        for link in part.links where !link.isDownloaded {
                            
                        }
                        print(html)
                    case let.url(url):
                        print(url)
                    }
                }
            } catch {
                print("error = \(error)")
            }
        }
    }

    func download(link: OfflineDownloaderLink, to path: String) async throws {
        if link.isCssLink {
            // Create CSSLoader and wait while it will finish
        } else if link.isVideo {
            // Extract links if need
        } else if link.isIframe {
            // Extract link if need
        } else {

        }
    }

    private func prepare() async {
        await withCheckedContinuation {[weak self] continuation in
            guard let self = self else {
                continuation.resume()
                return
            }
            self.config.preparationBlock?(self.entry) {
                continuation.resume()
            }
        }
    }

    func cancel() {
        task?.cancel()
    }
}
