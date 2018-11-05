import Foundation
import CELLULAR

public extension Promise {

    // MARK: Plain response

    /// Adds a response handler to the promise, executing `completion`, in given `queue` upon
    /// network request finishes and `filter` matches the status code of the returning promise.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - filter:
    ///            Defines a closure to evaluate the status code of the response. Return `true` if status code matches expectation.
    ///            Defaults to range of 200...399 status codes.
    ///   - completion:
    ///            Completion to be executed once the request finished and the filter matches.
    ///            Passed values are, the dependency that has been used to resolve the promise, the request and the returning response.
    /// - Returns: The promise to which the response handler has been subscribed.
    @discardableResult
    public func response(in queue: DispatchQueue? = .main, filter: @escaping (Int) -> Bool = { (200..<400).contains($0) },
                         completion: @escaping (T, Request, Response) -> Void) -> Promise {
        addResponseOperation { result in
            // Error must never be considered a valid response
            guard case let .success(values) = result else { return }
            // Validate status code first, return if none-match.
            guard filter(values.response.statusCode) else { return }
            // The closure to be called upon finishing the response
            let resolve: () -> Void = { completion(values.dependency, values.request, values.response) }
            // If no specific queue is given (`nil`) return on current queue.
            guard let queue = queue else { return resolve() }
            // Specific queue given, return on the desired queue.
            queue.async(execute: resolve)
        }
        return self
    }

    /// Adds a response handler to the promise, executing `completion`, in given `queue` upon network request
    /// finishes and if any value within `filter` matches the status code of the returning promise.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - filter:
    ///            A sequence of status codes of which any must match in order for the completion block to be executed.
    ///            Defaults to range of 200...399 status codes.
    ///   - completion:
    ///            Completion to be executed once the request finished and the filter matches.
    ///            Passed values are, the dependency that has been used to resolve the promise, the request and the returning response.
    /// - Returns: The promise to which the response handler has been subscribed.
    @discardableResult
    public func response<S: Sequence>(
        in queue: DispatchQueue? = .main, filter: S,
        completion: @escaping (T, Request, Response) -> Void) -> Promise where S.Iterator.Element == Int {

        return response(in: queue, filter: { filter.contains($0) }, completion: completion)
    }

    /// Adds a response handler to the promise, executing `completion`, in given `queue` upon network request
    /// finishes and if the given status code matches the status code of the returning promise.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - code: The expected status code of the response in order to call the completion closure. Defaults to all codes within 200...300.
    ///   - completion:
    ///            Completion to be executed once the request finished and the filter matches.
    ///            Passed values are, the dependency that has been used to resolve the promise, the request and the returning response.
    /// - Returns: The promise to which the response handler has been subscribed.
    @discardableResult
    public func response(in queue: DispatchQueue? = .main, filter: Int, completion: @escaping (T, Request, Response) -> Void) -> Promise {
        return response(in: queue, filter: [filter], completion: completion)
    }

    // MARK: Serialized response

    /// Adds a response handler to the promise, executing `completion`, in given `queue` upon
    /// network request finishes and `filter` matches the status code of the returning promise.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - serializer: Serializer to use, in order to deserialize (a) model instance(s) from the response data.
    ///   - filter:
    ///            Defines a closure to evaluate the status code of the response. Return `true` if status code matches expectation.
    ///            Defaults to range of 200...399 status codes.
    ///   - completion:
    ///            Completion to be executed once the request finished and the filter matches.
    ///            Passed values are, the dependency that has been used to resolve the promise, the request,
    ///            the response and the deserialized model.
    /// - Returns: The promise to which the response handler has been subscribed.
    @discardableResult
    public func response<Serializer: Deserializer>(
        in queue: DispatchQueue? = .main,
        serializer: Serializer, filter: @escaping (Int) -> Bool = { (200..<400).contains($0) },
        completion: @escaping (T, Request, Response, Result<Serializer.Model, Swift.Error>) -> Void) -> Promise {

        return response(in: nil, filter: filter) { dependency, request, response in
            // Wrapping closure to execute the completion block on desired queue
            let resolve: (Result<Serializer.Model, Swift.Error>) -> Void = { result in
                guard let queue = queue else { return completion(dependency, request, response, result) }
                queue.async { completion(dependency, request, response, result) }
            }
            // Try deserialization and return the result of the conversion
            do {
                resolve(.success(try serializer.deserialize(from: response)))
            } catch let error {
                resolve(.failure(error))
            }
        }
    }

