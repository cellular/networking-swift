import XCTest
import Networking
import Alamofire
import CELLULAR

/*

Almost all tests within `CellulerNetworkingTests` will utilize http://httpbin.org/ in order
to retrieve and validate request, response and their (de-)serialization processes.

NOTE: Dependendy and DependendyManager must be seperate classes within an application code!
HTTPBin is not a showcase for how it should be done, but it is easier for testing purposes.

*/

struct HTTPBin: Dependency, DependencyManager {

    typealias Value = HTTPBin

    /// The HTTPBin dependency is its own resolve manager
    typealias Dependency = HTTPBin

    /// These test do not utilize any handler
    typealias Handler = Void

    /// httpbin.org covers all kinds of HTTP scenarios and allows HTTP library testing.
    let baseUrl = URL(string: "http://httpbin.org/")

    /// Returns user-agent.
    let userAgent = "/user-agent"

    /// Returns GET data.
    let get = "/get"

    /// POST endpoint
    let post = "/post"

    /// PUT endpoint
    let put = "/put"

    /// Returns given HTTP Status code.
    var statusCode: ((Int) -> String) = { "/status/\($0)" }

    /// Returns an endpoint that does not exist (on a server that does exist).
    let invalidEndpoint = "/this/endpoint/does/not/exist"

    /// Returns an invalid server address.
    let invalidServer = "https://invalid-url-here.omg/this/server/does/not/exist"

    /// The dependency succeeds with the above defined HTTPBin at any time. This must NOT be used for dependency tests.
    func requiresDependencyUpdate(manager: Provider, handler: Void, completion: @escaping (Swift.Result<HTTPBin, Swift.Error>) -> Void) {
        return completion(.success(self))
    }
}

extension HTTPBin: Hashable {

    static func == (lhs: HTTPBin, rhs: HTTPBin) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(baseUrl)
        hasher.combine(userAgent)
        hasher.combine(get)
        hasher.combine(post)
        hasher.combine(put)
        hasher.combine(invalidEndpoint)
        hasher.combine(invalidServer)
    }
}

// MARK: - Base Test Case

class BaseRequestTestCase: XCTestCase {

    // Timeout before any request/response related test will be marked as failed
    let timeout: TimeInterval = 30.0

    // Client to perform networking tasks
    var client: Client<HTTPBin>!

    /**
     Setup method called before the invocation of each test method in the class.

     Instantiates a completly new client for each test method.
     */
    override func setUp() {
        super.setUp()
        client = Client(provider: Session(configuration: URLSessionConfiguration.default))
        client.performDependencyUpdateRoutine(())
    }
}
