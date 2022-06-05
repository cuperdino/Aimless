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
import PersistenceService

class SynchronizationService {

    let dataImporter: DataImporterService
    let apiClient: ApiClient
    let persistenceService: PersistenceService

    init(dataImporter: DataImporterService, apiClient: ApiClient, persistenceService: PersistenceService) {
        self.dataImporter = dataImporter
        self.apiClient = apiClient
        self.persistenceService = persistenceService
    }

    func performSynchronization() async throws {
        // Fetch all unsynced items
        let context = persistenceService.backgroundContext
        let unsyncedTodos: [Todo] = try await persistenceService.backgroundContext.perform {
            let unsyncedRequest = TodoEntity.unsyncedFetchRequest
            return try context.fetch(unsyncedRequest).map { $0.asTodo }
        }
        
        // post them to remote
        // retrieve response and sync it to local
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
