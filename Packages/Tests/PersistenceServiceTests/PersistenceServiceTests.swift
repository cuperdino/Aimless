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
        verifyAttribute(named: "title", on: todoEntity, hasType: .string, isOptional: false)
        verifyAttribute(named: "id", on: todoEntity, hasType: .integer64, isOptional: false)
        verifyAttribute(named: "title", on: todoEntity, hasType: .string, isOptional: false)
        verifyAttribute(named: "userId", on: todoEntity, hasType: .integer64, isOptional: false)
        verifyAttribute(named: "synchronized", on: todoEntity, hasType: .integer64, isOptional: false)
        verifyAttribute(named: "updatedAt", on: todoEntity, hasType: .date, isOptional: false)
        verifyAttribute(named: "deletion", on: todoEntity, hasType: .integer64, isOptional: false)
        verifyAttribute(named: "deletedAt", on: todoEntity, hasType: .date, isOptional: true)
    }

    func verifyAttribute(
        named name: String,
        on entity: NSEntityDescription,
        hasType type: NSAttributeDescription.AttributeType,
        isOptional: Bool
    ) {
        guard let attribute = entity.attributesByName[name] else {
            XCTFail("\(entity.name!) is missing expected attribute \(name)")
            return
        }
        XCTAssertEqual(attribute.isOptional, isOptional)
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

    func testTodoDeletion() async throws {
        let request = TodoEntity.fetchRequest()
        let context = persistenceService.viewContext

        try await context.perform {
            let todo = context.save(TodoEntity.self) { todo in
                todo.id = 1
                todo.title = "A title"
                todo.completed = false
                todo.userId = 1
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }

            context.softDelete(todo: todo!)
            try context.saveWithRollback()
            for todo in try! context.fetch(request) {
                XCTAssertTrue(todo.deletionState == .deletionPending)
            }

            context.hardDelete(todo: todo!)
            try context.saveWithRollback()
            for todo in try! context.fetch(request) {
                XCTAssertTrue(todo.deletionState == .deleted)
            }

            context.restoreDelete(todo: todo!)
            try context.saveWithRollback()
            for todo in try! context.fetch(request) {
                XCTAssertTrue(todo.deletionState == .notDeleted)
            }
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

    func testUnsyncedFetchRequest() async throws {
        let context = persistenceService.viewContext

        try await context.perform {
            let todo = context.save(TodoEntity.self) { todo in
                todo.id = 1
                todo.title = "A title"
                todo.completed = false
                todo.userId = 1
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }

            context.softDelete(todo: todo!)
            try context.saveWithRollback()

            context.save(TodoEntity.self) { todo in
                todo.id = 2
                todo.title = "Another title"
                todo.completed = false
                todo.userId = 2
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }

            context.save(TodoEntity.self) { todo in
                todo.id = 3
                todo.title = "Another title"
                todo.completed = false
                todo.userId = 3
                todo.synchronizationState = .notSynchronized
                todo.updatedAt = Date()
            }

            let unsyncedFetchRequest = TodoEntity.unsyncedFetchRequest
            let todos = try context.fetch(unsyncedFetchRequest)
            XCTAssertEqual(todos.count, 2)

            for todo in todos {
                XCTAssertTrue(todo.deletionState == .notDeleted)
            }
        }
    }
}
