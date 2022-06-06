//
//  TodosFeatureStorage.swift
//  
//
//  Created by Sabahudin Kodro on 06/06/2022.
//

import Foundation
import Combine
import CoreData
import Models

class FeatureStorage<Entity: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    var models = CurrentValueSubject<[Entity], Never>([])
    private var fetchedResultsController: NSFetchedResultsController<Entity>

    init(context: NSManagedObjectContext, fetchRequest: NSFetchRequest<Entity>) {
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil, cacheName: nil
        )
        super.init()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            self.models.value = fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Could not fetch todos")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let models = controller.fetchedObjects as? [Entity] else {
            return
        }
        self.models.value = models
    }
}
