import Alamofire
import Foundation
import CELLULAR

// MARK: - Definitions

/// Maps the client internal `Method` definitions to the Alamofire specific `Method`.
extension Networking.Method {
    internal var alamofire: Alamofire.HTTPMethod {
        switch self {
        case .options: return .options
        case .get:     return .get
        case .head:    return .head
        case .post:    return .post
        case .put:     return .put
        case .patch:   return .patch
        case .delete:  return .delete
        case .trace:   return .trace
        case .connect: return .connect
        }
    }
}

/// Maps the client internal `Header` definitions to the Alamofire specific `HTTPHeaders`.
extension Networking.Header {
    internal var alamofire: Alamofire.HTTPHeaders {
        .init(self)
    }
}

/// Wrapper around Alamofire Encoding to be used by the Networking Encoding
private struct CustomEncoding: Alamofire.ParameterEncoding {

    /// The handler to use for encoding
    private let handler: (URLRequest, [String: Any]?) -> (URLRequest, NSError?)

    /// Initializes a new instance of Self using provided handler.
    ///
    /// - Parameter handler: The handler to use for encoding
    init(handler: @escaping (URLRequest, [String: Any]?) -> (URLRequest, NSError?)) {
        self.handler = handler
    }

    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// - Parameters:
    ///   - urlRequest: The request to have parameters applied.
    ///   - parameters: The parameters to apply.
    /// - Returns: The encoded request.
    /// - Throws: An `AFError.parameterEncodingFailed` error if encoding fails.
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        guard let urlRequest = urlRequest as? URLRequest else { throw AFError.parameterEncodingFailed(reason: .missingURL) }
        let (request, error) = handler(urlRequest, parameters)
        guard let throwableError = error else { return request }
        throw throwableError
    }
}

/// Maps the client internal `Encoding` definitions to the Alamofire specific `ParameterEncoding`.
extension Networking.ParameterEncoding {
    internal var alamofire: Alamofire.ParameterEncoding {
        switch self {
        case .json: return JSONEncoding.default
        case .url:  return URLEncoding.httpBody
        case .urlEncodedInUrl: return URLEncoding.queryString
        case let .custom(handler): return CustomEncoding(handler: handler)
        }
    }
}

// MARK: - Messages

/// Allows Alamofire.Requests to be used as CellularNetworking related Request objects.
extension Alamofire.DataRequest: Networking.Request {

    /// Updates the managing promise once to the response have finished downloading or an error occured.
    /// The provider request **must** call the given handler once it determined the final state of the request.
    ///
    /// - Parameter completion: Must be called within the provider request once it completed (either successfull or due to a failure).
    public func onCompleted(_ completion: @escaping (Swift.Result<Networking.Response, Swift.Error>) -> Void) {
        validate(statusCode: Int.min..<Int.max).validate(contentType: ["*/*"]).response { dataResponse in

            // Only a valid response object will allow this request to be handled as "successful"
            guard let response = dataResponse.response else {
                return completion(.failure(Error.requestFailed(self, "\(String(describing: dataResponse.error))")))
            }
            // Success. Request received a response - data is optional (not necessary for success).
            completion(.success(AlamofireResponse(response: response, data: dataResponse.data)))
        }
    }
}

/// Alamofire does not have a response object as defined within the networking protocol. This is a dedicated but hidden struct.
private struct AlamofireResponse: Networking.Response {

    /// The response received from the server, if any.
    var response: HTTPURLResponse

    /// The data received within the response body (if any).
    var data: Data?
}

// MARK: - Provider

extension MultipartFormData {

    /// convenience bridging method which offers optional parameter handling
    public func append(_ fileURL: URL, withName name: String, fileName: String?, mimeType: String?) {
        if let fileName = fileName, let mimeType = mimeType {
            append(fileURL, withName: name, fileName: fileName, mimeType: mimeType)
        } else {
            append(fileURL, withName: name)
        }
    }

