import Foundation

public extension Path {
    /**
     Copies a file.
     - Note: `throws` if `to` is a directory.
     - Parameter to: Destination filename.
     - Parameter overwrite: If true overwrites any file that already exists at `to`.
     - Returns: `to` to allow chaining
     - SeeAlso: copy(into:overwrite:)
     */
    @discardableResult
    public func copy(to: Path, overwrite: Bool = false) throws -> Path {
        if overwrite, to.exists {
            try FileManager.default.removeItem(at: to.url)
        }
        try FileManager.default.copyItem(atPath: string, toPath: to.string)
        return to
    }

    /**
     Copies a file into a directory

     If the destination does not exist, this function creates the directory first.

     - Note: `throws` if `into` is a file.
     - Parameter into: Destination directory
     - Parameter overwrite: If true overwrites any file that already exists at `into`.
     - Returns: The `Path` of the newly copied file.
     - SeeAlso: copy(into:overwrite:)
     */
    @discardableResult
    public func copy(into: Path, overwrite: Bool = false) throws -> Path {
        if !into.exists {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } else if overwrite, !into.isDirectory {
            try into.delete()
        }
        let rv = into/basename()
        try FileManager.default.copyItem(at: url, to: rv.url)
        return rv
    }

    @discardableResult
    public func move(to: Path, overwrite: Bool = false) throws -> Path {
        if overwrite, to.exists {
            try FileManager.default.removeItem(at: to.url)
        }
        try FileManager.default.moveItem(at: url, to: to.url)
        return to
    }

    @discardableResult
    public func move(into: Path) throws -> Path {
        if !into.exists {
            try into.mkpath()
        } else if !into.isDirectory {
            throw CocoaError.error(.fileWriteFileExists)
        }
        let rv = into/basename()
        try FileManager.default.moveItem(at: url, to: rv.url)
        return rv
    }

    @inlinable
    public func delete() throws {
        try FileManager.default.removeItem(at: url)
    }

    @inlinable
    @discardableResult
    func touch() throws -> Path {
        return try "".write(to: self)
    }

    private func _foo(go: () throws -> Void) throws {
    #if !os(Linux)
        do {
            try go()
        } catch CocoaError.Code.fileWriteFileExists {
            // noop
        }
    #else
        do {
            try go()
        } catch {
            let error = error as NSError
            guard error.domain == NSCocoaErrorDomain, error.code == CocoaError.Code.fileWriteFileExists.rawValue else {
                throw error
            }
        }
    #endif
    }

    @discardableResult
    public func mkdir() throws -> Path {
        try _foo {
            try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: false, attributes: nil)
        }
        return self
    }

    @discardableResult
    public func mkpath() throws -> Path {
        try _foo {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return self
    }

    /// - Note: If file doesn’t exist, creates file
    /// - Note: If file is not writable, makes writable first, resetting permissions after the write
    @discardableResult
    public func replaceContents(with contents: String, atomically: Bool = false, encoding: String.Encoding = .utf8) throws -> Path {
        let resetPerms: Int?
        if exists, !isWritable {
            resetPerms = try FileManager.default.attributesOfItem(atPath: string)[.posixPermissions] as? Int
            let perms = resetPerms ?? 0o777
            try chmod(perms | 0o200)
        } else {
            resetPerms = nil
        }

        defer {
            _ = try? resetPerms.map(self.chmod)
        }

        try contents.write(to: self)

        return self
    }
}
