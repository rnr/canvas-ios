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
    private var cancellables: [AnyCancellable] = []

    enum State {
        case none // init
        case loading
        case loaded
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
        let group = DispatchGroup()
        courseViewModels.forEach { viewModel in
            storageManager.delete(viewModel.courseDataModel) { _ in }
            group.enter()
            storageManager.loadAll(of: OfflineDownloaderEntry.self) { [weak self] result in
                guard let self = self else {
                    group.leave()
                    return
                }
                result.success { entries in
                    let items = DownloadsHelper.filter(courseId: viewModel.courseId, entries: entries)
                    items.forEach {
                        try? self.downloadsManager.delete(entry: $0)
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.storageManager.deleteAll { [weak self] _ in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    self.modules = []
                    self.courseViewModels = []
                    self.state = .loaded
                }
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
            storageManager.loadAll(of: OfflineDownloaderEntry.self) { [weak self] result in
                guard let self = self else {
                    return
                }
                result.success { entries in
                    let items = DownloadsHelper.filter(courseId: viewModel.courseId, entries: entries)
                    items.forEach {
                        try? self.downloadsManager.delete(entry: $0)
                        self.storageManager.delete($0) {_ in}
                    }
                }
            }
        }
        state = .loaded
    }

    // MARK: - Private methods -

    func fetch() {
        state = .loading
        storageManager.loadAll(of: CourseStorageDataModel.self) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { courses in
                self.courseViewModels = courses.compactMap { courseDataModel in
                    if courseDataModel.entriesIds.isEmpty {
                        return nil
                    }
                    return DownloadCourseViewModel(
                        courseDataModel: courseDataModel
                    )
                }
            }
            self.state = .loaded
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
