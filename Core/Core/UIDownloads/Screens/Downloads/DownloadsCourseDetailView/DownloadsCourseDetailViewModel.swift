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
    var detailViewModels: [DownloadsCourseDetailsViewModel] = []

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
                let pages: [Page] = entries.compactMap {
                    guard let page = try? Page.fromOfflineModel($0.dataModel),
                            page.contextID.digits == self.courseViewModel.courseId else {
                        return nil
                    }
                    return page
                }
                let modules: [ModuleItem] = entries.compactMap {
                    guard let moduleItem = try? ModuleItem.fromOfflineModel($0.dataModel),
                          moduleItem.courseID == self.courseViewModel.courseId else {
                        return nil
                    }
                    return moduleItem
                }
                if !pages.isEmpty {
                    self.detailViewModels.append(
                        DownloadsCourseDetailsViewModel(
                            course: course,
                            contentType: .pages(Array(pages))
                        )
                    )
                }
                if !modules.isEmpty {
                    self.detailViewModels.append(
                        DownloadsCourseDetailsViewModel(
                            course: course,
                            contentType: .modules(Array(modules))
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

extension String {
    var digits: String {
        components(
            separatedBy: CharacterSet.decimalDigits.inverted
        )
        .joined()
    }
}
