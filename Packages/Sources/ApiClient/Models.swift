//
//  Models.swift
//  
//
//  Created by Sabahudin Kodro on 02/06/2022.
//

import Foundation

public struct Todo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

public struct User: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

// Custom decoding for post response
public struct PostResponse<Model: Codable>: Codable {
    let modelArray: [Model]

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempArray = [Model]()
        for key in container.allKeys {
            guard let decodedObject = try? container.decode(Model.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!
            ) else {
                continue
            }
            tempArray.append(decodedObject)
        }
        modelArray = tempArray
    }
}
