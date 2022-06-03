//
//  Todo.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import Foundation

public struct Todo: Codable {
    public let userId: Int
    public let id: Int
    public let title: String
    public let completed: Bool
}
