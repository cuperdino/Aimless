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

public struct HTTPMethod {
    static let get = "GET"
    static let post = "POST"
}

extension URLRequest {
    private static var baseUrL = URL(string: "https://jsonplaceholder.typicode.com")!

    // GET /users
    static var getUsers: URLRequest {
        var request = URLRequest(url: baseUrL.appendingPathComponent("users"))
        request.httpMethod = HTTPMethod.get
        return request
    }

    // POST /todos
    static func postTodos(todos: [Todo]) -> URLRequest {
        var request = URLRequest(url: baseUrL.appendingPathComponent("users"))
        let body = try? JSONEncoder().encode(todos)
        request.httpBody = body
        request.httpMethod = HTTPMethod.post
        return request
    }

    // GET /user/{id}
    static func getUser(id: Int) -> URLRequest {
        let user = baseUrL.appendingPathComponent("users").appendingPathComponent("\(id)")
        var request = URLRequest(url: user)
        request.httpMethod = HTTPMethod.get
        return request
    }

    // GET /todos
    static var getTodos: URLRequest {
        var request = URLRequest(url: baseUrL.appendingPathComponent("todos"))
        request.httpMethod = HTTPMethod.get
        return request
    }
}

struct Todo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

struct PostResponse<Model: Codable>: Codable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempArray = [Model]()
        for key in container.allKeys {
            guard key.stringValue != "id" else { continue }
            let decodedObject = try container.decode(
                Model.self,
                forKey: DynamicCodingKeys(stringValue: key.stringValue)!
            )
            tempArray.append(decodedObject)
        }
        modelArray = tempArray
    }
}

struct User: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
}
