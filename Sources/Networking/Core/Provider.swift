import Foundation
import CELLULAR

/// Provider to be used in order to handle the actual networking within the client. Any outgoing request as received
/// by the client are passed to the provider which is then responsible for handling the actual networking interaction.
public protocol Provider {

    /// Creates a request for the specified method, URL string, parameters, parameter encoding and headers.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - URL: The URL string.
    ///   - parameters: The parameters. Defaults to `nil`.
    ///   - encoding: The parameter encoding. Defaults to `.url`.
    ///   - header: The HTTP header. Defaults to `nil`.
    /// - Returns: A new request with specified method, URL string, parameters, encoding and header.
    func request(_ method: Method, url: String, parameters: [String: Any]?,
                 encoding: ParameterEncoding, header: [String: String]?) -> Request

#if !os(watchOS)
    /// Returns a `ReachabilityManager` instance that may be used to monitor the reachability state against given host.
    ///
    /// - Parameter host: The host used to evaluate network reachability.
    /// - Returns: `ReachabilityManager` instance the may be used to monitor reachability state.
    func reachabilityManager(for host: String?) -> ReachabilityManager?
#endif

    /// Creates a request to upload the given data to the specified URL including the given parameters
    ///
    /// - Parameters:
    ///   - data: Data to upload
    ///   - url: URL endpoint to upload to
    ///   - method: HTTP method to use
    ///   - header: Optional HTTP header fields
    ///   - progressHandler: Closure to receive upload progress updates
    /// - Returns: A newly constructed request with the given parameters
    func upload(_ data: NetworkData, url: String, method: Method, header: [String: String]?,
                progressHandler: ((Progress) -> Void)?) -> Request

    /// Creates a request to upload multipart form data according to RFC 2388 with the given data and parameters
    ///
    /// - Parameters:
    ///   - multipartFormData: Array of form data, will be joined to form the multipart data form
    ///   - url: URL endpoint to upload to
    ///   - method: HTTP method to use
    ///   - header: Optional HTTP header fields
    ///   - encodingCompletion: Completion closure of the form encoding. If successful, the result contains the constructed Request object
    ///   - progressHandler: Closure to receive upload progress updates
    func upload(multipartFormData: [FormDataPart], url: String, method: Method, header: [String: String]?,
                progressHandler: ((Progress) -> Void)?) -> Request

//    func download(_ url: URLConvertible,method: HTTPMethod = .get, parameters: Parameters? = nil,
//        encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil,
//        to destination: DownloadRequest.DownloadFileDestination? = nil) -> DownloadRequest
}
