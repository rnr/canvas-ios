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

public class OfflineStorageManager {
    public static let shared: OfflineStorageManager = .init()
    private var config: OfflineStorageConfig = OfflineStorageConfig()

    public func setConfig(config: OfflineStorageConfig) {
        self.config = config
    }

    func save<T>(_ object: T) {
        guard let helper = helper(for: object) else { return }
        let data = helper.toOfflineModel()
        // TODO: Save to database
    }

    func load<T>(for id: String, castingType: T.Type) -> T? {
        let typeString = String(describing: castingType)
        // TODO: get data from database for id and typeString
        let data = OfflineStorageDataModel(id: "testId", type: typeString, json: "{}")
        return object(from: data, for: castingType)
    }

    func loadAll<T>(of type: T.Type) -> [T] {
        let typeString = String(describing: type)
        // TODO: load all entries for type = typeString
        return []
    }

    func dataModel<T>(for object: T) -> OfflineStorageDataModel? {
        helper(for: object)?.toOfflineModel()
    }

    public func object<T>(from data: OfflineStorageDataModel, for type: T.Type) -> T? {
        guard let helper = helper(for: type) else { return nil }
        return helper.fromOfflineModel(data) as? T
    }

    func helper<T>(for object: T) -> (any OfflineStorageDataProtocol)? {
        helper(for: type(of: object))
    }

    func helper<T>(for type: T.Type) -> (any OfflineStorageDataProtocol)? {
        config.helpers.first(where: {$0.offlineType == type})
    }
}
