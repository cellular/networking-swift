import XCTest
import Networking

class ChainedPromiseTests: BaseRequestTestCase {

    func testThatResponseDataReturnsSuccessResultWithValidData() {

        // Given
        let expectation = self.expectation(description: "Request should succeed")
        let chainedExpectation = self.expectation(description: "Chained request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?
        var chainedResult: (dependency: HTTPBin, request: Request, response: Response)?

        // When
        let promise = client.request(.get) { $0.statusCode(248) }
        let chainedPromise = promise.map(in: .main) { _ in
            promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
            return self.client.request(.get) { $0.userAgent }
        }

        chainedPromise.response(filter: { _ in true }) { chainedResult = ($0, $1, $2); chainedExpectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
        XCTAssertNotNil(chainedResult, "Response should not be nil")
        XCTAssertNotNil(chainedResult?.response.data, "Data should not be nil")
    }
}
