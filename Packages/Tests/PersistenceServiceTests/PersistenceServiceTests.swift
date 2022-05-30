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

    func testSaveTodo() throws {
        let request = Todo.fetchRequest()
        let context = persistenceService.container.viewContext

        let initialCount = try context.count(for: request)
        XCTAssertEqual(initialCount, 0)

        persistenceService.saveTodo(
            id: 1,
            title: "Something todo",
            userId: 1,
            completed: false
        )

        let finalCount = try context.count(for: request)

        XCTAssertEqual(finalCount, 1)
    }

    func testSaveUser() throws {
        let request = User.fetchRequest()
        let context = persistenceService.container.viewContext

        let initialCount = try context.count(for: request)
        XCTAssertEqual(initialCount, 0)

        persistenceService.saveUser(
            id: 1,
            name: "name",
            username: "username",
            email: "email@email.com"
        )

        let finalCount = try context.count(for: request)

        XCTAssertEqual(finalCount, 1)
    }

    func testDeleteUser() throws {
        let request = User.fetchRequest()
        let context = persistenceService.container.viewContext

        persistenceService.saveUser(
            id: 1,
            name: "name",
            username: "username",
            email: "email@email.com"
        )

        let countBeforeDelete = try context.count(for: request)
        XCTAssertEqual(countBeforeDelete, 1)

        let user = try context.fetch(request).first!
        persistenceService.deleteUser(user: user)

        let countAfterDelete = try context.count(for: request)
        XCTAssertEqual(countAfterDelete, 0)
    }
}
