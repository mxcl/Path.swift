import Foundation

public extension Path {
    /// - Note: If file is already locked, does nothing
    /// - Note: If file doesn’t exist, throws
    @discardableResult
    public func lock() throws -> Path {
        var attrs = try FileManager.default.attributesOfItem(atPath: string)
        let b = attrs[.immutable] as? Bool ?? false
        if !b {
            attrs[.immutable] = true
            try FileManager.default.setAttributes(attrs, ofItemAtPath: string)
        }
        return self
    }

    /// - Note: If file isn‘t locked, does nothing
    /// - Note: If file doesn’t exist, does nothing
    @discardableResult
    public func unlock() throws -> Path {
        var attrs: [FileAttributeKey: Any]
        do {
            attrs = try FileManager.default.attributesOfItem(atPath: string)
        } catch CocoaError.fileReadNoSuchFile {
            return self
        }
        let b = attrs[.immutable] as? Bool ?? false
        if b {
            attrs[.immutable] = false
            try FileManager.default.setAttributes(attrs, ofItemAtPath: string)
        }
        return self
    }

    /**
     Sets the file’s attributes using UNIX octal notation.

         Path.home.join("foo").chmod(0o555)
     */
    @discardableResult
    public func chmod(_ octal: Int) throws -> Path {
        try FileManager.default.setAttributes([.posixPermissions: octal], ofItemAtPath: string)
        return self
    }

    /// - Returns: modification-time or creation-time if none
    public var mtime: Date {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: string)
            return attrs[.modificationDate] as? Date ?? attrs[.creationDate] as? Date ?? Date()
        } catch {
            //TODO print(error)
            return Date()
        }
    }
}
