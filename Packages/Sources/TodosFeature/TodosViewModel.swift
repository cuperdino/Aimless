//
//  TodosViewModel.swift
//  
//
//  Created by Sabahudin Kodro on 05/06/2022.
//

import Foundation
import PersistenceService
import DataImporterService
import Models
import Combine
import CoreData

public class TodosViewModel: ObservableObject {
    let persistenceService: PersistenceService
    let dataImporter: DataImporterService
    let todosStorage: FeatureStorage<TodoEntity>
    let deletedTodosStorage: FeatureStorage<TodoEntity>
    var cancellables = [AnyCancellable]()

    @Published var todos: [TodoEntity] = []
    @Published var deletedTodos: [TodoEntity] = []

    public init(persistenceService: PersistenceService, dataImporter: DataImporterService) {
        self.persistenceService = persistenceService
        self.dataImporter = dataImporter
        self.todosStorage = FeatureStorage(
            context: persistenceService.viewContext,
            fetchRequest: TodoEntity.sortedFetchRequest
        )

        self.deletedTodosStorage = FeatureStorage(
            context: persistenceService.viewContext,
            fetchRequest: TodoEntity.sortedDeletionPendingRequest
        )

        self.todosStorage.models.sink { todos in
            self.todos = todos
        }.store(in: &cancellables)

        self.deletedTodosStorage.models.sink { deletedTodos in
            self.deletedTodos = deletedTodos
        }.store(in: &cancellables)
    }

    func saveTodo() {
        persistenceService.viewContext.save(TodoEntity.self) { todo in
            let id = randomizedId()
            todo.id = id
            todo.userId = id
            todo.title = "Todo with id: \(id)"
            todo.synchronizationState = .notSynchronized
            todo.completed = false
            todo.updatedAt = Date()
        }
    }

    func softDelete(at offsets: IndexSet) {
        for offset in offsets {
            let todo = todos[offset]
            persistenceService.viewContext.softDelete(todo: todo)
            try? persistenceService.viewContext.saveWithRollback()
        }
    }

    func hardDelete(todo: TodoEntity) {
        persistenceService.viewContext.hardDelete(todo: todo)
        try? persistenceService.viewContext.saveWithRollback()
    }

    func hardDeleteAll(todos: [TodoEntity]) {
        for todo in todos {
            persistenceService.viewContext.hardDelete(todo: todo)
        }
        try? persistenceService.viewContext.saveWithRollback()
    }

    func restoreAll(todos: [TodoEntity]) {
        for todo in todos {
            persistenceService.viewContext.restoreDelete(todo: todo)
        }
        try? persistenceService.viewContext.saveWithRollback()
    }

    func restoreDelete(todo: TodoEntity) {
        persistenceService.viewContext.restoreDelete(todo: todo)
        try? persistenceService.viewContext.saveWithRollback()
    }

    func importTodosFromRemote() {
        Task {
            try? await self.dataImporter.importTodosFromRemote()
        }
    }

    func randomizedId() -> Int {
        var string = ""

        for _ in 1...10 {
            string += String(Int.random(in: 0...9))
        }
        return Int(string)!
    }
}
