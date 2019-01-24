import Foundation

/// Extensions on Foundation’s `Bundle` so you get `Path` rather than `String` or `URL`.
public extension Bundle {
    /// Returns the path for requested resource in this bundle.
    func path(forResource: String, ofType: String?) -> Path? {
        let f: (String?, String?) -> String? = path(forResource:ofType:)
        let str = f(forResource, ofType)
        return str.flatMap(Path.init)
    }

    /// Returns the path for the shared-frameworks directory in this bundle.
    var sharedFrameworks: Path? {
        return sharedFrameworksPath.flatMap(Path.init)
    }

    /// Returns the path for the resources directory in this bundle.
    var resources: Path? {
        return resourcePath.flatMap(Path.init)
    }

    /// Returns the path for this bundle.
    var path: Path {
        return Path(string: bundlePath)
    }
}

/// Extensions on `String` that work with `Path` rather than `String` or `URL`
public extension String {
    /// Initializes this `String` with the contents of the provided path.
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

/// Extensions on `Data` that work with `Path` rather than `String` or `URL`
public extension Data {
    /// Initializes this `Data` with the contents of the provided path.
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
        #if !os(Linux)
            opts = .atomicWrite
        #else
            opts = .atomic
        #endif
        } else {
            opts = []
        }
        try write(to: to.url, options: opts)
        return to
    }
}
