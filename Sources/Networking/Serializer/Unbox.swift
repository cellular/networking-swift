import Unbox

// MARK: - Convenience Unboxing

/// Creates and returns a deserializer for a single `Model` instance of given type `model`.
/// `Model` must conform to `Unboxable`.
///
/// - Parameter model: The `Model.Type` to unbox within the response serialization process.
/// - Returns: A new deserializer that will unbox an instance of given `Model.Type` within a response deserialization.
public func unbox<Model>(model: Model.Type) -> UnboxedSingle<Model> {
    return UnboxedSingle<Model>()
}

/// Creates and returns a deserializer for an array of `Model` instance of given type `model`.
/// `Model` must conform to `Unboxable`.
///
/// - Parameters:
///   - model: The `Model.Type` to unbox within the response serialization process.
///   - allowInvalidElements: Allowing invalid elements withtin the array to deserialize.
/// - Returns: A new deserializer that will unbox an array of given `Model.Type` within a response deserialization.
public func unbox<Model>(model: Model.Type, allowInvalidElements: Bool) -> UnboxedArray<[Model]> {
    return UnboxedArray<[Model]>(allowInvalidElements: allowInvalidElements)
}

// MARK: - Specific Unboxing

/// Unboxes a single model instance
public struct UnboxedSingle<Model>: Deserializer where Model: Unboxable {

    /// Deserializes a `Model` instance from given `response` data using `Unbox`.
    /// Returns an error result if serialization failed.
    ///
    /// - Parameter response: The response received of which the data should be used for deserialization.
    /// - Returns: The result of the deserialization.
    public func deserialize(from response: Response) throws -> Model {
        if let data = response.data { return try unbox(data: data) }
        throw Error.serializationFailed("Response does not contain body data to be deserialized.")
    }
}

/// Unboxes an array of model instances
public struct UnboxedArray<Model>: Deserializer where Model: Sequence, Model.Iterator.Element: Unboxable {

    /// Allowing invalid elements within the array to deserialize.
    private let allowInvalids: Bool

    /// Initializes a new array unboxer instance that, depending on provided `allowInvalidElements`, will
    /// either force each element within the array to be valid, or allow some to fail the deserialization.
    ///
    /// - Parameter allowInvalidElements: Whether elements within the array are allowed to fail the deserialization.
    fileprivate init(allowInvalidElements: Bool) {
        allowInvalids = allowInvalidElements
    }

    /// Deserializes an array of `Model` instances from given `response` data using `Unbox`.
    /// Returns an error result if serialization failed.
    ///
    /// - Parameter response: The response received of which the data should be used for deserialization.
    /// - Returns: The result of the deserialization.
    public func deserialize(from response: Response) throws -> [Model.Iterator.Element] {
        if let data = response.data { return try unbox(data: data, allowInvalidElements: allowInvalids) }
        throw Error.serializationFailed("Response does not contain body data to be deserialized.")
    }
}
