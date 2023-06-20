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

extension OfflineStorageManager {
    func addOrUpdateCourse(course: Course, deleting: Bool, downloadedId: String) {
        loadAll(of: CourseStorageDataModel.self) { [weak self] result in
            result.success { courses in
                if let courseStorageDataModel = courses.first(where: { $0.course.id == course.id }) {
                    if deleting {
                        courseStorageDataModel.entriesIds.removeAll(where: { $0 == downloadedId })
                    } else {
                        if !courseStorageDataModel.entriesIds.contains(downloadedId) {
                            courseStorageDataModel.entriesIds.append(downloadedId)
                        }
                    }
                    print(courseStorageDataModel.entriesIds, "courseStorageDataModel.entriesIds")
                    self?.save(courseStorageDataModel) { _ in }
                } else {
                    let courseStorageDataModel = CourseStorageDataModel(
                        course: course,
                        entriesIds: [downloadedId]
                    )
                    self?.save(courseStorageDataModel) { _ in }
                }
            }
        }
    }
}
