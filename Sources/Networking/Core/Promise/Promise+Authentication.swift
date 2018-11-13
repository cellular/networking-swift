import Foundation

public extension Promise {

    /// Authenticates the request associated with the promise with given credentials.
    ///
    /// - Parameter authentication: The authentication to be used for the request within the promise.
    /// - Returns: The promise to be authenticated with given credentials.
    public func authenticate(_ authentication: Authentication) -> Promise {
        self.authentication = authentication
        return self
    }

    /// Authenticates the request of the promise with provided token in basic authentication.
    ///
    /// - Parameters:
    ///   - credentials: The credentials to be used for authorization.
    ///   - base64Encoded: Whether given credentials are already base64 encoded
    ///                    or needs to be done within the promise. Defaults to `true`.
    /// - Returns: The authorized promise (and its request).
    /// - Throws: Invalid argument error if credentials are not convertible as `NSData` (`base64Encoded = false` only).
    public func authenticate(usingBasic credentials: String, base64Encoded: Bool = true) throws -> Promise {
        return try authenticate(BasicAuthentication(credentials: credentials, base64Encoded: base64Encoded))
    }

    /// Authenticates the request of the promise with provided user and password in basic authentication.
    ///
    /// - Parameters:
    ///   - user: The user name to be used for authorization.
    ///   - password: The password to be used for authorization.
    /// - Returns: The authorized promise (and its request).
    /// - Throws: Invalid argument error if credentials are not convertible as `Data`.
    public func authenticate(user: String, password: String) throws -> Promise {
        return try authenticate(BasicAuthentication(user: user, password: password))
    }

    /// Authenticates the request of the promise with provided token in JSON Web Token authentication.
    ///
    /// - Parameter token: The token to be used for authorization.
    /// - Returns: The authorized promise (and its request).
    public func authenticate(usingJWT token: String) -> Promise {
        return authenticate(JWTAuthentication(token: token))
    }
}
