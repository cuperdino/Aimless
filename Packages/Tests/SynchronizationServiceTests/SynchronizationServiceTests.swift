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
@testable import SynchronizationService

class SynchronizationServiceTests: XCTestCase {

    var dataImporter: DataImporterService!
    var apiClient: ApiClient!
    var synchronizationService: SynchronizationService!

    override func setUpWithError() throws {
        let testTransport = TestTransport(
            responseData: Data(),
            urlResponse: .valid
        )
        let persistenceService = PersistenceService(storeType: .inMemory)
        self.apiClient = ApiClient(transport: testTransport)
        self.dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistenceService)
        self.synchronizationService = SynchronizationService(dataImporter: dataImporter, apiClient: apiClient)
    }

    override func tearDownWithError() throws {
        self.dataImporter = nil
        self.apiClient = nil
    }

    func testPerformSynchronization() async throws {
        try await self.synchronizationService.performSynchronization()
    }

}
