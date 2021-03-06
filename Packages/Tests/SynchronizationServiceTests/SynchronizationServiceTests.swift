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
import DataImporterService
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

        try await context.perform {
            let unsyncedTodos = try context.fetchUnscynedTodos()
            let allTodos = TodoEntity.fetchRequest()
            let allCount = try context.count(for: allTodos)

            XCTAssertEqual(15, allCount)
            XCTAssertEqual(4, unsyncedTodos.count)
        }
    }

    func testUpdateTodoSyncState() async throws {
        let context = persistenceService.backgroundContext
        let unsyncedTodos = try await context.perform { try context.fetchUnscynedTodos() }
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

            XCTAssertEqual(allCount, 15)
            XCTAssertEqual(unsyncedCount, 0)
            XCTAssertEqual(syncPendingCount, 4)
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
        let dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistenceService)
        let synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService,
            dataImporter: dataImporter
        )

        // Validate state before synchronization
        try await context.perform {
            let allTodos = try context.fetch(TodoEntity.fetchRequest())

            var syncedCount = 0
            var notSyncedCount = 0
            var syncPendingCount = 0

            for todo in allTodos {
                if todo.synchronizationState == .synchronized {
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
            XCTAssertEqual(syncedCount, 11)
        }

        // Perform synchronization
        await synchronizationService._synchronization(context: context)

        // Validate state after synchronization
        try await context.perform {
            let allTodos = try context.fetch(TodoEntity.fetchRequest())

            var syncedCount = 0
            var notSyncedCount = 0
            var syncPendingCount = 0

            for todo in allTodos {
                if todo.synchronizationState == .synchronized {
                    syncedCount += 1
                }
                if todo.synchronizationState == .synchronizationPending {
                    syncPendingCount += 1
                }
                if todo.synchronizationState == .notSynchronized {
                    notSyncedCount += 1
                }
            }

            XCTAssertEqual(notSyncedCount, 0)
            XCTAssertEqual(syncPendingCount, 0)
            XCTAssertEqual(syncedCount, 15)
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
        let dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistenceService)

        let synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService,
            dataImporter: dataImporter
        )

        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 15)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }

        // Validate state before synchronization
        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 15)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }

        // Perform synchronization
        await synchronizationService._synchronization(context: context)

        // Validate state after synchronization
        try await context.perform {
            let unsyncedTodosRequest = TodoEntity.unsyncedFetchRequest
            let allTodosRequest = TodoEntity.fetchRequest()
            let unsyncedTodosCount = try context.count(for: unsyncedTodosRequest)
            let allTodosCount = try context.count(for: allTodosRequest)

            XCTAssertEqual(allTodosCount, 15)
            XCTAssertEqual(unsyncedTodosCount, 4)
        }
    }

    func testDeletionSynchronization() async throws {
        // Setup
        let context = self.persistenceService.backgroundContext
        let testTransport = TestTransport(
            responseData: createPostResponse(),
            urlResponse: .success
        )
        let apiClient = ApiClient(transport: testTransport)
        let dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistenceService)
        let synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService,
            dataImporter: dataImporter
        )

        // Validate state before synchronization
        try await context.perform {
            let allTodos = try context.fetch(TodoEntity.fetchRequest())

            var notDeleted = 0
            var deletionPending = 0
            var deleted = 0

            for todo in allTodos {
                if todo.deletionState == .notDeleted {
                    notDeleted += 1
                }

                if todo.deletionState == .deletionPending {
                    deletionPending += 1
                }

                if todo.deletionState == .deleted {
                    deleted += 1
                }
            }

            XCTAssertEqual(notDeleted, 10)
            XCTAssertEqual(deletionPending, 0)
            XCTAssertEqual(deleted, 5)
        }

        // Perform synchronization
        await synchronizationService._deletionSynchronization(context: context)

        // Validate state after synchronization
        try await context.perform {
            let allTodos = try context.fetch(TodoEntity.fetchRequest())

            var notDeleted = 0
            var deletionPending = 0
            var deleted = 0

            for todo in allTodos {
                if todo.deletionState == .notDeleted {
                    notDeleted += 1
                }

                if todo.deletionState == .deletionPending {
                    deletionPending += 1
                }

                if todo.deletionState == .deleted {
                    deleted += 1
                }
            }

            XCTAssertEqual(notDeleted, 10)
            XCTAssertEqual(deletionPending, 0)
            XCTAssertEqual(deleted, 0)
        }
    }

    private func setupUnsyncedTodoEntities() async {
        let context = persistenceService.backgroundContext
        try? await context.perform {
            // Setup .notSynchronized todos
            for number in 1...4 {
                let todoEntity = TodoEntity(context: context)
                todoEntity.id = number
                todoEntity.title = "Some title"
                todoEntity.updatedAt = Date.now
                todoEntity.synchronizationState = .notSynchronized
                todoEntity.completed = false
                todoEntity.userId = number
            }

            // Setup .synchronized todos
            for number in 5...10 {
                let todoEntity = TodoEntity(context: context)
                todoEntity.id = number
                todoEntity.title = "Some title"
                todoEntity.updatedAt = Date.now
                todoEntity.synchronizationState = .synchronized
                todoEntity.completed = false
                todoEntity.userId = number
            }
            for number in 11...15 {
                let todoEntity = TodoEntity(context: context)
                todoEntity.id = number
                todoEntity.title = "Some title"
                todoEntity.updatedAt = Date.now
                todoEntity.synchronizationState = .synchronized
                todoEntity.deletionState = .deleted
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
