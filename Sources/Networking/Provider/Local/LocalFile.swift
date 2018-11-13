import Foundation
import CELLULAR

// MARK: - Models

// MARK: Public

/// Represents a model which contains the file path to the JSON as well as all the placeholders.
public struct LocalFileDefinition {

    /// The bundle where all the JSON files are stored
    var bundle: Bundle

    /// The file name of the JSON file, which provides all the mapping
    var fileName: String

    /// The Dictionary, which provides the placeholder names in combination with the replacement strings
    var placeholders: [String: String]

    public init(bundle: Bundle, fileName: String, placeholders: [String: String]) {
        self.bundle = bundle
        self.fileName = fileName
        self.placeholders = placeholders
    }
}

// MARK: Internal

internal struct LocalFileMapContainer: Decodable {

    var fileMaps: [LocalFileMap]
}

public struct LocalFileMap: Decodable {
    let url: String
    let fileName: String
    let fileType: String?
    let statusCode: Int

    public init(url: String, fileName: String, fileType: String? = nil, statusCode: Int = 200) {
        self.url = url
        self.fileName = fileName
        self.fileType = fileType
        self.statusCode = statusCode
    }
}

// MARK: Private

/// Represents a response received by reading the data of a local file.
private struct LocalFileResponse: Networking.Response {

    /// The response received from the server, if any.
    var response: HTTPURLResponse

    /// The data received within the response body (if any).
    var data: Data?
}

// MARK: - Request

/// Responsible for request that is not send via the network, but instead reads its representing response data from a local file.
class LocalFileRequest: Request {

    private(set) var request: URLRequest?

    private let mapping: [LocalFileMap]
    private let bundle: Bundle

    init(url: String, provider: LocalFileProvider) {
        if let url = URL(string: url) {
            request = URLRequest(url: url)
        }
        self.mapping = provider.mapping
        self.bundle = provider.fileBundle
    }

    /// Updates the managing promise once to the response have finished downloading or an error occured.
    /// The provider request **must** call the given handler once it determined the final state of the request.
    ///
    /// - Parameter completion: Must be called within the provider request once it completed (either successfull or due to a failure).
    public func onCompleted(_ completion: @escaping (Result<Response, Error>) -> Void) {
        if let url = request?.url, let map = mapping.first(where: { $0.url == url.absoluteString}),
            let filePath = bundle.path(forResource: map.fileName, ofType: map.fileType ?? "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
            let response = HTTPURLResponse(url: url, statusCode: map.statusCode, httpVersion: nil, headerFields: nil) {

            completion(.success(LocalFileResponse(response: response, data: data)))
        } else if let url = request?.url, let wildcardMap = LocalFileHelper.findWildcard(for: url, in: mapping),
            let filePath = bundle.path(forResource: wildcardMap.fileName, ofType: wildcardMap.fileType ?? "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
            let response = HTTPURLResponse(url: url, statusCode: wildcardMap.statusCode, httpVersion: nil, headerFields: nil) {

            completion(.success(LocalFileResponse(response: response, data: data)))
        } else if let url = request?.url, let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil) {
            completion(.failure(Error.clientError(self, LocalFileResponse(response: response, data: nil))))
        } else {
            completion(.failure(Error.requestFailed(self, "Could not handle request")))
        }
    }

    /// Cancels the request.
    func cancel() { /* Once created, the local file request is */ }
}

// MARK: - Provider

public class LocalFileProvider: Provider {

    /// mock file mapping, held in container
    private(set) var mapping: [LocalFileMap]

    /// Bundle where mapping files are stored
    let fileBundle: Bundle

    public init(definition: LocalFileDefinition) throws {
        self.fileBundle = definition.bundle
        self.mapping = (try LocalFileHelper.createMapping(with: definition)).fileMaps
    }

    public init(mapping: [LocalFileMap], bundle: Bundle) {
        self.mapping = mapping
        self.fileBundle = bundle
    }

    /// Creates a request for the specified method, URL string, parameters, parameter encoding and headers.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - URL: The URL string.
    ///   - parameters: The parameters. Defaults to `nil`.
    ///   - encoding: The parameter encoding. Defaults to `.url`.
    ///   - header: The HTTP header. Defaults to `nil`.
    /// - Returns: A new request with specified method, URL string, parameters, encoding and header.
    public func request(_ method: Method, url: String, parameters: Parameters?,
                        encoding: ParameterEncoding, header: Header?) -> Request {
        return LocalFileRequest(url: url, provider: self)
    }

    public func upload(_ data: NetworkData, url: String, method: Method,
                       header: [String: String]?, progressHandler: ((Progress) -> Void)?) -> Request {
        return LocalFileRequest(url: url, provider: self)
    }

    public func upload(multipartFormData: [FormDataPart], url: String, method: Method, header: [String: String]?,
                       encodingCompletion: ((Result<FormDataEncodingResult, String>) -> Void)?, progressHandler: ((Progress) -> Void)?) {
        encodingCompletion?(.success(FormDataEncodingResult(request: LocalFileRequest(url: url, provider: self),
                                                            streamingFromDisk: false, streamFileURL: nil)))
    }

    #if !os(watchOS)
    /// The `LocalFileProvider` does not support evaluation of reachability changes (only **local** operations).
    public func reachabilityManager(for host: String?) -> ReachabilityManager? {
        return nil
    }
    #endif
}
