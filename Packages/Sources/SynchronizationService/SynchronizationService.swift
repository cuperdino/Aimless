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

    public func performSynchronization(context: NSManagedObjectContext) async throws {
        let unsyncedTodos: [TodoEntity] = try await context.perform {
            // Fetch the ones that are not deleted
            try context.fetchUnscynedTodos()
        }

        // Fetch the ones that should be deleted
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
}
