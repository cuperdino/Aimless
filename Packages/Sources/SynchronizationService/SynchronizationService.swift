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
import DataImporterService

public class SynchronizationService {

    private let apiClient: ApiClient
    private let persistenceService: PersistenceService
    private let dataImporter: DataImporterService

    public init(apiClient: ApiClient, persistenceService: PersistenceService, dataImporter: DataImporterService) {
        self.apiClient = apiClient
        self.persistenceService = persistenceService
        self.dataImporter = dataImporter
    }

    public func performSynchronization(context: NSManagedObjectContext) async {
        await withTaskGroup(of: Void.self, body: { group in
            group.addTask {
                await self._synchronization(context: context)
            }
            group.addTask {
                await self._deletionSynchronization(context: context)
            }
        })
    }

    internal func _synchronization(context: NSManagedObjectContext) async {
        print("_synchronization started")
        defer { print("_synchronization ended")}
        let unsyncedTodos: [TodoEntity] = await context.perform {
            do {
                return try context.fetchUnscynedTodos()
            } catch {
                return []
            }
        }

        guard unsyncedTodos.count > 0 else { return }
        do {
            try await context.perform {
                context.updateSyncState(on: unsyncedTodos, state: .synchronizationPending)
                try context.saveWithRollback()
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
                context.updateSyncState(on: unsyncedTodos, state: .synchronized)
                try context.saveWithRollback()
            }

            try await context.perform {
                self.dataImporter.importTodos(
                    todos: response.modelArray,
                    context: context
                )
                try context.saveWithRollback()
            }
        } catch {
            await context.perform {
                context.updateSyncState(on: unsyncedTodos, state: .notSynchronized)
                do {
                    try context.saveWithRollback()
                } catch {
                    print("Sync error: \(error) occured, could not reset state")
                }
            }
        }
    }

    internal func _deletionSynchronization(context: NSManagedObjectContext) async {
        print("_deletionSynchronization started")
        defer { print("_deletionSynchronization ended")}
        let deletedTodoEntities: [TodoEntity] = await context.perform {
            do {
                return try context.fetchDeletedTodos()
            } catch {
                return []
            }
        }
        guard !deletedTodoEntities.isEmpty else { return }

        do {
            let deletedTodos = await context.perform { deletedTodoEntities.map(\.asTodo) }
            try await withThrowingTaskGroup(of: Void.self) { group in
                for todo in deletedTodos {
                    group.addTask {
                        try await self.apiClient.send(request: .deleteTodo(id: todo.id))
                    }
                }
            }
            try await context.perform {
                for todo in deletedTodoEntities {
                    context.delete(todo)
                }
                try context.saveWithRollback()
            }
        } catch {
            await context.perform {
                for todo in deletedTodoEntities {
                    todo.deletionState = .deleted
                }
                do {
                    try context.saveWithRollback()
                } catch {
                    print("Sync deletion error: \(error) occured, could not reset state")
                }
            }
        }
    }
}

// MARK: Convinience extensions on NSManagedObjectContext used in SynchronizationService
extension NSManagedObjectContext {
    internal func fetchUnscynedTodos() throws -> [TodoEntity] {
        return try self.fetch(TodoEntity.unsyncedFetchRequest)
    }

    internal func fetchDeletedTodos() throws -> [TodoEntity] {
        return try self.fetch(TodoEntity.deletionRequest)
    }

    internal func updateSyncState(on todos: [TodoEntity], state: SynchronizationState) {
        for todo in todos {
            todo.synchronizationState = state
        }
    }
}
