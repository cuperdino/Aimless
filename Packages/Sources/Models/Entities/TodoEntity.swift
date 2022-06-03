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
    @NSManaged public var id: Int64
    @NSManaged public var title: String?
    @NSManaged public var userId: Int64
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
}


