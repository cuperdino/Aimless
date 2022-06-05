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

    func performSynchronization(context: NSManagedObjectContext) async throws {
        let unsyncedTodos = try await context.fetchUnscynedTodos()
        try await context.updateSyncState(on: unsyncedTodos, state: .synchronizationPending)
    }
}

// MARK: Convinience extensions on NSManagedObjectContext used in SynchronizationService
extension NSManagedObjectContext {
    internal func fetchUnscynedTodos() async throws -> [TodoEntity] {
        try await self.perform {
            return try self.fetch(TodoEntity.unsyncedFetchRequest)
        }
    }

    internal func updateSyncState(on todos: [TodoEntity], state: SynchronizationState) async throws {
        try await self.perform {
            for todo in todos {
                todo.synchronizationState = state
            }
            try self.saveWithRollback()
        }
    }
}

// MARK: Convinience extensions on TodoEntity used in SynchronizationService
extension TodoEntity {
    internal static var unsyncedFetchRequest: NSFetchRequest<TodoEntity> {
        let request = NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
        let predicate = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.synchronized),
            SynchronizationState.notSynchronized.rawValue
        )
        request.predicate = predicate
        return request
    }

    internal var asTodo: Todo {
        Todo(userId: userId, id: id, title: title ?? "", completed: completed)
    }

    internal func updateFromTodo(todo: Todo, syncState: SynchronizationState) {
        self.userId = todo.userId
        self.id = todo.id
        self.title = todo.title
        self.completed = todo.completed
        self.synchronizationState = syncState
        self.updatedAt = Date()
    }
}
