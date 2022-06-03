//
//  UserEntity+CoreDataClass.swift
//  Aimless
//
//  Created by Sabahudin Kodro on 03/06/2022.
//
//

import Foundation
import CoreData

@objc(UserEntity)
public class UserEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var email: String?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var username: String?
    @NSManaged public var todos: NSSet?
}

extension UserEntity {
    @objc(addTodosObject:)
    @NSManaged public func addToTodos(_ value: TodoEntity)

    @objc(removeTodosObject:)
    @NSManaged public func removeFromTodos(_ value: TodoEntity)

    @objc(addTodos:)
    @NSManaged public func addToTodos(_ values: NSSet)

    @objc(removeTodos:)
    @NSManaged public func removeFromTodos(_ values: NSSet)
}
