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

final public class CourseEntity {

    public var courseId: String
    public var name: String
    public var courseCode: String
    public var termName: String
    public var courseColor: String
    public var imageDownloadURL: String

    init(
        courseId: String,
        name: String?,
        courseCode: String?,
        termName: String?,
        courseColor: String?,
        imageDownloadURL: String?
    ) {
        self.courseId = courseId
        self.name = name ?? ""
        self.courseCode = courseCode ?? ""
        self.termName = termName ?? ""
        self.courseColor = courseColor ?? ""
        self.imageDownloadURL = imageDownloadURL ?? ""
    }
}

public extension CourseEntity {
    var color: UIColor {
        if AppEnvironment.shared.k5.isK5Enabled {
            return UIColor(hexString: courseColor)?.ensureContrast() ?? .oxford
        } else {
            return .ash
        }
    }
}
