import Foundation

import XCTest
@testable import Networking

class HashablePromiseTests: BaseRequestTestCase {

    func testSucceededPromises() {
        var promises: [Promise<HTTPBin>: Date] = [:]
        for _ in 0..<5 {
            // Given
            let expectation = self.expectation(description: "Request should succeed")
            var result: (dependency: HTTPBin, request: Request, response: Response)?

            // When
            let promise = client.request(.get) { $0.get }
            let beforeHash = promise.hashValue
            promises[promise] = Date()

            promise.response(filter: { _ in true }) {
                result = ($0, $1, $2)
                expectation.fulfill()
            }
            waitForExpectations(timeout: timeout, handler: nil)
            let afterHash = promise.hashValue

            // Then
            XCTAssert(beforeHash == afterHash)
            XCTAssertNotNil(result, "Response should not be nil")
            XCTAssertNotNil(result?.response.data, "Data should not be nil")
        }
        XCTAssert(promises.count == 5)
    }

    func testCancelledPromises() {
        var promises: [Promise<HTTPBin>: Date] = [:]
        for _ in 0..<5 {
            // When
            let promise = client.request(.get) { $0.get }
            let beforeHash = promise.hashValue
            promises[promise] = Date()
            promise.response(filter: { _ in true }) { _,_,_ in }
            promise.cancel()
            let afterHash = promise.hashValue

            // Then
            XCTAssert(beforeHash == afterHash)
        }
        XCTAssert(promises.count == 5)
    }

}
