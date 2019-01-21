import Foundation

/// Provided for relative-path coding. See the instructions in our `README`.
public extension CodingUserInfoKey {
    /// If set paths are encoded as relative to this path.
    static let relativePath = CodingUserInfoKey(rawValue: "dev.mxcl.Path.relative")!
}

/// Provided for relative-path coding. See the instructions in our `README`.
extension Path: Codable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if value.hasPrefix("/") {
            string = value
        } else {
            guard let root = decoder.userInfo[.relativePath] as? Path else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Path cannot decode a relative path if `userInfo[.relativePath]` not set to a Path object."))
            }
            string = (root/value).string
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let root = encoder.userInfo[.relativePath] as? Path {
            try container.encode(relative(to: root))
        } else {
            try container.encode(string)
        }
    }
}
