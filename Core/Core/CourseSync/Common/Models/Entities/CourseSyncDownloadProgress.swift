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
import CoreData

public final class CourseSyncDownloadProgress: NSManagedObject {
    @NSManaged public var bytesToDownload: Int
    @NSManaged public var bytesDownloaded: Int
    @NSManaged public var isFinished: Bool
    @NSManaged public var error: String?

    var progress: Float {
        Float(bytesDownloaded) / Float(bytesToDownload)
    }
}

public extension CourseSyncDownloadProgress {
    @discardableResult
    static func save(
        bytesToDownload: Int,
        bytesDownloaded: Int,
        isFinished: Bool,
        error: String?,
        in context: NSManagedObjectContext
    ) -> CourseSyncDownloadProgress {
        let model: CourseSyncDownloadProgress = context.first(scope: .all) ?? context.insert()
        model.bytesToDownload = bytesToDownload
        model.bytesDownloaded = bytesDownloaded
        model.isFinished = isFinished
        model.error = error
        return model
    }
}
