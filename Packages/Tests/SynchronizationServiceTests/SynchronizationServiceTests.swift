//
//  SynchronizationServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import XCTest
import Models
import ApiClient
import PersistenceService
@testable import SynchronizationService

class SynchronizationServiceTests: XCTestCase {

    var apiClient: ApiClient!
    var synchronizationService: SynchronizationService!
    var persistenceService: PersistenceService!
    lazy var todos = self.createTodos()

    override func setUpWithError() throws {
        let todosData = try! JSONEncoder().encode(todos)
        let testTransport = TestTransport(
            responseData: todosData,
            urlResponse: .valid
        )
        self.persistenceService = PersistenceService(storeType: .inMemory)
        self.apiClient = ApiClient(transport: testTransport)
        self.synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService
        )
        Task {
            await self.setupUnsyncedTodoEntities()
        }
    }

    override func tearDownWithError() throws {
        self.apiClient = nil
        self.persistenceService = nil
        self.synchronizationService = nil
    }

    func testFetchUnsyncedTodos() async throws {
        let context = persistenceService.backgroundContext

        let unsyncedTodos = try await context.fetchUnscynedTodos()

        try await context.perform {
            let allTodos = TodoEntity.fetchRequest()
            let allCount = try context.count(for: allTodos)

            XCTAssertEqual(10, allCount)
            XCTAssertEqual(4, unsyncedTodos.count)
        }
    }

    func testUpdateTodoSyncState() async throws {
        let context = persistenceService.backgroundContext
        let unsyncedTodos = try await context.fetchUnscynedTodos()
        try await context.updateSyncState(on: unsyncedTodos, state: .synchronizationPending)

        try await context.perform {
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest

            let allCount = try context.count(for: allTodosRequest)
            let unsyncedCount = try context.count(for: unsyncedTodosRequest)

            let allTodos = try context.fetch(allTodosRequest)
            var syncPendingCount = 0
            for todo in allTodos {
                if todo.synchronizationState == .synchronizationPending {
                    syncPendingCount += 1
                }
            }

            XCTAssertEqual(allCount, 10)
            XCTAssertEqual(unsyncedCount, 0)
            XCTAssertEqual(syncPendingCount, 4)
        }
    }

    // Here we simulate that we have 4 unsynced and 6 synced Todos
    // saved in the persistence. As local changes should trump
    // remote changes the 'importTodos(:)' method should NOT overwrite the
    // 4 unsynced changes. The remaining synced todos should be updated
    // and that is simulated with the title being set to "Updated title".
    func testImportTodosWithUnsyncedLocalChanges() async throws {
        let context = persistenceService.backgroundContext
        try await context.importTodos(todos: todos)

        try await context.perform {
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest

            let allCount = try context.count(for: allTodosRequest)
            let unsyncedCount = try context.count(for: unsyncedTodosRequest)

            XCTAssertEqual(allCount, 10)
            XCTAssertEqual(unsyncedCount, 4)

            var synchronizedCount = 0

            for todo in try! context.fetch(allTodosRequest) {
                if todo.synchronizationState == .synchronized {
                    synchronizedCount += 1
                    XCTAssertEqual("Updated title", todo.title!)
                } else {
                    XCTAssertEqual("Some title", todo.title!)
                }
            }
            XCTAssertEqual(synchronizedCount, 6)
        }
    }

    func testPerformSynchronization() async throws {
        try await self.synchronizationService.performSynchronization(context: persistenceService.backgroundContext)
    }

    private func setupUnsyncedTodoEntities() async {
        let context = persistenceService.backgroundContext
        try? await context.perform {
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
            try context.save()
        }
    }

    private func createTodos() -> [Todo] {
        var todos = [Todo]()
        for number in 1...10 {
            let todo = Todo(
                userId: number,
                id: number,
                title: "Updated title",
                completed: false
            )
            todos.append(todo)
        }
        return todos
    }
}
