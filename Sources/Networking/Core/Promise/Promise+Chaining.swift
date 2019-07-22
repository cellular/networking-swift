import Foundation

extension Promise {

    public func map(
        in queue: DispatchQueue? = .none,
        transform: @escaping (Result<Value, Swift.Error>) throws -> Promise
    ) -> Promise {
        return .init(in: dependencyQueue) { (promise, result) in
            self.addResponseOperation { (result) in
                // The closure to be called upon transforming and resolve the transform
                let resolve: () -> Void = {
                    do {
                        promise.resolve(with: try transform(result))
                    } catch {
                        promise.resolve(with: error)
                    }
                    let _ = self // retain self... yeeeeah, i know
                }
                // If no specific queue is given (`nil`) return on current queue.
                guard let queue = queue else { return resolve() }
                // Specific queue given, return on the desired queue.
                queue.async(execute: resolve)
            }
        }
    }

    public func map<Model>(
        in queue: DispatchQueue? = .none,
        serializing: @escaping (Response) throws -> Model,
        transform: @escaping (Result<Model, Swift.Error>) throws -> Promise
    ) -> Promise {
        return map(in: queue) { (result) in
            switch result {
            case let .failure(error):
                return try transform(.failure(error))
            case let .success(values):
                do {
                    return try transform(.success(try serializing(values.response)))
                } catch let error {
                    return try transform(.failure(error))
                }
            }
        }
    }

    public func map<Serializer: Deserializer>(
        in queue: DispatchQueue? = .none,
        serializer: Serializer,
        transform: @escaping (Result<Serializer.Model, Swift.Error>) throws -> Promise
    ) -> Promise {
        return map(in: queue, serializing: { try serializer.deserialize(from: $0) }, transform: transform)
    }
}
