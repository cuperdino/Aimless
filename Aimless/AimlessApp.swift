//
//  AimlessApp.swift
//  Aimless
//
//  Created by Sabahudin Kodro on 29/05/2022.
//

import SwiftUI
import PersistenceService
import TodosFeature
import SynchronizationService
import ApiClient
import CoreData

class SyncWrapper {
    let synchronizationService: SynchronizationService

    init(apiClient: ApiClient, persistenceService: PersistenceService) {
        self.synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService
        )
    }

    func startSyncService(context: NSManagedObjectContext) {
        Task {
            while true {
                print("Synchronization started")
                try? await self.synchronizationService.performSynchronization(context: context)
                print("Synchronization finished")
                try? await Task.sleep(nanoseconds: 20_000_000_000)
            }
        }
    }
}

@main
struct AimlessApp: App {
    let persistence: PersistenceService
    let apiClient: ApiClient
    let syncWrapper: SyncWrapper

    init() {
        self.persistence = PersistenceService()
        self.apiClient = ApiClient()
        self.syncWrapper = SyncWrapper(apiClient: apiClient, persistenceService: persistence)

        self.syncWrapper.startSyncService(context: persistence.backgroundContext)
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                TodosView(viewModel: TodosViewModel(persistenceService: persistence))
            }
        }
    }
}
