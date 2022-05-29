import XCTest
@testable import ApiClient

final class ApiClientTests: XCTestCase {

    let apiClient = ApiClient()

    func testFetchTodos() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let posts = try await apiClient.fetchTodos()
        print(posts)
    }

    func testFetchUsers() async throws {
        let users = try await apiClient.fetchUsers()
        print(users)
    }
}
