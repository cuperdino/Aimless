//
//  AimlessApp.swift
//  Aimless
//
//  Created by Sabahudin Kodro on 29/05/2022.
//

import SwiftUI
import PersistenceService
import TodosFeature

@main
struct AimlessApp: App {
    let persistence = PersistenceService()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                TodosView(viewModel: TodosViewModel(persistenceService: persistence))
            }
        }
    }
}
