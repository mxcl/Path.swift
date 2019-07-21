import Foundation

/**
 Provided for relative-path coding. See the instructions in our
 [README](https://github.com/mxcl/Path.swift/#codable).
*/
public extension CodingUserInfoKey {
    /**
     If set on an `Encoder`’s `userInfo` all paths are encoded relative to this path.

     For example:

         let encoder = JSONEncoder()
         encoder.userInfo[.relativePath] = Path.home
         encoder.encode([Path.home, Path.home/"foo"])

     - Remark: See the [README](https://github.com/mxcl/Path.swift/#codable) for more information.
    */
    static let relativePath = CodingUserInfoKey(rawValue: "dev.mxcl.Path.relative")!
}

/**
 Provided for relative-path coding. See the instructions in our
 [README](https://github.com/mxcl/Path.swift/#codable).
*/
extension Path: Codable {
    /// - SeeAlso: `CodingUserInfoKey.relativePath`
    /// :nodoc:
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if value.hasPrefix("/") {
            string = value
        } else if let root = decoder.userInfo[.relativePath] as? Path {
            string = (root/value).string
        } else if let root = decoder.userInfo[.relativePath] as? DynamicPath {
            string = (root/value).string
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Path cannot decode a relative path if `userInfo[.relativePath]` not set to a Path object."))
        }
    }

    /// - SeeAlso: `CodingUserInfoKey.relativePath`
    /// :nodoc:
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let root = encoder.userInfo[.relativePath] as? Path {
            try container.encode(relative(to: root))
        } else if let root = encoder.userInfo[.relativePath] as? DynamicPath {
            try container.encode(relative(to: root))
        } else {
            try container.encode(string)
        }
    }
}
