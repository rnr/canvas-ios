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

import mobile_offline_downloader_ios

final public class PageEntity: Hashable {

    public static func == (lhs: PageEntity, rhs: PageEntity) -> Bool {
        lhs.id == rhs.id
    }

    public var id: String
    public var title: String
    public var contextId: String
    public var pageId: String
    public var courseId: String
    public var htmlURL: String
    public var lastUpdated: Date?

    public init(
        title: String,
        contextId: String,
        pageId: String,
        courseId: String,
        htmlURL: String,
        lastUpdated: Date?
    ) {
        self.id = pageId
        self.pageId = pageId
        self.title = title
        self.contextId = contextId
        self.pageId = pageId
        self.courseId = courseId
        self.htmlURL = htmlURL
        self.lastUpdated = lastUpdated        
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
