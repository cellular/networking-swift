import Foundation

/// Used to specify the way in which a set of parameters are applied to a URL request.
///
/// - json:            Uses `JSONSerialization` to create a JSON representation of the parameters object, which is
///                    set as the body of the request. The `Content-Type` HTTP header field of an encoded request is
///                    set to `application/json`.
///
/// - url:             Creates a query string to be set as or appended to any existing URL query for `GET`, `HEAD`,
///                    and `DELETE` requests, or set as the body for requests with any other HTTP method. The
///                    `Content-Type` HTTP header field of an encoded request with HTTP body is set to
///                    `application/x-www-form-urlencoded; charset=utf-8`. Since there is no published specification
///                    for how to encode collection types, the convention of appending `[]` to the key for array
///                    values (`foo[]=1&foo[]=2`), and appending the key surrounded by square brackets for nested
///                    dictionary values (`foo[bar]=baz`).
///
/// - urlEncodedInUrl: Creates query string to be set as or appended to any existing URL query. Uses the same
///                    implementation as the `.url` case, but always applies the encoded result to the URL.
///
/// - custom:          Uses the associated closure value to construct a new request given an existing request and parameters.
public enum ParameterEncoding {
    case json
    case url
    case urlEncodedInUrl
    case custom((URLRequest, [String: Any]?) -> (URLRequest, NSError?))
}
