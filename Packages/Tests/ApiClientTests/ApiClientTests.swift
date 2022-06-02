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

    private func testApiError(withStatusCode statusCode: Int) async throws -> Data {
        let request = URLRequest(url: URL(string: "testurl.com")!)
        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        let testTransport = TestTransport(responseData: Data(), urlResponse: urlResponse!)
        do {
            return try await testTransport.send(request: request)
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
