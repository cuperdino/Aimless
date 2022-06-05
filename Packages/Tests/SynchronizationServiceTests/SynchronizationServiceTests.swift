//
//  SynchronizationServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import XCTest
@testable import Models
import ApiClient
import PersistenceService
@testable import SynchronizationService

class SynchronizationServiceTests: XCTestCase {

    var persistenceService: PersistenceService!
    lazy var todos = self.createTodos()

    override func setUpWithError() throws {
        self.persistenceService = PersistenceService(storeType: .inMemory)
        Task {
            await self.setupUnsyncedTodoEntities()
        }
    }

    override func tearDownWithError() throws {
        self.persistenceService = nil
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
        // Setup
        let context = self.persistenceService.backgroundContext
        let testTransport = TestTransport(
            responseData: createPostResponse(),
            urlResponse: .success
        )
        let apiClient = ApiClient(transport: testTransport)
        let synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService
        )

        // Validate state before synchronization
        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 10)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }

        // Perform synchronization
        try await synchronizationService.performSynchronization(context: context)

        // Validate state after synchronization
        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 10)
            XCTAssertEqual(unsyncedTodosCount, 0)
        }
    }

    // We pass an error state to api client, which means
    // that the synchronization will error out, and all
    // initially unsynced objects should be reset to the
    // unsynced state, even if they changed their state during
    // the synchronization process.
    func testPerformSynchronizationWithError() async throws {
        // Setup
        let context = self.persistenceService.backgroundContext
        let testTransport = TestTransport(
            responseData: Data(),
            urlResponse: .error
        )
        let apiClient = ApiClient(transport: testTransport)
        let synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService
        )

        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 10)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }

        // Validate state before synchronization
        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 10)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }

        // Perform synchronization
        try await synchronizationService.performSynchronization(context: context)

        // Validate state after synchronization
        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 10)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }
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

    private func createPostResponse() -> Data {
        let string =
        """
        {
            "1": {
                "userId": 1,
                "id": 1,
                "title": "Updated title",
                "completed": false
            },
            "2": {
                "userId": 2,
                "id": 2,
                "title": "Updated title",
                "completed": true
            },
            "3": {
                "userId": 3,
                "id": 3,
                "title": "Updated title",
                "completed": false
            },
            "4": {
                "userId": 4,
                "id": 4,
                "title": "Updated title",
                "completed": true
            },
            "id": 201
        }
        """
        return Data(string.utf8)
    }
}
