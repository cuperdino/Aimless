//
//  TodoEntity+CoreDataClass.swift
//  Aimless
//
//  Created by Sabahudin Kodro on 03/06/2022.
//
//

import Foundation
import CoreData

public enum SynchronizationState: Int {
    case notSynchronized = 0, synchronizationPending, synchronized
}

public enum DeletionState: Int {
    case notDeleted = 0, deletionPending, deleted
}

@objc(TodoEntity)
public class TodoEntity: NSManagedObject {
    public class func fetchRequest() -> NSFetchRequest<TodoEntity> {
        return NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var id: Int
    @NSManaged public var title: String
    @NSManaged public var userId: Int
    @NSManaged public var synchronized: Int
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletion: Int
    @NSManaged public var deletedAt: Date?
    
    public var synchronizationState: SynchronizationState {
        get {
            SynchronizationState(rawValue: synchronized) ?? .notSynchronized
        }
        set {
            synchronized = newValue.rawValue
        }
    }

    public var deletionState: DeletionState {
        get {
            DeletionState(rawValue: deletion) ?? .notDeleted
        }
        set {
            deletion = newValue.rawValue
        }
    }

}

extension TodoEntity {
    public static var sortedFetchRequest: NSFetchRequest<TodoEntity> = {
        let request = TodoEntity.fetchRequest()
        let notDeletedPredicated = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.deletion),
            DeletionState.notDeleted.rawValue
        )
        request.predicate = notDeletedPredicated
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TodoEntity.updatedAt, ascending: false)]
        return request
    }()

    public static var sortedDeletionPendingRequest: NSFetchRequest<TodoEntity> = {
        let request = TodoEntity.fetchRequest()
        let deletionPendingPredicated = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.deletion),
            DeletionState.deletionPending.rawValue
        )
        request.predicate = deletionPendingPredicated
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TodoEntity.updatedAt, ascending: false)]
        return request
    }()

    public static var unsyncedFetchRequest: NSFetchRequest<TodoEntity> {
        let request = NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
        let unsyncedPredicated = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.synchronized),
            SynchronizationState.notSynchronized.rawValue
        )

        let notDeletedPredicated = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.deletion),
            DeletionState.notDeleted.rawValue
        )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unsyncedPredicated, notDeletedPredicated])
        request.predicate = compoundPredicate
        return request
    }

    public static var deletionRequest: NSFetchRequest<TodoEntity> {
        let request = NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
        let deletedPredicate = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.deletion),
            DeletionState.deleted.rawValue
        )

        request.predicate = deletedPredicate
        return request
    }

    public static func findOrCreate(id: Int, in context: NSManagedObjectContext) -> TodoEntity {
        let request = TodoEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "%K == %d",
            #keyPath(TodoEntity.id),
            id
        )

        if let todo = try? context.fetch(request).first {
            return todo
        } else {
            let todo = TodoEntity(context: context)
            return todo
        }
    }

    public func updateFromTodo(todo: Todo, syncState: SynchronizationState) {
        self.userId = todo.userId
        self.id = todo.id
        self.title = todo.title
        self.completed = todo.completed
        self.synchronizationState = syncState
        self.updatedAt = Date()
    }

    public var asTodo: Todo {
        Todo(userId: userId, id: id, title: title, completed: completed)
    }
}


