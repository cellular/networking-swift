import Foundation

extension Promise {

    /// Describes the values necessary for a promise to be resolved successfully.
    public struct Value {

        /// The dependency used by the promise to construct a request to be sent against the backend.
        let dependency: T

        /// The request constructed by the promise and sent against the backend.
        let request: Request

        /// The response of the request sent by the promise.
        let response: Response
    }
}
