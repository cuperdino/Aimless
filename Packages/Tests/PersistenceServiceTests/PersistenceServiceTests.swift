//
//  PersistenceServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 29/05/2022.
//

import XCTest
@testable import PersistenceService
import Models
import CoreData

final class PersistenceServiceTests: XCTestCase {

    private var persistenceService: PersistenceService!

    override func setUpWithError() throws {
        persistenceService = PersistenceService(storeType: .inMemory)
    }

    override func tearDown() {
        persistenceService = nil
    }

    func testTodoEntity() {
        let todoEntity = persistenceService.container.managedObjectModel.entitiesByName["TodoEntity"]!
        verifyAttribute(named: "title", on: todoEntity, hasType: .string)
        verifyAttribute(named: "id", on: todoEntity, hasType: .integer64)
        verifyAttribute(named: "title", on: todoEntity, hasType: .string)
        verifyAttribute(named: "userId", on: todoEntity, hasType: .integer64)
        verifyAttribute(named: "synchronized", on: todoEntity, hasType: .integer64)
        verifyAttribute(named: "updatedAt", on: todoEntity, hasType: .date)

        guard let userRelationship = todoEntity.relationshipsByName["user"] else {
            XCTFail("TodoEntity is missing expected relationship 'user'")
            return
        }
        XCTAssertFalse(userRelationship.isToMany)
        let userEntity = persistenceService.container.managedObjectModel.entitiesByName["UserEntity"]!
        XCTAssertEqual(userEntity, userRelationship.destinationEntity)
    }

    func testUserEntity() {
        let userEntity = persistenceService.container.managedObjectModel.entitiesByName["UserEntity"]!
        verifyAttribute(named: "email", on: userEntity, hasType: .string)
        verifyAttribute(named: "id", on: userEntity, hasType: .integer64)
        verifyAttribute(named: "name", on: userEntity, hasType: .string)
        verifyAttribute(named: "username", on: userEntity, hasType: .string)

        guard let todoRelationShip = userEntity.relationshipsByName["todos"] else {
            XCTFail("UserEntity is missing expected relationship 'todos'")
            return
        }
        XCTAssertTrue(todoRelationShip.isToMany)
        let todoEntity = persistenceService.container.managedObjectModel.entitiesByName["TodoEntity"]!
        XCTAssertEqual(todoEntity, todoRelationShip.destinationEntity)
    }

    func verifyAttribute(
        named name: String,
        on entity: NSEntityDescription,
        hasType type: NSAttributeDescription.AttributeType
    ) {
        guard let attribute = entity.attributesByName[name] else {
            XCTFail("\(entity.name!) is missing expected attribute \(name)")
            return
        }
        XCTAssertEqual(type, attribute.type)
    }

    func testSave() async throws {
        let todoRequest = TodoEntity.fetchRequest()
        let viewContext = persistenceService.viewContext

        try await viewContext.perform {
            let todoInitialCount = try viewContext.count(for: todoRequest)
            XCTAssertEqual(todoInitialCount, 0)

            _ = viewContext.save(TodoEntity.self) { todo in
                todo.id = 1
                todo.title = "A title"
                todo.completed = false
                todo.userId = 1
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }
            let todoFinalCount = try viewContext.count(for: todoRequest)
            XCTAssertEqual(todoFinalCount, 1)
        }
    }

    func testSaveWithRelationShips() async throws {
        let todoRequest = TodoEntity.fetchRequest()
        let userRequest = UserEntity.fetchRequest()
        let viewContext = persistenceService.viewContext

        try await viewContext.perform {
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

            let todoToAssert = try viewContext.fetch(todoRequest).first!
            let user = try viewContext.fetch(userRequest).first!
            let userTodo = user.todos?.allObjects.first as? TodoEntity

            XCTAssertEqual(todoToAssert.user, user)
            XCTAssertEqual(userTodo, todo)
        }
    }

    func testDelete() async throws {
        let request = UserEntity.fetchRequest()
        let context = persistenceService.viewContext

        await context.perform {
            _ = context.save(UserEntity.self) { user in
                user.id = 1
                user.name = "name"
                user.username = "username"
                user.email = "email@email.com"
            }
        }

        try await context.perform {
            let countBeforeDelete = try context.count(for: request)
            XCTAssertEqual(countBeforeDelete, 1)

            let user = try context.fetch(request).first!
            context.delete(entity: user)

            let countAfterDelete = try context.count(for: request)
            XCTAssertEqual(countAfterDelete, 0)
        }
    }

    func testSaveWithRollback() async throws {
        let context = persistenceService.viewContext
        await context.perform {
            let todo1 = TodoEntity(context: context)
            todo1.title = ""
            // Perform a save without assigning non-optional values
            try? context.save()
            // As we have not rolled back, there are items
            // in the insertedObjects of the context
            XCTAssertFalse(context.insertedObjects.isEmpty)

            let todo2 = TodoEntity(context: context)
            todo2.title = ""
            // Perform a save without assigning non-optional values
            try? context.saveWithRollback()
            // As we have rolled back, there should not be
            // any elements in the insertedObjects of the context
            XCTAssertTrue(context.insertedObjects.isEmpty)
        }
    }
}
