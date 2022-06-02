import Foundation

// Transport maps a URLRequest to Data.
// Makes it easily extendable and testable.
// Simple but powerful idea, taken from
// Rob Napier: http://robnapier.net/a-mockery-of-protocols
public protocol Transport {
    func send(request: URLRequest) async throws -> Data
}

// Check for a couple of
// standard errors
enum ApiError: Error {
    case interalServerError
    case notFound
    case other(String)

    init(statusCode: Int) {
        if statusCode == 500 {
            self = .interalServerError
        } else if statusCode == 404 {
            self = .notFound
        } else {
            let localizedString = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            self = .other(localizedString)
        }
    }
}

public extension URLResponse {
    func validate() throws {
        if let httpResponse = self as? HTTPURLResponse {
            if !(200..<300).contains(httpResponse.statusCode) {
                throw ApiError(statusCode: httpResponse.statusCode)
            }
        }
    }
}

extension URLSession: Transport {
    public func send(request: URLRequest) async throws -> Data {
        let (data, response) = try await self.data(for: request)
        try response.validate()
        return data
    }
}

class ApiClient {
    let transport: Transport

    init(transport: Transport = URLSession.shared) {
        self.transport = transport
    }

    func send<T: Codable>(request: URLRequest) async throws -> T {
        let data = try await transport.send(request: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

    }
}

struct Todo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

struct User: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
}
