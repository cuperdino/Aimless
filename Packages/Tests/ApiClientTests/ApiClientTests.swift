import XCTest
@testable import ApiClient

final class ApiClientTests: XCTestCase {

    let apiClient = ApiClient()

    func testNotFoundError() async throws {
        let apiError = await getApiError(statusCode: 404)
        XCTAssertEqual(ApiError.notFound, apiError)
    }

    func testNotInternalServerError() async throws {
        let apiError = await getApiError(statusCode: 500)
        XCTAssertEqual(ApiError.interalServerError, apiError)
    }

    func testOtherError() async throws {
        let apiError = await getApiError(statusCode: 504)
        switch apiError {
        case .other: assert(true)
        default: assert(false)
        }
    }

    private func getApiError(statusCode: Int) async -> ApiError {
        let request = URLRequest(url: URL(string: "testurl.com")!)

        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )

        var apiError: ApiError!

        let testTransport = TestTransport(responseData: Data(), urlResponse: urlResponse!)
        do {
            _ = try await testTransport.send(request: request)
        } catch {
            apiError = error as? ApiError
        }
        return apiError
    }
}
