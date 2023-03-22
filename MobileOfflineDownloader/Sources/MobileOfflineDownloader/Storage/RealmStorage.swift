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

final class RealmStorage: LocalStorage {

    static let `default`: RealmStorage = RealmStorage()

    private init() {
        configure()
    }

    let dataBaseQueue: RealmDatabaseQueue = .init()
    lazy var dataBaseThread: RealmDatabaseThread = RealmDatabaseThread().apply {
        $0.workingQueue = { [unowned self] key in
            self.dataBaseQueue.get(by: key)
        }
    }
    var realm: Realm? {
        try? dataBaseThread.getInstance()
    }
    private var config: Realm.Configuration = .defaultConfiguration

    func addOrUpdate<T>(
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) where T: Storable {
        dataBaseQueue.background.async { [weak self] in
            guard let realm = self?.realm else {
                completionHandler(.failure(RealmError.error))
                return
            }
            do {
                try realm.write {
                    realm.add(value)
                    completionHandler(.success(()))
                }
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    func addOrUpdate<T>(
        values: [T],
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) where T: Storable {
        dataBaseQueue.background.async { [weak self] in
            guard let self = self else {
                completionHandler(.failure(RealmError.error))
                return
            }
            let group = DispatchGroup()
            values.forEach {
                group.enter()
                self.addOrUpdate(
                    value: $0
                ) { _ in
                    group.leave()
                }
            }
            group.notify(queue: self.dataBaseQueue.background) {
                completionHandler(.success(()))
            }
        }
    }

    func objects<T>(
        _ type: T.Type,
        completionHandler: @escaping ([T]) -> Void
    ) where T: Storable {
        dataBaseQueue.background.async { [weak self] in
            guard let realm = self?.realm else {
                completionHandler([])
                return
            }
            let objects = realm.objects(type)
            completionHandler(Array(objects))
        }
    }

    func object<T, KeyType>(
        _ type: T.Type,
        forPrimaryKey key: KeyType,
        completionHandler: @escaping (T?) -> Void
    ) where T: Storable {
        dataBaseQueue.background.async { [weak self] in
            guard let realm = self?.realm else {
                completionHandler(nil)
                return
            }

            let object = realm.object(ofType: type, forPrimaryKey: key)
            completionHandler(object)

        }
    }

    func delete<T>(
        value: T,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) where T: Storable {
        dataBaseQueue.background.async { [weak self] in
            guard let realm = self?.realm else {
                completionHandler(.failure(RealmError.error))
                return
            }
            do {
                try realm.write {
                    realm.delete(value)
                    completionHandler(.success(()))
                }
            } catch {
                print(error.localizedDescription)
                completionHandler(.failure(error))
            }
        }
    }

    func delete<T>(
        values: [T],
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) where T: Storable {
        dataBaseQueue.background.async { [weak self] in
            guard let self = self else {
                completionHandler(.failure(RealmError.error))
                return
            }
            let group = DispatchGroup()
            values.forEach {
                group.enter()
                self.delete(
                    value: $0
                ) { _ in
                    group.leave()
                }
            }
            group.notify(queue: self.dataBaseQueue.background) {
                completionHandler(.success(()))
            }
        }
    }

    func deleteAll(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        dataBaseQueue.background.async { [weak self] in
            guard let self = self else {
                completionHandler(.failure(RealmError.error))
                return
            }
            do {
                try self.realm?.write {
                    self.realm?.deleteAll()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func configure() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { _, _ in },
            deleteRealmIfMigrationNeeded: true
        )
        self.config = config
    }
}
