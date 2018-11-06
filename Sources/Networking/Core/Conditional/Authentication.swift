import Foundation

/// Defines the values of which either one, a combination of some or even all of them, needs to be authenticated before sending the request.
public typealias Authenticatables = (url: URL, header: Header?, parameters: Parameters?)

// MARK: - Generic

/// Defines a protocol to implemented by classes or structs that should act as request authentication.
public protocol Authentication {

    /// Authenticates one of the provided parameters (or a mix of some/all of them) and returns the new values.
    /// Returning values will be used to be passed to a request (that needs authorization), before its been sent.
    ///
    /// - Parameters:
    ///   - url: The URL to be addressed by the request and eventually be modified for authorization.
    ///   - header: The header to be sent with the request and eventually be modified for authorization.
    ///   - parameters: The parameters to be sent with the request and eventually be modified for authorization.
    /// - Returns: The authenticated values of which either one, a combination of some or even all of them, have credentials attached.
    func authenticate(url: URL, header: Header?, parameters: Parameters?) -> Authenticatables
}

// MARK: - Specific

/// Defines a protocol to implemented by classes or structs that send authentication credentials using the request headers.
public protocol HeaderAuthentication: Authentication {

    /// The header field that is utilized within the API to identify authorization (defaults to "Authorization")
    var headerField: String { get }

    /// The identifier to be passed with the credentials in the value field of the header.
    var identifier: String { get }

    /// The credentials (e.g. token) to be passed with the identifier in the value field of the header.
    var credentials: String { get }

    /// Passes the request header as parameter which should be modified by attaching the authentication header field.
    ///
    /// - Parameter header: The request header to attach the authentication header field.
    /// - Returns: The request header with the authentication header field of `self` attached.
    func authenticate(header: Header?) -> Header
}

extension HeaderAuthentication {

    /// Most header authentication utilizes the "Authorization" field, so each HeaderAuthentication defaults to this.
    public var headerField: String { return "Authorization" }

    /// Overrides the `Authentication` provided method with only the header manipulation.
    ///
    /// - Parameters:
    ///   - url: The URL of the request. Remains untouched within a header authentication manipulation.
    ///   - header: The header to be sent with the request. The only value to be modified upon authentication.
    ///   - parameters: The parameters to be sent with the request. Remain untouched within a header authentication manipulation.
    /// - Returns: The values passed to the method of which only the headers will be modified to incorporate the authorization credentials.
    public func authenticate(url: URL, header: Header?, parameters: Parameters?) -> Authenticatables {
        return (url: url, header: authenticate(header: header), parameters: parameters)
    }

    /// Provides the default implementation for header based authentication (<headerField>: <identifier> <credentials>)
    ///
    /// - Parameter header: The header fields to which to add the autorization header field of `self`.
    /// - Returns: The header as passed to the method including the added authorization credentials.
    public func authenticate(header: Header?) -> Header {
        var authenticationHeader = header ?? [:]
        authenticationHeader[headerField] = "\(identifier) \(credentials)"
        return authenticationHeader
    }
}

/// Defines a protocol to be implemented by classes that manages URL authentication.
public protocol URLAuthentication: Authentication {

    /// Passes the request URL as parameter which should be modified by attaching the authentication details.
    ///
    /// - Parameter url: The request URL to be modified and to attach the authentication details.
    /// - Returns: The request URL with the authentication details of `self`.
    func authenticate(url: URL) -> URL
}

extension URLAuthentication {

    /// Overrides the `Authentication` provided method with only the URL manipulation.
    ///
    /// - Parameters:
    ///   - url: The URL of the request. The only value to be modified upon authentication
    ///   - header: The header to be sent with the request. Remains untouched within a URL authentication manipulation.
    ///   - parameters: The parameters to be sent with the request. Remains untouched within a URL authentication manipulation.
    /// - Returns: The values passed to the method of which only the URL will be modified to contain the authorization credentials.
    public func authenticate(url: URL, header: Header?, parameters: Parameters?) -> Authenticatables {
        return (url: authenticate(url: url), header: header, parameters: parameters)
    }
}

// MARK: - Common

/// Defines basic authentication using a user name and password (https://en.wikipedia.org/wiki/basic_access_authentication).
public struct BasicAuthentication: HeaderAuthentication {

    /// The identifier of a basic authentication ("Basic")
    public let identifier: String = "Basic"

    /// The credentials as given within the any of the initializers.
    public let credentials: String

    /// Initializes a new instance of `Self` using the given credentials for authorization.
    ///
    /// - Parameters:
    ///   - credentials: The credentials to be used (as is) for authorization.
    ///   - base64Encoded: Whether given credentials are already base64 encoded or needs to be done within the promise. Defaults to `true`.
    /// - Throws: Invalid credentials error if given string ist not convertible as `NSData` (`base64Encoded = false` only).
    public init(credentials: String, base64Encoded: Bool = true) throws {
        // If the string is already encoded, return early with only the credentials stored.
        guard !base64Encoded else { self.credentials = credentials; return }
        // Otherwise, convert the string into a base64 version and throw on error (store on success).
        guard let data = credentials.data(using: .utf8) else {
            throw Error.invalidCredentials("Given basic authentication credential is not a valid UTF8-strings.")
        }
        self.credentials = data.base64EncodedString(options: [])
    }

    /// Initializes a new instance of `Self` using the given username and passworf for authorization.
    ///
    /// - Parameters:
    ///   - user: The user name to be used for authorization.
    ///   - password: The password to be used for authorization.
    /// - Throws: Invalid credentials error if given username and password are not convertible as `NSData`.
    public init(user: String, password: String) throws {
        guard let data = "\(user):\(password)".data(using: .utf8) else {
            throw Error.invalidCredentials("Given basic authentications username and password are not valid UTF8-strings.")
        }
        credentials = data.base64EncodedString(options: [])
    }
}

/// Defines a JSON Web Token authentication. (https://jwt.io)
public struct JWTAuthentication: HeaderAuthentication {

    /// The default identifier for JWT based authentication ("Bearer")
    public let identifier: String = "Bearer"

    /// The token to be passed alongside the identifier within the header.
    public let credentials: String

    /// Initializes a new instance of `Self` using the given token for authorization.
    ///
    /// - Parameter token: The token to be passed alongside the identifier (Bearer) within the header.
    public init(token: String) {
        credentials = token
    }
}
