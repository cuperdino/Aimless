//
//  PersistenceService.swift
//  
//
//  Created by Sabahudin Kodro on 29/05/2022.
//

import Foundation
import CoreData

class PersistenceService {
    let container: PersistenceContainer

    init(storeType: PersistenceContainer.StoreType = .persisted) {
        container = PersistenceContainer(name: "Model", storeType: storeType)

        container.loadPersistentStores(completionHandler: { description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error)")
            }
        })
    }

    func save<T: NSManagedObject>(
        _ entity: T.Type,
        context: NSManagedObjectContext,
        _ body: (inout T) -> Void
    ) {
        var entity = entity.init(context: context)
        body(&entity)
        do {
            try context.save()
        } catch {
            context.rollback()
            print("Error", error)
        }
    }

    func delete<T: NSManagedObject>(entity: T, context: NSManagedObjectContext) {
        context.delete(entity)
        do {
            try context.save()
        } catch {
            context.rollback()
            print("Error", error)
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



