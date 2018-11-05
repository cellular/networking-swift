import Foundation

/// Holds result of the multipart form data when constructing request data
public struct FormDataEncodingResult {
    let request: Request
    let streamingFromDisk: Bool
    let streamFileURL: URL?

    public init(request: Request, streamingFromDisk: Bool, streamFileURL: URL?) {
        self.request = request
        self.streamingFromDisk = streamingFromDisk
        self.streamFileURL = streamFileURL
    }
}
