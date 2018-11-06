import Foundation

/// A part of MultipartFormData, shall be combined with other parts to combine MultipartFormData
/// Please see RFC 2388 for more info
public struct FormDataPart {

    /// The data to be sent in the form
    let data: NetworkData

    /// Name of the form field
    let name: String

    /// Optional file name
    let fileName: String?

    /// Optional mime type
    let mimeType: String?

    public init(data: NetworkData, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
