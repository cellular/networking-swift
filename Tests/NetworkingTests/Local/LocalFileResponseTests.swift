import XCTest
import Networking

class LocalFileRequestTestCase: XCTestCase {

    // Timeout before any request/response related test will be marked as failed
    let timeout: TimeInterval = 3.0

    // Client to perform networking tasks
    var client: Client<HTTPBin>?

    /**
     Setup method called before the invocation of each test method in the class.

     Instantiates a completly new client for each test method.
     */
    override func setUp() {
        super.setUp()
        let definition = LocalFileDefinition(bundle: Bundle.module, fileName: "LocalFileDefinition", placeholders: ["%@$1" : "bar"])
        do {
            client = try Client(provider: LocalFileProvider(definition: definition))
        } catch let error {
            print(error)
        }
        client?.performDependencyUpdateRoutine(())
    }
}

class LocalFileResponseTests: LocalFileRequestTestCase {

    func testLocalResponseWithInMemoryMapping() {
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?

        let provider = LocalFileProvider(mapping: [
            LocalFileMap(url: "https://foo.de/bar", fileName: "bar")
        ], bundle: Bundle.module)
        client = Client(provider: provider)
        client?.performDependencyUpdateRoutine(())

        let promise = client?.request(.get) { _ in "https://foo.de/bar" }
        promise?.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testLocalResponseWithIncorrectInMemoryMapping() {
        let expectation = self.expectation(description: "Request should fail")

        let provider = LocalFileProvider(mapping: [
            LocalFileMap(url: "https://foo.de/bar", fileName: "foo")
            ], bundle: Bundle.module)
        client = Client(provider: provider)
        client?.performDependencyUpdateRoutine(())

        let promise = client?.request(.get) { _ in "https://foo.de/bar" }
        promise?.failure { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testLocalResponseWithValidFile() {
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?

        let promise = client?.request(.get) { _ in "https://foo.de/bar" }
        promise?.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testLocalResponseWithInvalidFile() {
        let expectation = self.expectation(description: "Request should fail with 404")
        var failureError: Networking.Error?

        let promise = client?.request(.get) { url in "https://foo.de/bar/nothing" }
        promise?.failure { (error) in
            failureError = error as? Networking.Error
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertNotNil(failureError, "Error should not be nil")
        XCTAssertNil(failureError?.response?.data, "Data must be nil")
        XCTAssert(failureError?.response?.statusCode == 404, "Response should return with status code 404")
    }

    func testLocalResponseWithValidWildcardFile() {
        let expectation = self.expectation(description: "Request should succeed")
        var result: (dependency: HTTPBin, request: Request, response: Response)?

        let promise = client?.request(.get) { url in "https://cellular.de/news/category/tech/today" }
        promise?.response(filter: { _ in true }) { result = ($0, $1, $2); expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result?.response.data, "Data should not be nil")
    }

    func testLocalResponseWithInvalidWildcardFile() {
        let expectation = self.expectation(description: "Request should fail with 404")
        var failureError: Networking.Error?

        let promise = client?.request(.get) { url in "https://notfound.cellular.de/news/category/tech/today" }
        promise?.failure { (error) in
            failureError = error as? Networking.Error
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertNotNil(failureError, "Error should not be nil")
        XCTAssertNil(failureError?.response?.data, "Data must be nil")
        XCTAssert(failureError?.response?.statusCode == 404, "Response should return with status code 404")
    }

    func testThrowOfErrorWithInvalidJSON() {
        let definition = LocalFileDefinition(bundle: Bundle.module, fileName: "BrokenLocalFileDefinition", placeholders: [String: String]())
        var parsingError: Swift.Error?
        do {
            client = try Client(provider: LocalFileProvider(definition: definition))
        } catch let error {
            parsingError = error
        }
        XCTAssertNotNil(parsingError, "Error should not be nil")
        if let decodingError = parsingError as? DecodingError,
            case let DecodingError.keyNotFound(key, _) = decodingError {
            XCTAssert(key.stringValue == "statusCode", "Missing CodingKey should be \"statusCode\"")
        }
    }
}
