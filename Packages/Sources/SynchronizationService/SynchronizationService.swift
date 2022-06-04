//
//  File.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import Foundation
import ApiClient
import DataImporterService
import Models
import CoreData

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

extension TodoEntity {
    static var unsyncedFetchRequest: NSFetchRequest<TodoEntity> {
        let request = NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
        let predicate = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.synchronized),
            SynchronizationState.notSynchronized.rawValue
        )
        request.predicate = predicate
        return request
    }
}
