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

final class DownloadsCourseDetailViewModel: ObservableObject {

    // MARK: - Injections -

    private var storageManager: OfflineStorageManager = .shared
    private var downloadsManager: OfflineDownloadsManager = .shared

    // MARK: - Properties -

    enum State {
        case none // init
        case loading
        case loaded
    }

    @Published var state: State = .none

    // MARK: - Content -

    let courseViewModel: DownloadCourseViewModel
    var categories: [DownloadsCourseCategoryViewModel] = []

    var title: String {
        courseViewModel.courseCode
    }

    // MARK: - Lifecycle -

    init(courseViewModel: DownloadCourseViewModel) {
        self.courseViewModel = courseViewModel
    }

    // MARK: - Intents -

    func fetch() {
        let course = courseViewModel.courseDataModel.course
        storageManager.loadAll(of: OfflineDownloaderEntry.self) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { entries in
                let courseEntries = DownloadsHelper.filter(
                    courseId: self.courseViewModel.id,
                    entries: entries
                )
                let pagesSection = DownloadsHelper.pages(
                    courseId: self.courseViewModel.id,
                    entries: courseEntries
                )
                let modulesSection = DownloadsHelper.moduleItems(
                    courseId: self.courseViewModel.id,
                    entries: courseEntries
                )
                if !pagesSection.isEmpty {
                    self.categories.append(
                        DownloadsCourseCategoryViewModel(
                            course: course,
                            content: pagesSection,
                            contentType: .pages
                        )
                    )

                }
                if !modulesSection.isEmpty {
                    self.categories.append(
                        DownloadsCourseCategoryViewModel(
                            course: course,
                            content: modulesSection,
                            contentType: .modules
                        )
                    )
                }
            }
            DispatchQueue.main.async {
                self.state = .loaded
            }
        }
    }
}
