import Foundation
import CELLULAR

/// Promise defines a proxy object between the request to be sent and the dependency that needs to resolve.
/// It is available and returned once a networking request is addressed as the `Client` while the actual request
/// may not directly be available due to a pending dependency update. However, the corresponding request will
/// directly be assigned to the managing promise on creation and is available in either completion closure.
/// Furthermore, the promise allows access and serialization to the request at any time and queue the
/// access/serialization if necessary (e.g. while the actual request is still waiting for it being created).
public final class Promise<T> where T: Dependency {

    /// The underlying closure to be queued within the client's dependency queue to send the request.
    private var dependencyClosure: ((Promise, Result<T, Swift.Error>) -> Void)

    /// The queue to add the dependency operation once the request should be executed.
    private var dependencyQueue: OperationQueue<Result<T, Swift.Error>>

    /// The passed in operation to be executed to resolve the promise once the dependency is resolved.
    private var requestOperation: Operation?

    /// The queue to add any serialization related tasks (response serialization or failure listener).
    private let responseQueue: OperationQueue<Result<Value, Swift.Error>>

    /// The current state of the promise within the request queue wrapped as protected/atomic values.
    private lazy var protectedState = Protected<State>(initialValue: .idle, lock: DispatchLock(
            queue: DispatchQueue(label: "de.cellular.networking.promise.protected-state-lock")))

    /// The current state of the promise within the request queue.
    public var state: State { return protectedState.read { $0 } }

    /// The authentication to be sent with the request associated with this promise.
    public internal(set) var authentication: Authentication?

    // MARK: Initializers

    /// Initializes a new promise object to be used as a proxy between the (possible) delayed request and the client API,
    /// within given queue once it's value is resolved. Given operation will be executed with newly instantiated promise
    /// once given `OperationQueue` is no longer suspended.
    ///
    /// - Parameters:
    ///   - queue: The `OperationQueue` within which the promise should be "queued" once its ready.
    ///   - operation: The operation to execute once given `OperationQueue` is no longer suspended.
    internal init(in queue: OperationQueue<Result<T, Swift.Error>>, operation: @escaping (Promise, Result<T, Swift.Error>) -> Void) {
        responseQueue = OperationQueue()
        dependencyClosure = operation
        dependencyQueue = queue
    }

    // MARK: Operational

    /// Starts queueing the promise underlying dependency access in order to send the request and receive data.
    @discardableResult
    internal func addResponseOperation(closure: @escaping (Result<Value, Swift.Error>) -> Void) -> Operation {

        protectedState.write { state in
            // Switch state from idling to pending (if not already started)
            guard case .idle = state else { return }
            state = .pending

            // Queue the promise operation within the client to send the request.
            requestOperation = dependencyQueue.addOperation({ [weak self] (result) in
                guard let this = self else { return }
                this.dependencyClosure(this, result)
            })
        }
        return responseQueue.addOperation(closure)
    }

    /// Resolves the promise "successfully" as a valid request object has been instantiated and assigned to the promise.
    /// This does not imply that the request is successfull as it may still be pending. Therefore the state of the promise
    /// switches to `.started` and will become either `.finished` (on a successful request) or `.failed` (request failed).
    ///
    /// - Parameter value: The request object behind the promise "proxy" object.
    internal func resolve(with request: Request, using dependency: T) {

        let hasStarted: (inout State) -> Bool = { state in
            guard case .pending = state else { return false }
            // Switch state pending to started (if not already started)
            state = .started(dependency, request)
            return true
        }

        guard protectedState.write(hasStarted) else { return }
        // Since the request has now been started, attach the completion handler.
        request.onCompleted(resolve(with:))
    }

    /// Resolves the promise "finished" as a valid response with proper data has been received and assigned to the promise.
    /// Request serialization will now start for all previously added response-serialization steps. Further serialization
    /// may still be added if so desired (serialization will happen based on FIFO). If an error has been given as result,
    /// the promise marks itself "failed", the serialization queue will also be started, however only the failure listeners
    /// will be executed.
    ///
    /// - Parameter result: The request response result (either the proper response or an error, e.g. due to a timeout).
    internal func resolve(with result: Result<Response, Swift.Error>) {

        // Resolve response queue with the result returned by write task
        responseQueue.resolve(with: protectedState.write { state in
            // Validate the result returned successfully as well as the internal state is of proper value.
            guard case let .started(dependency, request) = state, case let .success(response) = result else {
                // Error while requesting data. Examine the reason and resolve the promise as failed.
                let error: Swift.Error
                if case let .failure(networkingError) = result {
                    error = networkingError
                } else { // Dependency error
                    error = Error.unsolvedDependency("Dependency missing on success return.")
                }
                // Fail the promise and update the response/failure closures
                state = .failed(error)
                return .failure(error)
            }
            // Finish the promise as dependency, request and response has been received.
            let values = Value(dependency: dependency, request: request, response: response)
            state = .finished(values)
            return .success(values)
        })
    }

    /// Cancels the request promise and any response serialization within `self`.
    public func cancel() {
        protectedState.write { state in
            // Switch current state to cancel (if still cancelable)
            switch state {
            // Promises that have been canceled, have failed or finished are no longer "cancelable".
            case .canceled, .failed, .finished: return
            // Promises that have started, may be canceled, but their request must be canceled as well as the operating queues.
            case let .started(_, request): request.cancel()
            // Other states are cancelable and do not require additional processes other than canceling the operating queues.
            default: break
            }
            state = .canceled
            // Cancel the request if already associated and all tasks within the access operation.
            responseQueue.cancelAllOperations()
            requestOperation?.cancel()
        }
    }
}

// MARK: - Hashable
extension Promise: Hashable {
    public static func == (lhs: Promise<T>, rhs: Promise<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
