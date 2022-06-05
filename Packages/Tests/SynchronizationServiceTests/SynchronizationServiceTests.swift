//
//  SynchronizationServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import XCTest
import Models
import ApiClient
import DataImporterService
import PersistenceService
@testable import SynchronizationService

class SynchronizationServiceTests: XCTestCase {

    var dataImporter: DataImporterService!
    var apiClient: ApiClient!
    var synchronizationService: SynchronizationService!
    var persistenceService: PersistenceService!

    override func setUpWithError() throws {
        let responseData = try! JSONEncoder().encode([
            Todo(userId: 1, id: 1, title: "A title", completed: false),
            Todo(userId: 2, id: 2, title: "Another title", completed: false),
            Todo(userId: 3, id: 3, title: "A thirds title", completed: false)
        ])
        let testTransport = TestTransport(
            responseData: responseData,
            urlResponse: .valid
        )
        self.persistenceService = PersistenceService(storeType: .inMemory)
        self.apiClient = ApiClient(transport: testTransport)
        self.dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistenceService)
        self.synchronizationService = SynchronizationService(
            dataImporter: dataImporter,
            apiClient: apiClient,
            persistenceService: persistenceService
        )
    }

    override func tearDownWithError() throws {
        self.dataImporter = nil
        self.apiClient = nil
        self.persistenceService = nil
        self.synchronizationService = nil
    }

    func testPerformSynchronization() async throws {
        try await self.synchronizationService.performSynchronization()
    }

    func testFetchUnsyncedTodos() async throws {
        let context = persistenceService.backgroundContext

        try await context.perform {
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

        try await context.perform {
            let allTodos = TodoEntity.fetchRequest()
            let unsyncedFetchRequest = TodoEntity.unsyncedFetchRequest

            let allCount = try context.count(for: allTodos)
            let unsyncedCount = try context.count(for: unsyncedFetchRequest)
            XCTAssertEqual(10, allCount)
            XCTAssertEqual(4, unsyncedCount)
        }
    }

}
