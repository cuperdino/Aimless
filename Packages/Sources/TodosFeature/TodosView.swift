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
    @State var isSheetPresented = false

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
                    viewModel.softDelete(at: indexSet)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.isSheetPresented = !isSheetPresented
                    } label: {
                        Text("Deletion history")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
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
                        viewModel.importTodosFromRemote()
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
        .sheet(
            isPresented: $isSheetPresented) {
                SheetView(viewModel: viewModel)
            }
        .navigationTitle("Todos")
        .navigationViewStyle(.columns)
    }
}

struct SheetView: View {
    @ObservedObject var viewModel: TodosViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.deletedTodos, id: \.id) { todo in
                    HStack {
                        Text(todo.title)
                        Spacer()
                        todo.synchronizationState.view
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            self.viewModel.restoreDelete(todo: todo)
                        } label: {
                            Label("Restore", systemImage: "arrow.3.trianglepath")
                        }
                        .tint(.indigo)
                        Button(role: .destructive) {
                            viewModel.hardDelete(todo: todo)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.hardDeleteAll(todos: viewModel.deletedTodos)
                    } label: {
                        Text("Delete all")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.restoreAll(todos: viewModel.deletedTodos)
                    } label: {
                        Text("Restore all")
                    }
                }
            }
            .navigationTitle("Deletion history")
        }
    }
}
