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

public class DataImporterService {

    let apiClient: ApiClient
    let persistenceService: PersistenceService

    public init(apiClient: ApiClient, persistenceService: PersistenceService) {
        self.apiClient = apiClient
        self.persistenceService = persistenceService
    }

    public func importTodosFromRemote() async throws {
        let todos: [Todo] = try await apiClient.send(request: .getTodos)
        let context = persistenceService.backgroundContext

        try await context.perform {
            self.importTodos(todos: todos, context: context)
            try context.saveWithRollback()
        }
    }

    public func importTodos(todos: [Todo], context: NSManagedObjectContext) {
        for todo in todos {
            let todoEntity = TodoEntity.findOrCreate(id: todo.id, in: context)
            // If the objectID is temporary, it means it's a new object,
            // not yet persisted to the store. Therefore it is safe to
            // write to it.
            //
            // If the .synchronizationState == .synchronized, it means
            // the object has no local changes to it, which means it is
            // safe to write to it.
            //
            // Otherwise, it means that a local change has occured to the item,
            // and that the item has not yet been synced to remote.
            // Nothing should be done to it now, as it will automatically
            // be synced to remote upon the next sync.
            if todoEntity.objectID.isTemporaryID || todoEntity.synchronizationState == .synchronized {
                todoEntity.updateFromTodo(todo: todo, syncState: .synchronized)
            }
        }
    }
}
