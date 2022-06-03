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

    func testSave() async throws {
        let todoRequest = TodoEntity.fetchRequest()
        let viewContext = persistenceService.container.viewContext
        let todoInitialCount = try viewContext.count(for: todoRequest)

        XCTAssertEqual(todoInitialCount, 0)

        await viewContext.perform {
            _ = viewContext.save(TodoEntity.self) { todo in
                todo.id = 1
                todo.title = "A title"
                todo.completed = false
                todo.userId = 1
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }
        }

        let todoFinalCount = try viewContext.count(for: todoRequest)
        XCTAssertEqual(todoFinalCount, 1)
    }

    func testSaveWithRelationShips() async throws {
        let todoRequest = TodoEntity.fetchRequest()
        let userRequest = UserEntity.fetchRequest()
        let viewContext = persistenceService.container.viewContext

        await viewContext.perform {
            let todo = viewContext.save(TodoEntity.self) { todo in
                todo.id = 1
                todo.title = "A title"
                todo.completed = false
                todo.userId = 1
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }
            guard let todo = todo else { return }

            viewContext.save(UserEntity.self) { user in
                user.id = 1
                user.name = "Dino"
                user.email = "test@email.com"
                user.username = "cuperdino"
                user.addToTodos(todo)
            }
        }

        let todo = try viewContext.fetch(todoRequest).first!
        let user = try viewContext.fetch(userRequest).first!
        let userTodo = user.todos?.allObjects.first as? TodoEntity

        XCTAssertEqual(todo.user, user)
        XCTAssertEqual(userTodo, todo)
    }

    func testDelete() async throws {
        let request = UserEntity.fetchRequest()
        let context = persistenceService.container.viewContext

        await context.perform {
            _ = context.save(UserEntity.self) { user in
                user.id = 1
                user.name = "name"
                user.username = "username"
                user.email = "email@email.com"
            }
        }

        let countBeforeDelete = try context.count(for: request)
        XCTAssertEqual(countBeforeDelete, 1)

        let user = try context.fetch(request).first!
        context.delete(entity: user)

        let countAfterDelete = try context.count(for: request)
        XCTAssertEqual(countAfterDelete, 0)
    }
}
