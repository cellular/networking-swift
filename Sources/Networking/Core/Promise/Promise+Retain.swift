import Foundation

/// A special promise class that no longer allows operations to be added,
/// as it retains itself until all following operations are completed.
public final class RetainedPromise<T> where T: Dependency {

    /// The promise to retain within `self` and which in turn retains
    /// `self` up until its operation queue has finished processing.
    private var retained: Promise<T>?

    /// Initializes a new instance of `self`, that retains given promise until its queued
    /// tasks have finished, and releases the `self` as as well as the promise afterwards.
    ///
    /// - Parameter promise: The promise to retain until it finished processing.
    fileprivate init(promise: Promise<T>) {
        retained = promise
        promise.addResponseOperation { _ in
            // As th operation "destroys" itself after the following step, `self` gets released.
            self.retained = nil // "nil-out" the promise as the last operation to break the retain-cycle.
        }
    }
}

extension Promise {

    /// Returns a `RetainedPromise` instance of `self`, allowing the promise to execute until it finished processing
    /// no matter the actual retain count. (e.g. if the responsible ViewController gets destroyed, the promise will still execute).
    ///
    /// - Returns: `RetainedPromise` of `self`.
    @discardableResult
    public func retained() -> RetainedPromise<T> {
        return RetainedPromise(promise: self)
    }
}
