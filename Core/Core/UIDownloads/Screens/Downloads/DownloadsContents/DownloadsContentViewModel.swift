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
import SwiftUI

final class DownloadsContentViewModel: ObservableObject {

    // MARK: - Injections -

    private var storageManager: OfflineStorageManager = .shared
    private var downloadsManager: OfflineDownloadsManager = .shared

    // MARK: - Properties -

    @Published var content: [OfflineDownloaderEntry]
    let courseDataModel: CourseStorageDataModel
    var onDeleted: ((OfflineDownloaderEntry) -> Void)?
    var onDeletedAll: (() -> Void)?

    var color: UIColor {
        UIColor(hexString: courseDataModel.course.courseColor) ?? .oxford
    }

    init(
        content: [OfflineDownloaderEntry],
        courseDataModel: CourseStorageDataModel,
        onDeleted: ((OfflineDownloaderEntry) -> Void)? = nil,
        onDeletedAll: (() -> Void)? = nil
    ) {
        self.content = content
        self.courseDataModel = courseDataModel
        self.onDeleted = onDeleted
        self.onDeletedAll = onDeletedAll
    }

    func deleteAll() {
        content.forEach {
            try? self.downloadsManager.delete(entry: $0)
            storageManager.delete($0) {_ in}
        }
        onDeletedAll?()
    }

    func swipeDelete(indexSet: IndexSet) {
        indexSet.forEach { index in
            let entry = content[index]
            delete(entry: entry)
        }
    }

    func delete(entry: OfflineDownloaderEntry) {
        content.removeAll(where: {$0.dataModel.id  == entry.dataModel.id})
        try? downloadsManager.delete(entry: entry)
        storageManager.delete(entry) { _ in}
        onDeleted?(entry)
    }
}
