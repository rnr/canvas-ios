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
import Foundation

public struct StorageProvider {
    static public var current: LocalStorage = RealmStorage.default
}

class StoreObject: Object {}

public protocol Storable: Object, RealmFetchable {
    static func all(
        in storage: LocalStorage,
        completionHandler: @escaping ([Self]) -> Void
    )

    static func object<KeyType>(
        in storage: LocalStorage,
        forPrimaryKey key: KeyType,
        completionHandler: @escaping (_ value: Self?) -> Void
    )

    func addOrUpdate<T: Storable>(
        in storage: LocalStorage,
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )

    func delete<T: Storable>(
        in storage: LocalStorage,
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )
}

extension Storable {
    func store(in storage: LocalStorage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            storage.addOrUpdate(value: self) { result in
                continuation.resume(with: result)
            }
        }
    }

    func delete(from storage: LocalStorage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            storage.delete(value: self) { result in
                continuation.resume(with: result)
            }
        }
    }

    public static func all(
        in storage: LocalStorage,
        completionHandler: @escaping ([Self]) -> Void
    ) {
        storage.objects(Self.self, completionHandler: completionHandler)
    }

    public static func object<KeyType>(
        in storage: LocalStorage,
        forPrimaryKey key: KeyType,
        completionHandler: @escaping (_ value: Self?) -> Void
    ) {
        storage.object(Self.self, forPrimaryKey: key, completionHandler: completionHandler)
    }

    public func addOrUpdate<T: Storable>(
        in storage: LocalStorage,
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        storage.addOrUpdate(value: value, completionHandler: completionHandler)
    }

    public func delete<T: Storable>(
        in storage: LocalStorage,
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        storage.delete(value: self, completionHandler: completionHandler)
    }
}

public protocol LocalStorage {
    func objects<T: Storable>(
        _ type: T.Type,
        completionHandler: @escaping ([T]) -> Void
    )
    func object<T: Storable, KeyType>(
        _ type: T.Type,
        forPrimaryKey key: KeyType,
        completionHandler: @escaping (_ value: T?) -> Void
    )
    func addOrUpdate<T: Storable>(
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )
    func addOrUpdate<T: Storable>(
        values: [T],
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )
    func delete<T: Storable>(
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )
    func delete<T: Storable>(
        values: [T],
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )
    func deleteAll(
        completionHandler: @escaping (Result<Void, Error>) -> Void
    )
}
