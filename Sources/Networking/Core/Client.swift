import Foundation
import CELLULAR

/// Defines the type of dictionary and types that are acceptable as request parameters.
public typealias Parameters = [String: Any]

/// Defines the type of dictionary and types that aree acceptable as request header fields.
public typealias Header = [String: String]

/// The base class to send requests.
open class Client<T> where T: DependencyManager {

    /// The underlying provider of the actual networking functionality (Alamofire, AFNetworking, ...).
    fileprivate let provider: Provider

    /// The internal manager to be used once the client needs an updated dependency
    fileprivate let dependencyManager: T

#if !os(watchOS)
    /// The manager to listen for reachability changes on 0.0.0.0
    fileprivate let reachabilityManager: ReachabilityManager?
#endif

    /// Queue to stack up requests until the dependencies of the client have been resolved.
    fileprivate let queue = OperationQueue<Result<T.Value, Swift.Error>>()

    /// The authentication to be sent with each request created by the client.
    fileprivate var authentications: [String: Authentication] = [:]

    /// Initializes a proper Client instance with a known provider that is capable of sending networking requests.
    /// This intializer may be used by any provider extension within the project (internally) to create a public
    /// init that uses its provider out of the box.
    ///
    /// - Parameters:
    ///   - provider: The provider to be used internally within the client to send networking requests.
    ///   - manager: The `DependencyManager` that should be used for internal `Dependency` updates.
    public init(provider: Provider, manager: T = T()) {
        self.provider = provider
        self.dependencyManager = manager
#if !os(watchOS)
        self.reachabilityManager = provider.reachabilityManager(for: nil)
#endif
    }
}

// MARK: - Dependency Access

extension Client {

    /// Allows asynchronous access to the last resolved dependency of the client.
    ///
    /// - Parameters:
    ///   - success: Called with the last resolved dependency if successful.
    ///   - failed: Called with the error that occured while resolving last dependency.
    /// - Returns: Returns the operation that is created to access the dependency (or the error).
    @discardableResult
    public func dependency(success: @escaping (T.Value) -> Void, failure: ((Swift.Error) -> Void)? = nil) -> Operation {
        return queue.addOperation { result in
            switch result {
            case let .success(result): success(result)
            case let .failure(error): failure?(error)
            }
        }
    }
}

// MARK: - Routine

extension Client {

    /// Performs any task necessary to resolve the clients internal dependency. Needs to be called whenever the dependency
    /// is invalid (or not yet existing). Calling this method will suspend (if not already suspended) any outgoing request
    /// until the depdency has been resolved again and networking against the new set of data is possible.
    ///
    /// - Parameter handler: Optional Handler to pass to the networking client's internal dependency manager.
    public func performDependencyUpdateRoutine(_ handler: T.Handler) {

        /*
         The current Dependency gets immediately invalid once the update routine gets triggered. As a result, further
         outgoing requests would fail while the dependency is resolving. Therefore, the dependency queue needs to be
         suspended/invalidated before the instance of the client will trigger a new dependency update routine.
         */
        queue.invalidate()

        // Update/Resolve the client dependency while other requests are idling.
        dependencyManager.requiresDependencyUpdate(manager: provider, handler: handler, completion: queue.resolve)
    }
}

// MARK: - Reachability

#if !os(watchOS)
extension Client {

    /// Defines the generic (no specific host) reachability state of the client.
    public var reachabilityStatus: ReachabilityStatus {
        return reachabilityManager?.status ?? .unknown
    }

    /// Returns a `ReachabilityManager` instance that may be used to monitor the reachability state against given host.
    ///
    /// - Parameter host: The host used to evaluate network reachability. If `nil`, the manager will listen on 0.0.0.0
    /// - Returns: `ReachabilityManager` instance the may be used to monitor reachability state.
    public func reachabilityManager(for host: String? = nil) -> ReachabilityManager? {
        return provider.reachabilityManager(for: host)
    }
}
#endif

// MARK: - Authentication

extension Client {

    /// Authenticates each request created by the client with given credentials.
    ///
    /// - Parameters:
    ///   - host: Requests against given host will be authenticated with given `authentication`.
    ///   - authentication: The authentication to be used for each request within the client.
    public func authenticate(against host: String, authentication: Authentication) {
        authentications[host] = authentication
    }

    /// Invalidates the authentication associated with the client against given host.
    ///
    /// - Parameter host: Requests against given host will no longer be authentiated via the client.
    public func invalidateAuthenication(against host: String) {
        authentications[host] = nil
    }

    /// Authenticates each request addressed at the client with provided token in basic authentication.
    ///
    /// - Parameters:
    ///   - host: Requests against given host will be authenticated with given `credentials`.
    ///   - credentials: The credentials to be used for authorization.
    ///   - base64Encoded: Whether given credentials are already base64 encoded or needs to be done within the promise. Defaults to `true`.
    /// - Throws: Invalid credentials error if given string is not convertible as `Data` (`base64Encoded = false` only).
    public func authenticate(against host: String, usingBasic credentials: String, base64Encoded: Bool = true) throws {
        return authenticate(against: host, authentication: try BasicAuthentication(credentials: credentials, base64Encoded: base64Encoded))
    }

