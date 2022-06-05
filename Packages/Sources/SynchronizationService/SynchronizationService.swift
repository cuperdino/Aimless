//
//  File.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import Foundation
import ApiClient
import Models
import CoreData
import PersistenceService

class SynchronizationService {

    let apiClient: ApiClient
    let persistenceService: PersistenceService

    init(apiClient: ApiClient, persistenceService: PersistenceService) {
        self.apiClient = apiClient
        self.persistenceService = persistenceService
    }

    func performSynchronization(context: NSManagedObjectContext) async throws {
        let unsyncedTodos: [TodoEntity] = try await context.perform {
            try context.fetchUnscynedTodos()
        }
        guard unsyncedTodos.count > 0 else { return }
        do {
            await context.perform {
                context.updateSyncState(on: unsyncedTodos, state: .synchronizationPending)
            }
            // Sync to remote, and update local state from remote,
            // in case merges happened on the server when posting.
            //
            // Note: as I am using a test API, the server does not actually
            // change. However I added this in as well, just to show what
            // can be done if if does.
            let response: PostArrayResponse<Todo> = try await apiClient.send(
                request: .postTodos(todos: context.perform { unsyncedTodos.map(\.asTodo) } )
            )

            try await context.perform {
                context.importTodos(todos: response.modelArray)
                try context.saveWithRollback()
            }
        } catch {
            try await context.perform {
                context.updateSyncState(on: unsyncedTodos, state: .notSynchronized)
                try context.saveWithRollback()
            }
        }
    }
}

// MARK: Convinience extensions on NSManagedObjectContext used in SynchronizationService
extension NSManagedObjectContext {
    internal func fetchUnscynedTodos() throws -> [TodoEntity] {
        return try self.fetch(TodoEntity.unsyncedFetchRequest)
    }

    internal func updateSyncState(on todos: [TodoEntity], state: SynchronizationState) {
        for todo in todos {
            todo.synchronizationState = state
        }
    }

    internal func importTodos(todos: [Todo]) {
        for todo in todos {
            let todoEntity = TodoEntity.findOrCreate(id: todo.id, in: self)
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
