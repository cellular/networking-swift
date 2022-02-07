import XCTest
import Networking

class ResponseTests: BaseRequestTestCase {

    func testThatRequestReturnsFailureOnNotExistingServer() {

        // Given
        let expectation = self.expectation(description: "Request should fail")
        var result: Networking.Error?

        // When
        let promise = client.request(.get) { $0.invalidServer }
        promise.response(filter: { _ in true }) { _,_,_  in XCTFail("Response should not exist.") }
        promise.failure { result = $0 as? Networking.Error; expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Error should not be nil")
        switch result {
        case let .requestFailed(message)?:
            XCTAssertNotNil(message, "Request failed message should not be nil")
        default:
            XCTFail("Failure request should not result in any other error than `.RequestFailed(_)`")
        }
    }
}

class ResponseDataTests: BaseRequestTestCase {

    func testThatResponseDataReturnsSuccessResultWithValidData() {

        // Given
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?

        // When
        let promise = client.request(.get) { $0.get }
        promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testThatResponseDataReturnsSuccessOnFailureResultWithValidData() {

        // Given
        let expectation = self.expectation(description: "Request should succeed with 404")
        var result: (dependency: HTTPBin, request: Request, response: Response)?

        // When
        let promise = client.request(.get) { $0.invalidEndpoint }
        promise.response(filter: [404]) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
        XCTAssert(result?.response.statusCode == 404, "Response should return with status code 404")
    }

    func testDataUpload() {
        // Given
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?
        let data = "Test Data".data(using: .utf8)!

        // When
        let promise = client.upload(.data(data), path: { $0.post })
        promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testFileUpload() {
        // Given
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?
        let fileURL = Bundle.module.url(forResource: "a", withExtension: "png")!

        // When
        let promise = client.upload(.fileURL(fileURL), path: { $0.post })
        promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testFileUploadPut() {
        // Given
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?
        let fileURL = Bundle.module.url(forResource: "a", withExtension: "png")!

        // When
        let promise = client.upload(.fileURL(fileURL), path: { $0.put })
        promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testFileUploadProgress() {
        // Given
        let expectation = self.expectation(description: "Request should call progress handler")
        expectation.assertForOverFulfill = false // avoids crash when filfill

        let fileURL = Bundle.module.url(forResource: "b", withExtension: "png")!

        // When
        let promise = client.upload(.fileURL(fileURL), path: { $0.post }, progressHandler: { _ in
            expectation.fulfill()
        })
        promise.response(filter: { _ in true }) { (_: HTTPBin, _: Request, _: Response) in }

        // Then
        waitForExpectations(timeout: timeout, handler: nil)

    }

    func testInputStreamUpload() {
        // Given
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?
        let fileURL = Bundle.module.url(forResource: "a", withExtension: "png")!
        let data = try! Data(contentsOf: fileURL)
        let inputStream = InputStream(data: data)

        // When
        let promise = client.upload(.inputStream(inputStream, length: UInt64(data.count)), path: { $0.post })
        promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testMultipartFormUpload() {
        // Given
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?
        let fileURL = Bundle.module.url(forResource: "a", withExtension: "png")!
        let data = try! Data(contentsOf: fileURL)

        // When
        let formData = FormDataPart(data: .data(data), name: "abc")

        let promise = client.uploadMultipart([formData], path: { $0.post })
        promise.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }
}
