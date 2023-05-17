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

import SwiftSoup

class OfflineDownloaderLink {
    let link: String
    let tag: String?
    let attribute: String?
    var extractedLink: String?
    var downloadedLink: String?

    var isWebLink: Bool {
        tag != nil && tag?.isEmpty == false
    }

    var isCssLink: Bool {
        tag?.lowercased() == "link"
    }

    var isIframe: Bool {
        tag?.lowercased() == "iframe"
    }

    var isVideo: Bool {
        tag?.lowercased() == "video"
    }

    var isAudio: Bool {
        tag?.lowercased() == "audio"
    }

    var isImage: Bool {
        tag?.lowercased() == "img"
    }

    var isSource: Bool {
        tag?.lowercased() == "source"
    }

    var isDownloaded: Bool {
        downloadedLink != nil
    }

    init(link: String, tag: String?, attribute: String?) {
        self.link = link
        self.tag = tag
        self.attribute = attribute
    }
}
