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

        let testTransport = TestTransport(responseData: responseData, urlResponse: .valid)

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
}
