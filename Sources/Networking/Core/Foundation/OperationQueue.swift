import Foundation

/// Defines a serial operation queue that operates (only) once its depending value is resolved.
public final class OperationQueue<Value> {

    /// The value to resolve the operation queue against
    internal private(set) var value: Value?

    /// Indicates whether the queue is actively scheduling operations for execution.
    public var isSuspended: Bool { return queue.isSuspended }

    /// The operation queue to stack the incoming operations within `-addOperation:`
    private var queue: Foundation.OperationQueue = {
        let queue = Foundation.OperationQueue()
        queue.maxConcurrentOperationCount = 1 // Serial queue
        queue.isSuspended = true // Suspended, up until resolved by `value`
        return queue
    }()

    // MARK: - Operational

    /// Wraps the specified block in an operation object and adds it to the receiver.
    /// This method adds a single block to the receiver by first wrapping it in an operation object.
    /// You should not attempt to get a reference to the newly created operation object or determine its type information.
    ///
    /// - Parameter closure: The closure to execute from the operation object. The closure takes the queue depending value
    ///                      as parameter (the value it has been resolved with) and has no return value.
    /// - Returns: The operation that has been created and added to the queue.
    public func addOperation(_ closure: @escaping (Value) -> Void) -> Operation {
        let operation = BlockOperation(block: { [weak self] in
            if let value = self?.value { closure(value) }
        })
        queue.addOperation(operation)
        return operation
    }

    /// Resolves the queues dependency with given `value`. Queue will be unsuspended after the value has
    /// been assigned and operations that have been added to the queue will be executed with given value.
    ///
    /// - Parameter value: The value to resolve the queue and to be passed to each added operation.
    public func resolve(with value: Value) {
        self.value = value
        queue.isSuspended = false
    }

    /// Invalidates the current value within the queue by suspending the queue and deleting it's internal value reference.
    public func invalidate() {
        queue.isSuspended = true
        self.value = nil
    }

    /// Cancels all operations within the serial queue.
    ///
    /// None of the operations queued within `self` will be executed but simple removed from the operation queue.
    public func cancelAllOperations() {
        queue.cancelAllOperations()
    }
}
