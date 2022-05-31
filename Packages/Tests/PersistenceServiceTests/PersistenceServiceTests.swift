//
//  PersistenceServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 29/05/2022.
//

import XCTest
@testable import PersistenceService

final class PersistenceServiceTests: XCTestCase {

    private var persistenceService: PersistenceService!

    override func setUpWithError() throws {
        persistenceService = PersistenceService(storeType: .inMemory)
    }

    override func tearDown() {
        persistenceService = nil
    }

    func testSave() throws {
        let request = User.fetchRequest()
        let context = persistenceService.container.viewContext

        let initialCount = try context.count(for: request)
        XCTAssertEqual(initialCount, 0)

        persistenceService.save(User.self, context: context) { user in
            user.id = 1
            user.name = "name"
            user.username = "username"
            user.email = "email@email.com"
        }

        let finalCount = try context.count(for: request)

        XCTAssertEqual(finalCount, 1)
    }

    func testDelete() throws {
        let request = User.fetchRequest()
        let context = persistenceService.container.viewContext

        persistenceService.save(User.self, context: context) { user in
            user.id = 1
            user.name = "name"
            user.username = "username"
            user.email = "email@email.com"
        }

        let countBeforeDelete = try context.count(for: request)
        XCTAssertEqual(countBeforeDelete, 1)

        let user = try context.fetch(request).first!
        persistenceService.delete(entity: user, context: context)

        let countAfterDelete = try context.count(for: request)
        XCTAssertEqual(countAfterDelete, 0)
    }
}
