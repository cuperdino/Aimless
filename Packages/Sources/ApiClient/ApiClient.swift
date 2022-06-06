import Foundation
import Models

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

public class ApiClient {
    let transport: Transport

    public init(transport: Transport = URLSession.shared) {
        self.transport = transport
    }

    public func send<T: Decodable>(request: URLRequest) async throws -> T {
        let data = try await transport.send(request: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func send(request: URLRequest) async throws {
        _ = try await transport.send(request: request)
    }
}

public struct HTTPMethod {
    static let get = "GET"
    static let post = "POST"
    static let delete = "DELETE"
}

extension URLRequest {
    private static var baseUrL = URL(string: "https://jsonplaceholder.typicode.com")!

    // POST /todos
    public static func postTodos(todos: [Todo]) -> URLRequest {
        var request = URLRequest(url: baseUrL.appendingPathComponent("todos"))
        let body = try? JSONEncoder().encode(todos)
        request.httpBody = body
        request.httpMethod = HTTPMethod.post
        return request
    }

    // GET /todos
    public static var getTodos: URLRequest {
        var request = URLRequest(url: baseUrL.appendingPathComponent("todos"))
        request.httpMethod = HTTPMethod.get
        return request
    }

    // DELETE /todo/{id}
    public static func deleteTodo(id: Int) -> URLRequest {
        let todo = baseUrL.appendingPathComponent("todos").appendingPathComponent("\(id)")
        var request = URLRequest(url: todo)
        request.httpMethod = HTTPMethod.delete
        return request
    }
}
