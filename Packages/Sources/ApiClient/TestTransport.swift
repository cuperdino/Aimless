//
//  TestTransport.swift
//  
//
//  Created by Sabahudin Kodro on 02/06/2022.
//

import Foundation
import ApiClient

extension URLResponse {
    public static var success: HTTPURLResponse {
        let url = URL(string: "some.com")!
        return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    public static var error: HTTPURLResponse {
        let url = URL(string: "some.com")!
        return HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
    }
}

public class TestTransport: Transport {

    let responseData: Data
    let urlResponse: URLResponse

    public init(responseData: Data, urlResponse: URLResponse) {
        self.responseData = responseData
        self.urlResponse = urlResponse
        
    }

    public func send(request: URLRequest) async throws -> Data {
        try urlResponse.validate()
        return responseData
    }
}
