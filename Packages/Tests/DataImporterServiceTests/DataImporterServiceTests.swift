//
//  DataImporterServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import XCTest
@testable import DataImporterService
@testable import ApiClient
@testable import PersistenceService
@testable import Models

class DataImporterServiceTests: XCTestCase {

    var apiClient: ApiClient!
    var persistenceService: PersistenceService!
    var dataImporterService: DataImporterService!

    override func setUpWithError() throws {
        let responseData = try JSONEncoder().encode([
            Todo(userId: 1, id: 1, title: "First title", completed: false),
            Todo(userId: 2, id: 2, title: "Second title", completed: true),
            Todo(userId: 3, id: 3, title: "Third title", completed: false),
            Todo(userId: 4, id: 4, title: "Fourth title", completed: true)
        ])

        let testTransport = TestTransport(responseData: responseData, urlResponse: .success)

        self.apiClient = ApiClient(transport: testTransport)
        self.persistenceService = PersistenceService(storeType: .inMemory)
        self.dataImporterService = DataImporterService(
            apiClient: apiClient,
            persistenceService: persistenceService
        )
    }

    override func tearDownWithError() throws {
        apiClient = nil
        persistenceService = nil
    }

    func testImportTodosFromRemote() async throws {
        try await self.dataImporterService.importTodosFromRemote()
        let context = persistenceService.viewContext
        let fetchRequest = TodoEntity.fetchRequest()

        try await context.perform {
            let count = try context.count(for: fetchRequest)
            XCTAssertEqual(count, 4)
            let todo = try context.fetch(fetchRequest).first!
            todo.id = 1
        }
    }

    // Here we simulate that we have 4 unsynced and 6 synced Todos
    // saved in the persistence. As local changes should trump
    // remote changes the 'importTodos(:)' method should NOT overwrite the
    // 4 unsynced changes. The remaining synced todos should be updated
    // and that is simulated with the title being set to "Updated title".
    func testImportTodosWithUnsyncedLocalChanges() async throws {
        let context = persistenceService.backgroundContext

        await context.perform {
            self.setupUnsyncedTodoEntities()
        }

        try await context.perform { [weak self] in
            guard let self = self else { return }

            self.dataImporterService.importTodos(todos: self.getTodos(), context: context)

            let allTodos = try context.fetch(TodoEntity.fetchRequest())

            var syncedCount = 0
            var notSyncedCount = 0
            var syncPendingCount = 0

            for todo in allTodos {
                if todo.synchronizationState == .synchronized {
                    XCTAssertEqual(todo.title, "Updated title")
                    syncedCount += 1
                }
                if todo.synchronizationState == .synchronizationPending {
                    syncPendingCount += 1
                }
                if todo.synchronizationState == .notSynchronized {
                    notSyncedCount += 1
                }
            }

            XCTAssertEqual(notSyncedCount, 4)
            XCTAssertEqual(syncPendingCount, 0)
            XCTAssertEqual(syncedCount, 6)

        }
    }

    private func setupUnsyncedTodoEntities() {
        let context = persistenceService.backgroundContext
        for number in 1...4 {
            let todoEntity = TodoEntity(context: context)
            todoEntity.id = number
            todoEntity.title = "Some title"
            todoEntity.updatedAt = Date.now
            todoEntity.synchronizationState = .notSynchronized
            todoEntity.completed = false
            todoEntity.userId = number
        }

        for number in 5...10 {
            let todoEntity = TodoEntity(context: context)
            todoEntity.id = number
            todoEntity.title = "Some title"
            todoEntity.updatedAt = Date.now
            todoEntity.synchronizationState = .synchronized
            todoEntity.completed = false
            todoEntity.userId = number
        }
        try? context.save()
    }

    private func getTodos() -> [Todo] {
        return [
            Todo(userId: 1, id: 1, title: "Updated title", completed: false),
            Todo(userId: 2, id: 2, title: "Updated title", completed: true),
            Todo(userId: 3, id: 3, title: "Updated title", completed: false),
            Todo(userId: 4, id: 4, title: "Updated title", completed: true),
            Todo(userId: 5, id: 5, title: "Updated title", completed: false),
            Todo(userId: 6, id: 6, title: "Updated title", completed: true),
            Todo(userId: 7, id: 7, title: "Updated title", completed: false),
            Todo(userId: 8, id: 8, title: "Updated title", completed: true),
            Todo(userId: 9, id: 9, title: "Updated title", completed: true),
            Todo(userId: 10, id: 10, title: "Updated title", completed: true)
        ]
    }
}
