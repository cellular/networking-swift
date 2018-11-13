import XCTest
import Networking

class RetainedPromiseTests: BaseRequestTestCase {

    func testPromiseRetaining() {

        // Given
        let expectation = self.expectation(description: "Request must finish")
        var result: (dependency: HTTPBin, request: Request, response: Response)?

        // When
        client
            .request(.get) { $0.get }
            .response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
            .retained()

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testPromiseReleaseOnSuccess() {

        // Given
        let expectation = self.expectation(description: "Request must finish")

        // When
        weak var promise = client
            .request(.get) { $0.get }
            .response(in: .main, filter: { _ in true }) { (_: HTTPBin, _, _) in expectation.fulfill() }
            .retained()

        XCTAssertNotNil(promise, "Promise must not be nil")
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNil(promise, "Promise must be nil.")
    }

    func testPromiseReleaseOnFailure() {

        // Given
        let expectation = self.expectation(description: "Request must fail")

        // When
        weak var promise = client
            .request(.get) { $0.invalidServer }
            .failure { _ in expectation.fulfill() }
            .retained()

        XCTAssertNotNil(promise, "Promise must not be nil")
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNil(promise, "Promise must be nil.")
    }
}
