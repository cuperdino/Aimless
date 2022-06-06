//
//  TodoEntity+CoreDataClass.swift
//  Aimless
//
//  Created by Sabahudin Kodro on 03/06/2022.
//
//

import Foundation
import CoreData

@objc(TodoEntity)
public class TodoEntity: NSManagedObject {
    public class func fetchRequest() -> NSFetchRequest<TodoEntity> {
        return NSFetchRequest<TodoEntity>(entityName: "TodoEntity")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var id: Int
    @NSManaged public var title: String
    @NSManaged public var userId: Int
    @NSManaged public var user: UserEntity?
    @NSManaged public var synchronized: Int
    @NSManaged public var updatedAt: Date
    
    public var synchronizationState: SynchronizationState {
        get {
            SynchronizationState(rawValue: synchronized) ?? .notSynchronized
        }

        set {
            synchronized = newValue.rawValue
        }
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
}

extension TodoEntity {
    public static var sortedFetchRequest: NSFetchRequest<TodoEntity> = {
        let request = TodoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TodoEntity.updatedAt, ascending: false)]
        return request
    }()
}


