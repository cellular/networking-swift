import XCTest
@testable import Networking

class OperationQueueTests: XCTestCase {

    func testDefaultValue() {
        let queue = Networking.OperationQueue<Int>()
        XCTAssertNil(queue.value, "Queue must not be initialized with default (none-nil) value")
    }

    func testDefaultSuspended() {
        let queue = Networking.OperationQueue<Int>()
        XCTAssertTrue(queue.isSuspended, "Queue must start suspended")
    }

    func testResolveSuspended() {
        let queue = Networking.OperationQueue<Int>()
        queue.resolve(with: 1)
        XCTAssertFalse(queue.isSuspended, "Queue must be operational (not suspended) after resolve")
    }

    func testResolveValue() {
        let value = 1
        let queue = Networking.OperationQueue<Int>()
        queue.resolve(with: value)
        XCTAssert(queue.value == value, "Queue must have its resolving value stored.")
    }

    func testInvalidateSuspended() {
        let queue = Networking.OperationQueue<Int>()
        queue.resolve(with: 1)
        queue.invalidate()
        XCTAssertTrue(queue.isSuspended, "Queue must be suspended once invalidated.")
    }

    func testInvalidateValue() {
        let queue = Networking.OperationQueue<Int>()
        queue.resolve(with: 1)
        queue.invalidate()
        XCTAssertNil(queue.value, "Queue value must be have its value removed once invalidated.")
    }

    func testOperationValue() {

        // Given
        let value = 1
        let queue = Networking.OperationQueue<Int>()
        let expectation = self.expectation(description: "Queue operations must receive resolve value.")

        // When
        var received: Int?
        _ = queue.addOperation({ received = $0; expectation.fulfill() })
        queue.resolve(with: value)

        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssert(received == value, "Queue must have its stored value passed to all operations.")
    }

    func testOperationCancel() {

        // Given
        let value = 1
        let queue = Networking.OperationQueue<Int>()

        // When
        var receivedCanceled: Int?
        _ = queue.addOperation({ receivedCanceled = $0; XCTFail("Canceled operation must not be called.") })
        queue.cancelAllOperations()
        queue.resolve(with: value)

        // Then
        XCTAssertNil(receivedCanceled, "Canceled operation must not be called and never assigned a value.")
    }

    func testOperationCancelResume() {

        // Given
        let value = 1
        let queue = Networking.OperationQueue<Int>()
        let expectation = self.expectation(description: "Operations in resumed queue must receive resolve value.")

        // When
        var receivedCanceled: Int?, received: Int?
        _ = queue.addOperation({ receivedCanceled = $0; XCTFail("Canceled operation must not be called.") })
        queue.cancelAllOperations()
        _ = queue.addOperation({ received = $0; expectation.fulfill() })
        queue.resolve(with: value)

        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssertNil(receivedCanceled, "Canceled operation must not be called and never assigned a value.")
        XCTAssert(received == value, "Resumed queue must have its stored value passed to all operations.")
    }
}
