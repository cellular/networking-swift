import Foundation

public extension Promise {

    /// Possible states of the promise and its request within an entire lifecycle.
    ///
    /// - idle: The promise is not yet queued within the request chain, as authorization or chaining may be added.
    /// - pending: The promise is still waiting for the client to send a dedicted request.
    /// - started: The client has sent a dedicated request and the promise is waiting for the response.
    /// - failed: The client has failed to update the dependency OR the request did fail to receive a response.
    /// - canceled: The promise got canceled. (Note: Once the promise finished it is no longer cancelable.)
    /// - finished: The promise and its dedicated request finished successfully. Response available.
    public enum State {
        case idle
        case pending
        case started(T, Request)    // The dependency (used to resolve the request) and the request sent by the provider.
        case failed(Error)          // The error object to describe the reason for the promise to fail requesting.
        case canceled
        case finished(Value) // The dependency (used to resolve the request), the request and the received response.
    }
}
