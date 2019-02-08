import Foundation

public extension Path {
    //MARK: Filesystem Attributes

    /**
     Returns the creation-time of the file.
     - Note: Returns `nil` if there is no creation-time, this should only happen if the file doesn’t exist.
     - Important: On Linux this is filesystem dependendent and may not exist.
     */
    var ctime: Date? {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: string)
            return attrs[.creationDate] as? Date
        } catch {
            return nil
        }
    }

    /**
     Returns the modification-time of the file.
     - Note: If this returns `nil` and the file exists, something is very wrong.
     */
    var mtime: Date? {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: string)
            return attrs[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    /**
     Sets the file’s attributes using UNIX octal notation.

         Path.home.join("foo").chmod(0o555)
     */
    @discardableResult
    func chmod(_ octal: Int) throws -> Path {
        try FileManager.default.setAttributes([.posixPermissions: octal], ofItemAtPath: string)
        return self
    }
    
    /**
     Applies the macOS filesystem “lock” attribute.
     - Note: If file is already locked, does nothing.
     - Note: If file doesn’t exist, throws.
     - Important: On Linux does nothing.
     */
    @discardableResult
    func lock() throws -> Path {
    #if !os(Linux)
        var attrs = try FileManager.default.attributesOfItem(atPath: string)
        let b = attrs[.immutable] as? Bool ?? false
        if !b {
            attrs[.immutable] = true
            try FileManager.default.setAttributes(attrs, ofItemAtPath: string)
        }
    #endif
        return self
    }

    /**
     - Note: If file isn‘t locked, does nothing.
     - Note: If file doesn’t exist, does nothing.
     - Important: On Linux does nothing.
     - SeeAlso: `lock()`
     */
    @discardableResult
    func unlock() throws -> Path {
    #if !os(Linux)
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
    #endif
        return self
    }
}
