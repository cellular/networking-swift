import Foundation

/// Represents a response received as part of a networking request. It exposes the header fields (`header`),
/// the HTTP status code (`statusCode`) as well as the optional body data (`data`)
public protocol Response {

    /// The response's foundation representation as received from the server.
    var response: HTTPURLResponse { get }

    /// The data received within the response body (if any).
    var data: Data? { get }
}

/// Convenience access property definitions
extension Response {

    /// The HTTP status code of the response.
    public var statusCode: Int { return response.statusCode }

    /// All HTTP header fields of the response.
    public var allHeaderFields: [AnyHashable: Any] { return response.allHeaderFields }
}
