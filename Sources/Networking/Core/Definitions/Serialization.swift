import Foundation

/// Protocol to be implemented by classes that support deserialization and should
/// be used by the client to link it within the response chain for deserialization.
public protocol Deserializer {

    /// The model type which will be deserialized.
    associatedtype Model

    /// Deserializes a `Model` instance from given `response` data.
    /// Returns an error result if serialization failed.
    ///
    /// - Parameter response: The response received of which the data should be used for deserialization.
    /// - Returns: The result of the deserialization.
    func deserialize(from response: Response) throws -> Model
}