    /// Authenticates each request addressed at the client with provided user and password in basic authentication.
    ///
    /// - Parameters:
    ///   - host: Requests against given host will be authenticated with given `credentials`.
    ///   - user: The user name to be used for authorization.
    ///   - password: The password to be used for authorization.
    /// - Throws: Invalid credentials error if given user name and password are not convertible as `NSData`.
    public func authenticate(against host: String, user: String, password: String) throws {
        return authenticate(against: host, authentication: try BasicAuthentication(user: user, password: password))
    }

    /// Authenticates each request addressed at the client with provided token in JSON Web Token authentication.
    ///
    /// - Parameters:
    ///   - host: Requests against given host will be authenticated with given `credentials`.
    ///   - token: The token to be used for authorization.
    public func authenticate(against host: String, usingJWT token: String) {
        return authenticate(against: host, authentication: JWTAuthentication(token: token))
    }
}

// MARK: - Request

extension Client {

    /// Creates a request for the specified method, URL string, parameters, parameter encoding and headers.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - encoding: The parameter encoding. Defaults to `.url`.
    ///   - parameters: The parameters to be sent with the request. Defaults to `nil`.
    ///   - header: The HTTP headers to be sent with the request. Defaults to `nil`.
    ///   - path: The request path (relative to the baseURL) or the absolute URL string. Defaults to `nil`.
    /// - Returns: A new promise to send a request with specified method, URL, parameters, encoding and header.
    public func request(
        _ method: Method, encoding: ParameterEncoding = .url,
        parameters: ((T.Value) -> Parameters)? = nil,
        header: ((T.Value) -> Header)? = nil,
        path: @escaping (T.Value) -> URLStringConvertible) -> Promise<T.Value> {

        // Promise to send a request once the dependency is resolved
        return Promise(in: queue, operation: { [weak self] (promise, result) in

            // Resolve the promise against the new dependency or error
            switch result {
            case let .failure(error):
                promise.resolve(with: .failure(error))

            case let .success(dependency):
                // If `self`, the client instance, no longer exists, outgoing requests must/can not be continued.
                guard let this = self else {
                    return promise.resolve(with: .failure(Error.internalInconsistency("Managing client instance is no longer available.")))
                }

                // Whether or not the URL convertible is relative or absolute, it will be resolved against the base URL.
                // If the URL convertible is absolute in the first place, it will be kept the way it is. Relative paths
                // get the base URL prepended and will form an absolute URL that can be used to send requests.
                let path = path(dependency).urlString
                guard var url = URL(string: path, relativeTo: dependency.baseUrl) else {
                    let message = "Path \'\(path)\' relative to URL \'\(String(describing: dependency.baseUrl))\' could not be resolved."
                    return promise.resolve(with: .failure(Error.malformedUrl(message)))
                }

                // Resolve parameters and headers against the dependency
                var parameters = parameters?(dependency), header = header?(dependency)

                // Add the specified authentication(s) to the promise or (if unavailable) add the global host-based authentication(s)
                if let authentication = promise.authentication {
                    (url, header, parameters) = authentication.authenticate(url: url, header: header, parameters: parameters)
                } else if let host = url.host, let authentication = this.authentications[host] {
                    (url, header, parameters) = authentication.authenticate(url: url, header: header, parameters: parameters)
                }

                // Send a new request based on the resolved values and store it within the promise
                let request = this.provider.request(method,
                    url: url.absoluteString,
                    parameters: parameters,
                    encoding: encoding,
                    header: header
                )
                promise.resolve(with: request, using: dependency)
            }
        })
    }