    /// Adds a response handler to the promise, executing `completion`, in given `queue` upon
    /// network request finishes and `filter` matches the status code of the returning promise.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - serializer: Serializer to use, in order to deserialize (a) model instance(s) from the response data.
    ///   - filter:
    ///            Defines a closure to evaluate the status code of the response. Return `true` if status code matches expectation.
    ///            Defaults to range of 200...399 status codes.
    ///   - completion:
    ///            Completion to be executed once the request finished and the filter matches.
    ///            Passed values are, the dependency that has been used to resolve the promise, the request,
    ///            the response and the deserialized model.
    /// - Returns: The promise to which the response handler has been subscribed.
    @discardableResult
    public func response<Serializer: Deserializer, S: Sequence>(
        in queue: DispatchQueue? = .main,
        serializer: Serializer, filter: S,
        completion: @escaping (T, Request, Response, Result<Serializer.Model, Swift.Error>) -> Void) -> Promise
        where S.Iterator.Element == Int {

        return response(in: queue, serializer: serializer, filter: { filter.contains($0) }, completion: completion)
    }

    /// Adds a response handler to the promise, executing `completion`, in given `queue` upon
    /// network request finishes and `filter` matches the status code of the returning promise.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - serializer: Serializer to use, in order to deserialize (a) model instance(s) from the response data.
    ///   - filter:
    ///            Defines a closure to evaluate the status code of the response. Return `true` if status code matches expectation.
    ///            Defaults to range of 200...399 status codes.
    ///   - completion:
    ///            Completion to be executed once the request finished and the filter matches.
    ///            Passed values are, the dependency that has been used to resolve the promise, the request,
    ///            the response and the deserialized model.
    /// - Returns: The promise to which the response handler has been subscribed.
    @discardableResult
    public func response<Serializer: Deserializer>(
        in queue: DispatchQueue? = .main, serializer: Serializer, filter: Int,
        completion: @escaping (T, Request, Response, Result<Serializer.Model, Swift.Error>) -> Void) -> Promise {

        return response(in: queue, serializer: serializer, filter: [filter], completion: completion)
    }

    // MARK: Error Handling

    /// Subscribes a failure handler to the promise that will be triggered on promise or request errors and on responses with status codes
    /// within the default range of error codes (400 - 599). Convenience function for what is basically considered as error.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - handler: The handler to be triggered if an error occured or the response code is within error range.
    /// - Returns: The promise to which the failure handler has been subscribed.
    @discardableResult
    public func failure(in queue: DispatchQueue? = .main, handler: @escaping (Error) -> Void) -> Promise {
        return failure(in: queue, exclude: [], handler: handler)
    }

    /// Subscribes a failure handler to the promise that will be triggered on promise or request errors and on responses with status codes
    /// within the default range of error codes (400 - 599), excluding those provided via filter.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue within which the handler should return. Returns on current queue if `nil` given. Defaults to `.main`.
    ///   - exclude: Sequence of status codes to be excluded from the default error code range.
    ///   - handler: The handler to be triggered if an error occured or the response code is within error range.
    /// - Returns: The promise to which the failure handler has been subscribed.
    @discardableResult
    public func failure<S: Sequence>(
        in queue: DispatchQueue? = .main, exclude: S,
        handler: @escaping (Error) -> Void) -> Promise where S.Iterator.Element == Int {

        addResponseOperation { result in

            // Wrapping closure to execute the completion block on desired queue
            let resolve: (Error) -> Void = { error in
                guard let queue = queue else { return handler(error) }
                queue.async { handler(error) }
            }

            switch result {
            // Easiest failure, as there has been a failure within the request chain (no response at all)
            case let .failure(error): return resolve(error)
            // Evaluate the response status codes and return on default error ranges (client or server error).
            case let .success(values):
                let request = values.request
                let response = values.response
                if Set(400..<500).subtracting(exclude).contains(response.statusCode) {
                    // Response returned with a status code between 400 and 500, and is not excluded. Client Error.
                    resolve(.clientError(request, response))
                } else if Set(500..<600).subtracting(exclude).contains(response.statusCode) {
                    // Response returned with a status code between 500 and 600, and is not excluded. Server Error.
                    resolve(.serverError(request, response))
                }
            }
        }
        return self
    }
}
