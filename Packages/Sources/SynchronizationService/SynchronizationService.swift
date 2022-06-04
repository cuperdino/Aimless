//
//  File.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import Foundation
import ApiClient
import DataImporterService

class SynchronizationService {

    let dataImporter: DataImporterService
    let apiClient: ApiClient

    init(dataImporter: DataImporterService, apiClient: ApiClient) {
        self.dataImporter = dataImporter
        self.apiClient = apiClient
    }

    func performSynchronization() async throws {
        
    }
}
