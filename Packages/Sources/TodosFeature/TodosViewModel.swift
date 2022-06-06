//
//  TodosViewModel.swift
//  
//
//  Created by Sabahudin Kodro on 05/06/2022.
//

import Foundation
import PersistenceService
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
    let todosStorage: TodosFeatureStorage
    var cancellables = [AnyCancellable]()

    @Published var todos: [TodoEntity] = []

    public init(persistenceService: PersistenceService = PersistenceService(storeType: .inMemory)) {
        self.persistenceService = persistenceService
        self.todosStorage = TodosFeatureStorage(context: persistenceService.viewContext)

        self.todosStorage.todos.sink { todos in
            self.todos = todos
        }.store(in: &cancellables)
    }

    func saveTodo(title: String) {
        persistenceService.viewContext.save(TodoEntity.self) { todo in
            todo.id = randomizedId()
            todo.userId = randomizedId()
            todo.synchronizationState = .notSynchronized
            todo.completed = false
            todo.updatedAt = Date()
        }
    }

    func deleteTodo(at offsets: IndexSet) {
        for offset in offsets {
            let book = todos[offset]
            persistenceService.viewContext.delete(book)
        }

        try? persistenceService.viewContext.save()
    }

    func randomizedId() -> Int {
        var string = ""

        for _ in 1...10 {
            string += String(Int.random(in: 0...9))
        }
        return Int(string)!
    }
}
