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

import RealmSwift
import mobile_offline_downloader_ios

final public class PageEntity: StoreObject, Storable {

    @Persisted public var title: String
    @Persisted public var contextId: String
    @Persisted public var pageId: String
    @Persisted public var courseId: String
    @Persisted public var htmlURL: String
    @Persisted public var lastUpdated: Date?

    public convenience init(
        title: String,
        contextId: String,
        pageId: String,
        courseId: String,
        htmlURL: String,
        lastUpdated: Date?
    ) {
        self.init()
        self.id = pageId
        self.title = title
        self.contextId = contextId
        self.pageId = pageId
        self.courseId = courseId
        self.htmlURL = htmlURL
        self.lastUpdated = lastUpdated
    }
}
