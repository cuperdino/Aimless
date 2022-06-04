//
//  PersistenceService.swift
//  
//
//  Created by Sabahudin Kodro on 29/05/2022.
//

import Foundation
import CoreData

public class PersistenceService {
    public let container: PersistenceContainer
    public let backgroundContext: NSManagedObjectContext
    public let viewContext: NSManagedObjectContext

    public init(storeType: PersistenceContainer.StoreType = .persisted) {
        container = PersistenceContainer(name: "Model", storeType: storeType)

        container.loadPersistentStores(completionHandler: { description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error)")
            }
        })

        self.viewContext = container.viewContext
        self.backgroundContext = container.newBackgroundContext()
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func save<T: NSManagedObject>(
        _ entity: T.Type,
        _ body: (inout T) -> Void
    ) -> T? {
        var entity = entity.init(context: self)
        body(&entity)
        do {
            try self.saveWithRollback()
            return entity
        } catch {
            print(error)
            return nil
        }
    }

    func delete<T: NSManagedObject>(entity: T) {
        self.delete(entity)
        do {
            try self.saveWithRollback()
        } catch {
            print(error)
        }
    }

    func saveWithRollback() throws {
        do {
            try self.save()
        } catch {
            self.rollback()
            throw error
        }
    }
}

public final class PersistenceContainer: NSPersistentContainer {
    public enum StoreType {
      case inMemory, persisted
    }

    public init(name: String, storeType: StoreType) {
        guard let mom = NSManagedObjectModel.mergedModel(from: [Bundle.module]) else {
            fatalError("Failed to create mom")
        }
        super.init(name: name, managedObjectModel: mom)

        // the .inMemory type is used to save the core data in-memory
        // rather than on-disk. This is for testing purposes
        // as it will not persist data after finishing test executions
        // and we'll have a clean slate before executing each test.
        if let storeDescription = persistentStoreDescriptions.first {
            if storeType == .inMemory {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
            }
        }
    }
}



