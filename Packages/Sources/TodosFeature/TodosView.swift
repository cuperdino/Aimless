//
//  SwiftUIView.swift
//  
//
//  Created by Sabahudin Kodro on 05/06/2022.
//

import SwiftUI
import Models

extension SynchronizationState {
    var view: some View {
        switch self {
        case .synchronized:
            return Text("Synced").foregroundColor(.green)
        case .notSynchronized:
            return Text("Not synced").foregroundColor(.red)
        case .synchronizationPending:
            return Text("Sync pending...").foregroundColor(.yellow)
        }
    }
}

public struct TodosView: View {
    @ObservedObject var viewModel: TodosViewModel

    public init(viewModel: TodosViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(viewModel.todos, id: \.id) { todo in
                    HStack {
                        Text(todo.title)
                        Spacer()
                        todo.synchronizationState.view
                    }
                }
                .onDelete { indexSet in
                    print("About to delete a movie...")
                    viewModel.deleteTodo(at: indexSet)
                }
            }
            .toolbar {
                EditButton()
            }
            VStack {
                HStack {
                    Button {
                        viewModel.saveTodo()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").font(.title2)
                            Text("Add Todo")
                        }
                    }
                    Spacer()
                    Button {
                        viewModel.saveTodo()
                    } label: {
                        HStack {
                            Text("Import from remote")
                        }
                    }
                }
                .padding(10)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
            .background()
        }

        .navigationTitle("Todos")
        .navigationViewStyle(.columns)
    }
}


/*struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TodosView()
        }
    }
}*/
