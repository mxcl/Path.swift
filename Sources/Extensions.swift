import Foundation

public extension Bundle {
    func path(forResource: String, ofType: String?) -> Path? {
        let f: (String?, String?) -> String? = path(forResource:ofType:)
        let str = f(forResource, ofType)
        return str.flatMap(Path.init)
    }

    public var sharedFrameworks: Path? {
        return sharedFrameworksPath.flatMap(Path.init)
    }

    public var resources: Path? {
        return resourcePath.flatMap(Path.init)
    }
}

public extension String {
    @inlinable
    init(contentsOf path: Path) throws {
        try self.init(contentsOfFile: path.string)
    }

    /// - Returns: `to` to allow chaining
    @inlinable
    @discardableResult
    func write(to: Path, atomically: Bool = false, encoding: String.Encoding = .utf8) throws -> Path {
        try write(toFile: to.string, atomically: atomically, encoding: encoding)
        return to
    }
}

public extension Data {
    @inlinable
    init(contentsOf path: Path) throws {
        try self.init(contentsOf: path.url)
    }

    /// - Returns: `to` to allow chaining
    @inlinable
    @discardableResult
    func write(to: Path, atomically: Bool = false) throws -> Path {
        let opts: NSData.WritingOptions
        if atomically {
            opts = .atomicWrite
        } else {
            opts = []
        }
        try write(to: to.url, options: opts)
        return to
    }
}