    /// Creates a request to upload the given data to the specified URL including the given parameters
    ///
    /// - Parameters:
    ///   - data: Data to upload
    ///   - method: The HTTP method.
    ///   - encoding: The parameter encoding. Defaults to `.url`.
    ///   - parameters: The parameters to be sent with the request. Defaults to `nil`.
    ///   - header: The HTTP headers to be sent with the request. Defaults to `nil`.
    ///   - path: The request path (relative to the baseURL) or the absolute URL string. Defaults to `nil`
    ///   - progressHandler: Closure to receive upload progress updates
    /// - Returns: A new promise to upload the given data using the specified method, URL, parameters, encoding and header.
    public func upload(_ data: NetworkData, method: Method = .post, encoding: ParameterEncoding = .url,
                       parameters: ((T.Value) -> Parameters)? = nil,
                       header: ((T.Value) -> Header)? = nil,
                       path: @escaping (T.Value) -> URLStringConvertible,
                       progressHandler: ((Progress) -> Void)? = nil) -> Promise<T.Value> {

        return Promise(in: queue, operation: { [weak self] (promise, result) in
            // Resolve the promise against the new dependency or error
            switch result {
            case let .failure(error):
                promise.resolve(with: .failure(error))

            case let .success(dependency):
                // If `self`, the client instance, no longer exists, outgoing requests must/can not be continued.
                guard let this = self else {
                    return promise.resolve(with: .failure(Error.internalInconsistency("Managing client instance is no longer available.")))
                }

                // Whether or not the URL convertible is relative or absolute, it will be resolved against the base URL.
                // If the URL convertible is absolute in the first place, it will be kept the way it is. Relative paths
                // get the base URL prepended and will form an absolute URL that can be used to send requests.
                let path = path(dependency).urlString
                guard var url = URL(string: path, relativeTo: dependency.baseUrl) else {
                    let message = "Path \'\(path)\' relative to URL \'\(String(describing: dependency.baseUrl))\' could not be resolved."
                    return promise.resolve(with: .failure(Error.malformedUrl(message)))
                }

                // Resolve parameters and headers against the dependency
                var parameters = parameters?(dependency), header = header?(dependency)

                // Add the specified authentication(s) to the promise or (if unavailable) add the global host-based authentication(s)
                if let authentication = promise.authentication {
                    (url, header, parameters) = authentication.authenticate(url: url, header: header, parameters: parameters)
                } else if let host = url.host, let authentication = this.authentications[host] {
                    (url, header, parameters) = authentication.authenticate(url: url, header: header, parameters: parameters)
                }

                // Send a new request based on the resolved values and store it within the promise
                let request = this.provider.upload(data, url: url.absoluteString, method: method, header: header,
                                                   progressHandler: progressHandler)
                promise.resolve(with: request, using: dependency)
            }
        })
    }

    /// Creates a request to upload multipart form data according to RFC 2388 with the given data and parameters
    ///
    /// - Parameters:
    ///   - formData: Array of form data, will be joined to form the multipart data form
    ///   - method: The HTTP method.
    ///   - encoding: The parameter encoding. Defaults to `.url`.
    ///   - parameters: The parameters to be sent with the request. Defaults to `nil`.
    ///   - header: The HTTP headers to be sent with the request. Defaults to `nil`.
    ///   - path: The request path (relative to the baseURL) or the absolute URL string. Defaults to `nil`
    ///   - progressHandler: Closure to receive upload progress updates
    /// - Returns: A new promise to upload the given data using the specified method, URL, parameters, encoding and header.
    public func uploadMultipart(_ formData: [FormDataPart], method: Method = .post, encoding: ParameterEncoding = .url,
                                parameters: ((T.Value) -> Parameters)? = nil,
                                header: ((T.Value) -> Header)? = nil,
                                path: @escaping (T.Value) -> URLStringConvertible,
                                progressHandler: ((Progress) -> Void)? = nil) -> Promise<T.Value> {

        return Promise(in: queue, operation: { [weak self] (promise, result) in
            // Resolve the promise against the new dependency or error
            switch result {
            case let .failure(error):
                promise.resolve(with: .failure(error))

            case let .success(dependency):
                // If `self`, the client instance, no longer exists, outgoing requests must/can not be continued.
                guard let this = self else {
                    return promise.resolve(with: .failure(Error.internalInconsistency("Managing client instance is no longer available.")))
                }

                // Whether or not the URL convertible is relative or absolute, it will be resolved against the base URL.
                // If the URL convertible is absolute in the first place, it will be kept the way it is. Relative paths
                // get the base URL prepended and will form an absolute URL that can be used to send requests.
                let path = path(dependency).urlString
                guard var url = URL(string: path, relativeTo: dependency.baseUrl) else {
                    let message = "Path \'\(path)\' relative to URL \'\(String(describing: dependency.baseUrl))\' could not be resolved."
                    return promise.resolve(with: .failure(Error.malformedUrl(message)))
                }

                // Resolve parameters and headers against the dependency
                var parameters = parameters?(dependency), header = header?(dependency)

                // Add the specified authentication(s) to the promise or (if unavailable) add the global host-based authentication(s)
                if let authentication = promise.authentication {
                    (url, header, parameters) = authentication.authenticate(url: url, header: header, parameters: parameters)
                } else if let host = url.host, let authentication = this.authentications[host] {
                    (url, header, parameters) = authentication.authenticate(url: url, header: header, parameters: parameters)
                }

                // Send a new request based on the resolved values and store it within the promise
                this.provider.upload(multipartFormData: formData, url: url.absoluteString, method: method, header: header,
                                     encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    case .success(let result):
                        promise.resolve(with: result.request, using: dependency)
                    case .failure(let error):
                        promise.resolve(with: .failure(error))
                    }
                }, progressHandler: progressHandler)
            }
        })
    }
}
