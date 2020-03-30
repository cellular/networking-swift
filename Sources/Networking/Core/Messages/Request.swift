import Foundation
import CELLULAR

/// Responsible for sending a request and receiving the response and associated data from the server.
public protocol Request {

    /// The request sent or to be sent to the server.
    var request: URLRequest? { get }

    /// Updates the managing promise once the response have finished downloading or an error occured.
    /// The provider request **must** call the given handler once it determined the final state of the request.
    ///
    /// - Parameter completion: Must be called within the request once it completed (either successfull or due to a failure).
    func onCompleted(_ completion: @escaping (Result<Response, Swift.Error>) -> Void)

    /// Cancels the request.
    func cancel() -> Self
}
