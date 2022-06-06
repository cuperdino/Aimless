//
//  SwiftUIView.swift
//  
//
//  Created by Sabahudin Kodro on 05/06/2022.
//

import SwiftUI
import Models

public struct TodosView: View {
    @ObservedObject var viewModel: TodosViewModel

    public init(viewModel: TodosViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            ForEach(viewModel.todos, id: \.id) { todo in
                HStack {
                    Text(todo.title)
                }
            }
        }
        .toolbar {
            EditButton()
        }
        .navigationTitle("Todos")
        .navigationViewStyle(.columns)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TodosView(viewModel: TodosViewModel())
        }
    }
}
