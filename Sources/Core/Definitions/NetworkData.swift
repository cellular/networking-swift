import Foundation

/// Network data may be provided in the forms specified by these enum cases
public enum NetworkData {
    case data(Data)
    case fileURL(URL)
    case inputStream(InputStream, length: UInt64)
}
