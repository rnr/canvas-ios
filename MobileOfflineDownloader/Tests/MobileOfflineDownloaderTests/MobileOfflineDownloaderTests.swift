import XCTest
@testable import MobileOfflineDownloader
import RealmSwift

final class Person: StoreObject, Storable {
    @Persisted var name: String

    convenience init(name: String) {
        self.init()
        self.name = name
    }
}


final class MobileOfflineDownloaderTests: XCTestCase {

    @Injected(\.storage) private var storage: LocalStorage

    func testExample() throws {
        let person = Person(name: "Test")
        person.addOrUpdate(in: .current) { result in
            Person.all(in: .current) { result in
                print(result)
            }
        }

        storage.addOrUpdate(value: person) { [weak self] result in
            self?.storage.objects(Person.self) { result in
                print(result)
            }
        }
    }

}
