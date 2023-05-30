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

final class DownloadsCourseDetailsViewModel: Identifiable, Hashable {
    static func == (lhs: DownloadsCourseDetailsViewModel, rhs: DownloadsCourseDetailsViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String = Foundation.UUID().uuidString

    enum ContentType {
        case pages([Page])
        case modules([ModuleItem])
    }
    let contentType: ContentType

    let course: Course

    var courseColor: UIColor {
        course.color
    }

    var title: String {
        switch contentType {
        case .pages:
            return "Pages"
        case .modules:
            return "Modules"
        }
    }

    init(course: Course, contentType: ContentType) {
        self.contentType = contentType
        self.course = course
    }
}
