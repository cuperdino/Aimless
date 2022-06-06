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

class TodosFeatureStorage: NSObject {
    var todos = CurrentValueSubject<[TodoEntity], Never>([])
    private var fetchedResultsController: NSFetchedResultsController<TodoEntity>

    init(context: NSManagedObjectContext) {
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: TodoEntity.sortedFetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil, cacheName: nil
        )
        super.init()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            self.todos.value = fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Could not fetch todos")
        }
    }
}

extension TodosFeatureStorage: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let todos = controller.fetchedObjects as? [TodoEntity] else {
            return
        }
        self.todos.value = todos
    }
}

public class TodosViewModel: ObservableObject {
    let persistenceService: PersistenceService
    let dataImporter: DataImporterService
    let todosStorage: TodosFeatureStorage
    var cancellables = [AnyCancellable]()

    @Published var todos: [TodoEntity] = []

    public init(persistenceService: PersistenceService, dataImporter: DataImporterService) {
        self.persistenceService = persistenceService
        self.dataImporter = dataImporter
        self.todosStorage = TodosFeatureStorage(context: persistenceService.viewContext)

        self.todosStorage.todos.sink { todos in
            self.todos = todos
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

    func deleteTodo(at offsets: IndexSet) {
        for offset in offsets {
            let todo = todos[offset]
            persistenceService.viewContext.softDelete(todo: todo)
        }

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
