import XCTest
@testable import ApiClient

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

    func testApiResponseMapping() async throws {
        let userData = try! JSONEncoder().encode([User(id: 1, name: "Bob", username: "bob", email: "bob@email.com")])

        let testTransport = TestTransport(responseData: userData, urlResponse: .valid)
        let apiClient = ApiClient(transport: testTransport)

        let user: [User] = try await apiClient.send(request: .getUsers)
        XCTAssertEqual(user.first!.name, "Bob")
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
        let users = [User(id: 1, name: "Bob", username: "bob", email: "bob@email.com")]
        let postUsersRequest = URLRequest.postUsers(users: users)
        let data = try! JSONEncoder().encode([User(id: 1, name: "Bob", username: "bob", email: "bob@email.com")])

        XCTAssertEqual(postUsersRequest.url, URL(string: "https://jsonplaceholder.typicode.com/users")!)
        XCTAssertEqual(postUsersRequest.httpBody, data)
        XCTAssertEqual(postUsersRequest.httpMethod, HTTPMethod.post)
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
