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
import DataImporterService

class SyncWrapper {
    let synchronizationService: SynchronizationService

    init(apiClient: ApiClient, persistenceService: PersistenceService, dataImporter: DataImporterService) {
        self.synchronizationService = SynchronizationService(
            apiClient: apiClient,
            persistenceService: persistenceService,
            dataImporter: dataImporter
        )
    }

    func startSyncService(context: NSManagedObjectContext) {
        Task {
            while true {
                try await self.synchronizationService.performSynchronization(context: context)
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
    let dataImporter: DataImporterService

    init() {
        self.persistence = PersistenceService()
        self.apiClient = ApiClient()
        self.dataImporter = DataImporterService(apiClient: apiClient, persistenceService: persistence)

        self.syncWrapper = SyncWrapper(
            apiClient: apiClient,
            persistenceService:persistence,
            dataImporter: dataImporter
        )

        self.syncWrapper.startSyncService(context: persistence.backgroundContext)
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                TodosView(viewModel: TodosViewModel(persistenceService: persistence, dataImporter: dataImporter))
            }
        }
    }
}
