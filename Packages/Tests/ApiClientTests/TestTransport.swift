//
//  TestTransport.swift
//  
//
//  Created by Sabahudin Kodro on 02/06/2022.
//

import Foundation
import ApiClient

class TestTransport: Transport {

    let responseData: Data
    let urlResponse: URLResponse

    init(responseData: Data, urlResponse: URLResponse) {
        self.responseData = responseData
        self.urlResponse = urlResponse
        
    }

    func send(request: URLRequest) async throws -> Data {
        try urlResponse.validate()
        return responseData
    }
}
