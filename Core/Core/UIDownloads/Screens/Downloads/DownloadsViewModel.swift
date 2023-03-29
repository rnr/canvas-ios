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

final class DownloadsCourseDetailsViewModel: Identifiable, Hashable {
    static func == (lhs: DownloadsCourseDetailsViewModel, rhs: DownloadsCourseDetailsViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String = Foundation.UUID().uuidString
    let title: String

    init(title: String) {
        self.title = title
    }
}

final class DownloadCourseViewModel: Identifiable, Hashable {
    static func == (lhs: DownloadCourseViewModel, rhs: DownloadCourseViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String = Foundation.UUID().uuidString
    let shortName: String
    let courseCode: String

    init(shortName: String, courseCode: String) {
        self.shortName = shortName
        self.courseCode = courseCode
    }
}

final class DownloadingModule: Identifiable, Hashable {
    static func == (lhs: DownloadingModule, rhs: DownloadingModule) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String = Foundation.UUID().uuidString
    let shortName: String

    init(shortName: String) {
       self.shortName = shortName
   }
}

final class DownloadsViewModel: ObservableObject {

    // MARK: - Injections -

    @Injected(\.storage) var storage: LocalStorage

    // MARK: - Content -

    private(set) var courses: [DownloadCourseViewModel] = []
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
        modules = []
        courses = []
        state = .loaded
    }

    func swipeDeleteDownloading(indexSet: IndexSet) {
        indexSet.forEach { index in
            modules.remove(at: index)
        }
    }

    func swipeDelete(indexSet: IndexSet) {
        indexSet.forEach { index in
            courses.remove(at: index)
        }
    }

    // MARK: - Private methods -

    func fetch() {
        storage.objects(CourseEntity.self) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let results):
                self.courses = results.compactMap { courseEntity in
                    DownloadCourseViewModel(
                        shortName: courseEntity.name,
                        courseCode: courseEntity.courseCode
                    )
                }
                DispatchQueue.main.async {
                    self.state = .loaded
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    private func setIsEmpty() {
        switch state {
        case .loaded:
            if !isConnected && courses.isEmpty {
                isEmpty = true
            } else {
                isEmpty = modules.isEmpty && courses.isEmpty
            }
        default:
            break
        }
    }
}
