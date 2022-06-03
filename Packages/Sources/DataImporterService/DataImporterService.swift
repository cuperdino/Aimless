//
//  File.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import Foundation
import CoreData
import Models
import ApiClient
import PersistenceService

class DataImporterService {

    let apiClient: ApiClient
    let persistenceService: PersistenceService

    init(apiClient: ApiClient, persistenceService: PersistenceService) {
        self.apiClient = apiClient
        self.persistenceService = persistenceService
    }

    func importTodos() async throws {
        let todos: [Todo] = try await apiClient.send(request: .getTodos)
        let backgroundContext = persistenceService.backgroundContext

        try await backgroundContext.perform {
            for todo in todos {
                let todoEntity = TodoEntity.findOrInsert(id: todo.id, in: backgroundContext)

                if todoEntity.synchronizationState == .synchronized || todoEntity.objectID.isTemporaryID {
                    todoEntity.id = todo.id
                    todoEntity.title = todo.title
                    todoEntity.updatedAt = Date.now
                    todoEntity.synchronizationState = .synchronized
                    todoEntity.completed = todo.completed
                    todoEntity.userId = todo.userId
                }
            }
            try backgroundContext.save()
        }
    }
}
