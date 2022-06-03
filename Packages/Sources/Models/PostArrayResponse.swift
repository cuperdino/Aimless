//
//  PostArrayResponse.swift
//  
//
//  Created by Sabahudin Kodro on 03/06/2022.
//

import Foundation

public struct PostArrayResponse<Model: Decodable>: Decodable {
    public let modelArray: [Model]

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
            guard let decodedObject = try? container.decode(Model.self, forKey: key) else {
                continue
            }
            tempArray.append(decodedObject)
        }
        modelArray = tempArray
    }
}
