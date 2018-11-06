import Foundation

/// HTTP method definitions. See https://tools.ietf.org/html/rfc7231#section-4.3
public enum Method: String {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
}