    /// convenience bridging method which offers optional parameter handling
    public func append(_ stream: InputStream, withLength length: UInt64, name: String, fileName: String?, mimeType: String?) {
        if let fileName = fileName, let mimeType = mimeType {
            append(stream, withLength: length, name: name, fileName: fileName, mimeType: mimeType)
        } else {
            append(stream, withLength: length, headers: [:])
        }
    }
}

/// Allows the alamofire manager to be used as a client provider, managing requests directed through the client.
extension Session: Provider {

    public func upload(multipartFormData: [FormDataPart], url: String, method: Method, header: Header?,
                       progressHandler: ((Progress) -> Void)?) -> Request {
        return upload(multipartFormData: { (formData) in
            multipartFormData.forEach { dataPart in
                switch dataPart.data {
                case .data(let data):
                    formData.append(data, withName: dataPart.name, fileName: dataPart.fileName, mimeType: dataPart.mimeType)
                case .fileURL(let fileURL):
                    formData.append(fileURL, withName: dataPart.name, fileName: dataPart.fileName, mimeType: dataPart.mimeType)
                case .inputStream(let inputStream, let length):
                    formData.append(inputStream, withLength: length, name: dataPart.name, fileName: dataPart.fileName,
                                    mimeType: dataPart.mimeType)
                }
            }
        }, to: url, method: method.alamofire, headers: header?.alamofire)
    }

    public func upload(_ data: NetworkData, url: String, method: Method, header: Header?, progressHandler: ((Progress) -> Void)?)
        -> Request {
            switch data {
            case .data(let data):
                return upload(data, to: url, method: method.alamofire, headers: header?.alamofire)
                    .uploadProgress(closure: progressHandler ?? { _ in })
            case .fileURL(let fileURL):
                return upload(fileURL, to: url, method: method.alamofire, headers: header?.alamofire)
                    .uploadProgress(closure: progressHandler ?? { _ in })
            case .inputStream(let inputStream, _):
                return upload(inputStream, to: url, method: method.alamofire, headers: header?.alamofire)
                    .uploadProgress(closure: progressHandler ?? { _ in })
            }
    }

    public func request(_ method: Networking.Method, url: String, parameters: Parameters?,
                        encoding: ParameterEncoding, header: Header?) -> Networking.Request {
        return request(url, method: method.alamofire, parameters: parameters, encoding: encoding.alamofire, headers: header?.alamofire)
    }

#if !os(watchOS)
    /// Returns a `ReachabilityManager` instance that may be used to monitor the reachability state against given host.
    ///
    /// - Parameter host: The host used to evaluate network reachability.
    /// - Returns: `ReachabilityManager` instance the may be used to monitor reachability state.
    public func reachabilityManager(for host: String?) -> ReachabilityManager? {
        return AlamofireReachabilityManager(host: host)
    }
#endif
}

#if !os(watchOS)

// MARK: - Reachability

private extension NetworkReachabilityManager.NetworkReachabilityStatus {

    /// Converts the alamofire networking reachability status into its `CellularNetworking` counterpart.
    var converted: ReachabilityStatus {
        switch self {
        case .unknown: return .unknown
        case .notReachable: return .notReachable
        case .reachable(let type):
            switch type {
            case .ethernetOrWiFi:
                return .reachable(.ethernetOrWiFi)
            case .cellular:
                return .reachable(.cellular)
            }
        }
    }
}

private final class AlamofireReachabilityManager: ReachabilityManager {

    /// The current reachability status for defined host or generic reachability, if host not specified.
    var status: ReachabilityStatus { return manager.status.converted }

    /// A closure executed when the network reachability status of `self` changes.
    var listener: ReachabilityManager.Listener?

    /// The actual listener, wrapped within `self`.
    private let manager: NetworkReachabilityManager

    init?(host: String?) {
        if let host = host, let manager = NetworkReachabilityManager(host: host) {
            self.manager = manager
        } else if let manager = NetworkReachabilityManager() {
            self.manager = manager
        } else {
            return nil
        }
        manager.startListening { [weak self] (status) in
            self?.listener?(status.converted)
        }
    }
}

#endif
