import Foundation

/// Creates and returns a deserializer for an array of `Model` instance of given type `model`.
/// `Model` must conform to `Decodable`.
///
/// - Parameters:
///   - model: The `Model.Type` to decode within the response serialization process.
///   - decoder: An optional custom encoder to be used for serialization
/// - Returns: A new deserializer that will unbox an array of given `Model.Type` within a response deserialization.
public func decode<Model>(model: Model.Type, decoder: JSONDecoder = .init()) -> JSONNetworkingDecoder<Model> {
    return JSONNetworkingDecoder<Model>(decoder: decoder)
}

/// Decodes a single model instance
public struct JSONNetworkingDecoder<Model>: Deserializer where Model: Decodable {

    private let decoder: JSONDecoder

    /// Initializes a new decoder instance that
    ///
    /// - Parameter decoder: Optional custom encoder to be used for serialization
    fileprivate init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    /// Deserializes a `Model` instance from given `response` data using `Unbox`.
    /// Returns an error result if serialization failed.
    ///
    /// - Parameter response: The response received of which the data should be used for deserialization.
    /// - Returns: The result of the deserialization.
    public func deserialize(from response: Response) throws -> Model {
        if let data = response.data { return try decoder.decode(Model.self, from: data) }
        throw Error.serializationFailed("Response does not contain body data to be deserialized.")
    }
}
