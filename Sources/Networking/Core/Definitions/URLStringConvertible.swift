import Foundation

// MARK: - Generic

/// Defines a protocol to be implemented by objects that are convertible to a partial URL component (e.g. path) or an absolute URL.
public protocol URLStringConvertible {

    /// The relative or absolute URL component that is represented by `self`.
    var urlString: String { get }
}

// MARK: - Common

extension URL: URLStringConvertible {

    /// The absolute URL of `self`.
    public var urlString: String { return absoluteString }
}

extension String: URLStringConvertible {

    /// The relative or absolute URL component that is represented by `self`.
    public var urlString: String { return self }
}
