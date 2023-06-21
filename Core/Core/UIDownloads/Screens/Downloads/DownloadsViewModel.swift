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

import Combine
import SwiftUI
import mobile_offline_downloader_ios

final class DownloadsViewModel: ObservableObject {

    // MARK: - Injections -

    private var storageManager: OfflineStorageManager = .shared
    private var downloadsManager: OfflineDownloadsManager = .shared

    // MARK: - Content -

    private(set) var courseViewModels: [DownloadCourseViewModel] = []
    private(set) var categories: [String: [DownloadsCourseCategoryViewModel]] = [:]
    private var cancellables: [AnyCancellable] = []

    enum State {
        case none // init
        case loading
        case loaded
        case updated
    }

    @Published var state: State = .none {
        didSet {
            setIsEmpty()
        }
    }

    @Published var isConnected: Bool = true {
        didSet {
            setIsEmpty()
        }
    }

    @Published var modules: [DownloadingModule] = [] {
        didSet {
            setIsEmpty()
        }
    }
    @Published var isEmpty: Bool = false

    init() {
        fetch()
    }

    // MARK: - Intents -

    func pauseResume() {}

    func deleteAll() {
        courseViewModels.forEach { viewModel in
            storageManager.delete(viewModel.courseDataModel) { _ in }
            let models = categories.removeValue(forKey: viewModel.courseId)
            models
                .flatMap { $0.flatMap { $0.content } }?
                .forEach {
                try? self.downloadsManager.delete(entry: $0)
            }
        }
       storageManager.deleteAll { [weak self] _ in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.modules = []
                self.courseViewModels = []
                self.state = .updated
            }
        }
    }

    func swipeDeleteDownloading(indexSet: IndexSet) {
        indexSet.forEach { index in
            modules.remove(at: index)
        }
    }

    func swipeDelete(indexSet: IndexSet) {
        indexSet.forEach { index in
            let viewModel = courseViewModels.remove(at: index)
            storageManager.delete(viewModel.courseDataModel) { _ in }
            let models = categories.removeValue(forKey: viewModel.courseId)
            models
                .flatMap { $0.flatMap { $0.content } }?
                .forEach {
                try? downloadsManager.delete(entry: $0)
                storageManager.delete($0) {_ in}
            }
        }
        state = .loaded
    }

    func fetch() {
        state = .loading
        storageManager.loadAll(of: CourseStorageDataModel.self) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { courses in
                let dispatchGroup = DispatchGroup()
                courses.forEach { courseStorageDataModel in
                    dispatchGroup.enter()
                    self.fetchEntries(courseDataModel: courseStorageDataModel) {
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    self.state = .loaded
                }
            }
            result.failure { _ in
                self.state = .loaded
            }
        }
    }

    func categories(courseId: String) -> [DownloadsCourseCategoryViewModel] {
        categories[courseId] ?? []
    }

    func delete(courseViewModel: DownloadCourseViewModel) {
        categories.removeValue(forKey: courseViewModel.courseId)
        courseViewModels.removeAll(where: {$0.courseId == courseViewModel.courseId})
        setIsEmpty()
    }

    // MARK: - Private methods -

    private func fetchEntries(courseDataModel: CourseStorageDataModel, completion: @escaping () -> Void) {
        storageManager.loadAll(of: OfflineDownloaderEntry.self) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { entries in
                let courseEntries = DownloadsHelper.filter(
                    courseId: courseDataModel.course.id,
                    entries: entries
                )
                let pagesSection = DownloadsHelper.pages(
                    courseId: courseDataModel.course.id,
                    entries: courseEntries
                )
                let modulesSection = DownloadsHelper.moduleItems(
                    courseId: courseDataModel.course.id,
                    entries: courseEntries
                )
                var categories: [DownloadsCourseCategoryViewModel] = []
                if !pagesSection.isEmpty {
                    categories.append(
                        DownloadsCourseCategoryViewModel(
                            course: courseDataModel.course,
                            content: pagesSection,
                            contentType: .pages
                        )
                    )
                }
                if !modulesSection.isEmpty {
                    categories.append(
                        DownloadsCourseCategoryViewModel(
                            course: courseDataModel.course,
                            content: modulesSection,
                            contentType: .modules
                        )
                    )
                }

                if !categories.isEmpty {
                    self.categories[courseDataModel.course.id] = categories
                    self.courseViewModels.append(
                        DownloadCourseViewModel(
                            courseDataModel: courseDataModel
                        )
                    )
                }
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    private func setIsEmpty() {
        switch state {
        case .loaded:
            if !isConnected && courseViewModels.isEmpty {
                isEmpty = true
            } else {
                isEmpty = modules.isEmpty && courseViewModels.isEmpty
            }
        default:
            break
        }
    }
}
