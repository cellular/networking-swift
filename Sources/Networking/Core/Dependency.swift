import Foundation
import CELLULAR

/// Protocol to be implemented by any class/struct that may act as a client's dependency within an application.
public protocol Dependency: Hashable {

    /// The base URL to resolve each outgoing request against (relative).
    var baseUrl: URL? { get }
}

/// Protocol to be implemented by any class that is able to resolve the associated dependency for the client.
public protocol DependencyManager {

    /// The dependency class to be resolved within the dependency manager.
    associatedtype Value: Dependency

    /// The handler to be used within the application to get notified about dependency update events.
    associatedtype Handler

    /// Required initializer to bootstrap a dependency manager within the client.
    init()

    /// Called from within the client once it requires the manager to resolve/update it's managing dependency.
    ///
    /// - Parameters:
    ///   - manager: The provider that can be used to update the dependency. Allows direct networking access.
    ///   - handler: The handler that has been passed from the application to the client within its
    ///              `-performDependencyUpdateRoutine:` to receive updates on dependency changes.
    ///   - completion: The completion closure that must be called to inform the client once the dependency has been resolved.
    func requiresDependencyUpdate(manager: Provider, handler: Handler, completion: @escaping (Result<Value, String>) -> Void)
}
