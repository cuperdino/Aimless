//
//  SynchronizationServiceTests.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import XCTest
@testable import ApiClient
@testable import DataImporterService
@testable import PersistenceService

class SynchronizationServiceTests: XCTestCase {

    var dataImporter: DataImporterService!
    var apiClient: ApiClient!

    override func setUpWithError() throws {
        let testTransport = TestTransport(
            responseData: Data(),
            urlResponse: .valid
        )
        let persistenceService = PersistenceService(storeType: .inMemory)
        self.apiClient = ApiClient(transport: testTransport)
        self.dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistenceService)
    }

    override func tearDownWithError() throws {
        self.dataImporter = nil
        self.apiClient = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

}
