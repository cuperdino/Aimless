import XCTest
@testable import ApiClient
@testable import Models

final class ApiClientTests: XCTestCase {

    let apiClient = ApiClient()

    func testNotFoundError() async throws {
        await XCTAssertThrowsError(try await testApiError(withStatusCode: 404)) { error in
            guard case .notFound = error as! ApiError else {
                return XCTFail("Expected .notFound, but got \(error)")
            }
            XCTAssert(true)
        }
    }

    func testInternalServerError() async throws {
        await XCTAssertThrowsError(try await testApiError(withStatusCode: 500)) { error in
            guard case .interalServerError = error as! ApiError else {
                return XCTFail("Expected .interalServerError, but got \(error)")
            }
            XCTAssert(true)
        }
    }

    func testOtherError() async throws {
        await XCTAssertThrowsError(try await testApiError(withStatusCode: 505)) { error in
            guard case .other = error as! ApiError else {
                return XCTFail("Expected .other, but got \(error)")
            }
            XCTAssert(true)
        }
    }

    func testGetResponseParsing() async throws {
        let string =
        """
            [
                {
                    "userId": 1,
                    "id": 1,
                    "title": "delectus aut autem",
                    "completed": false
                }
            ]
        """
        let responseData = Data(string.utf8)

        let testTransport = TestTransport(responseData: responseData, urlResponse: .success)
        let apiClient = ApiClient(transport: testTransport)

        let todos: [Todo] = try await apiClient.send(request: .getTodos)
        XCTAssertEqual(todos.first!.title, "delectus aut autem")
        XCTAssertEqual(todos.count, 1)
    }

    func testPostArrayResponseParsing() async throws {
        let string =
        """
        {
            "0": {
                "userId": 1,
                "id": 1,
                "title": "delectus aut autem",
                "completed": false
            },
            "1": {
                "userId": 2,
                "id": 2,
                "title": "delectus aut autem",
                "completed": true
            },
            "id": 201
        }
        """
        let responseData = Data(string.utf8)

        let testTransport = TestTransport(responseData: responseData, urlResponse: .success)
        let apiClient = ApiClient(transport: testTransport)

        let todos = [
            Todo(userId: 1, id: 1, title: "delectus aut autem", completed: false),
            Todo(userId: 2, id: 2, title: "delectus aut autem", completed: true)
        ]
        let todosResponse: PostArrayResponse<Todo> = try await apiClient.send(request: .postTodos(todos: todos))
        XCTAssertEqual(todosResponse.modelArray.first!.title, "delectus aut autem")
        XCTAssertEqual(todosResponse.modelArray.count, 2)
    }

    func testGetUsersRequest() async throws {
        XCTAssertEqual(URLRequest.getUsers.url, URL(string: "https://jsonplaceholder.typicode.com/users"))
        XCTAssertEqual(URLRequest.getTodos.httpMethod, HTTPMethod.get)
    }

    func testGetTodosRequest() async throws {
        XCTAssertEqual(URLRequest.getTodos.url, URL(string: "https://jsonplaceholder.typicode.com/todos"))
        XCTAssertEqual(URLRequest.getTodos.httpMethod, HTTPMethod.get)
    }

    func testGetUserRequest() async throws {
        XCTAssertEqual(URLRequest.getUser(id: 1).url, URL(string: "https://jsonplaceholder.typicode.com/users/1"))
        XCTAssertEqual(URLRequest.getTodos.httpMethod, HTTPMethod.get)
    }

    func testPostUsersRequest() async throws {
        let todos = [Todo(userId: 1, id: 1, title: "delectus aut autem", completed: false)]
        let postTodoRequest = URLRequest.postTodos(todos: todos)
        let data = try JSONEncoder().encode(todos)

        XCTAssertEqual(postTodoRequest.url, URL(string: "https://jsonplaceholder.typicode.com/todos")!)
        XCTAssertEqual(postTodoRequest.httpBody, data)
        XCTAssertEqual(postTodoRequest.httpMethod, HTTPMethod.post)
    }

    func testDeleteTodoRequest() async throws {
        let deleteTodoRequest = URLRequest.deleteTodo(id: 1)

        XCTAssertEqual(deleteTodoRequest.url, URL(string: "https://jsonplaceholder.typicode.com/todos/1")!)
        XCTAssertEqual(deleteTodoRequest.httpMethod, HTTPMethod.delete)
    }

    private func testApiError(withStatusCode statusCode: Int) async throws -> Data {
        let request = URLRequest(url: URL(string: "testurl.com")!)
        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        let testTransport = TestTransport(responseData: Data(), urlResponse: urlResponse!)
        let apiClient = ApiClient(transport: testTransport)
        do {
            return try await apiClient.send(request: request)
        } catch {
            throw error
        }
    }
}

// Extension found at:
// https://www.wwt.com/article/unit-testing-on-ios-with-async-await
extension XCTest {
    func XCTAssertThrowsError<T: Sendable>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (_ error: Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
