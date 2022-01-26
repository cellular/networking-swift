import Foundation

/// Defines all errors that may occur within the request chain of the `Networking`.
///
/// - unsolvedDependency: Indicates an error due to an unsolved dependency update.
/// - malformedUrl: Indicates an error due to an invalid request URL.
/// - invalidCredentials: Indicates an error due to invalid credentials (within authorization).
/// - requestFailed: Indicates an error due to failed request (e.g. timeout) - request available.
/// - serializationFailed: Indicates an error due to an invalid deserialization.
/// - clientError: Indicates a client error on the request (4xx) - response available.
/// - serverError: Indicates a server error on the request (5xx) - response available.
public enum Error: Swift.Error {
    case unsolvedDependency(String)
    case internalInconsistency(String)
    case malformedUrl(String)
    case invalidCredentials(String)
    case requestFailed(Request, String)
    case serializationFailed(String)
    case clientError(Request, Response)
    case serverError(Request, Response)
}

// MARK: Convenience

extension Error {

    /// The response received and determined as error. `nil` if a response has not been received (e.g. timeout).
    public var response: Response? {
        switch self {
        case let .clientError(_, response): return response
        case let .serverError(_, response): return response
        default: return nil
        }
    }

    /// The status code of the response. `nil` if a response has not been received (e.g. timeout).
    public var statusCode: Int? {
        return response?.statusCode
    }
}

// MARK: Convertible

extension Error: CustomDebugStringConvertible, CustomStringConvertible {

    /// A textual representation of `self`.
    public var description: String {
        return debugDescription // As of now, there is no "shorter" description available.
    }

    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case let .unsolvedDependency(error):
            return "[Networking Error] Could not resolve dependency.\nDescription: \(error)"
        case let .internalInconsistency(error):
                return "[Networking Error] Internal inconsistency.\nDescription: \(error)"
        case let .malformedUrl(error):
            return "[Networking Error] Could not form a valid request URL.\nDescription: \(error)"
        case let .invalidCredentials(error):
            return "[Networking Error] Authorization failed.\nDescription: \(error)"
        case let .requestFailed(error, _):
            return "[Networking Error] Request failed.\nDescription: \(error)"
        case let .serializationFailed(error):
            return "[Networking Error] Serialization failed.\nDescription: \(error)"
        case let .clientError(request, response):
            return "[Networking Error] Request failed with status code \(response.statusCode) (CLIENT error)."
                + "\n\n> Request: \(request)\n\n> Response: \(response)"
        case let .serverError(request, response):
            return "[Networking Error] Request failed with status code \(response.statusCode) (SERVER Error)."
                + "\n\n> Request: \(request)\n\n > Response: \(response)"
        }
    }
}
