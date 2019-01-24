import Foundation

public extension Path {
    /**
     Copies a file.
     - Note: `throws` if `to` is a directory.
     - Parameter to: Destination filename.
     - Parameter overwrite: If `true` and both `self` and `to` are files, overwrites `to`.
     - Note: If either `self` or `to are directories, `overwrite` is ignored.
     - Returns: `to` to allow chaining
     - SeeAlso: `copy(into:overwrite:)`
     */
    @discardableResult
    public func copy(to: Path, overwrite: Bool = false) throws -> Path {
        if overwrite, to.isFile, isFile {
            try FileManager.default.removeItem(at: to.url)
        }
        try FileManager.default.copyItem(atPath: string, toPath: to.string)
        return to
    }

    /**
     Copies a file into a directory

     If the destination does not exist, this function creates the directory first.
    
        // Create ~/.local/bin, copy `ls` there and make the new copy executable
        try Path.root.join("bin/ls").copy(into: Path.home.join(".local/bin").mkpath()).chmod(0o500)

     - Note: `throws` if `into` is a file.
     - Parameter into: Destination directory
     - Parameter overwrite: If true overwrites any file that already exists at `into`.
     - Returns: The `Path` of the newly copied file.
     - SeeAlso: `copy(into:overwrite:)`
     */
    @discardableResult
    public func copy(into: Path, overwrite: Bool = false) throws -> Path {
        if !into.exists {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        let rv = into/basename()
        if overwrite, rv.isFile {
            try rv.delete()
        }
    #if os(Linux)
    #if swift(>=5)
        // check if fixed
    #else
        if !overwrite, rv.isFile {
            throw CocoaError.error(.fileWriteFileExists)
        }
    #endif
    #endif
        try FileManager.default.copyItem(at: url, to: rv.url)
        return rv
    }

    /**
     Moves a file.
     - Note: `throws` if `to` is a directory.
     - Parameter to: Destination filename.
     - Parameter overwrite: If true overwrites any file that already exists at `to`.
     - Returns: `to` to allow chaining
     - SeeAlso: move(into:overwrite:)
     */
    @discardableResult
    public func move(to: Path, overwrite: Bool = false) throws -> Path {
        if overwrite, to.exists {
            try FileManager.default.removeItem(at: to.url)
        }
        try FileManager.default.moveItem(at: url, to: to.url)
        return to
    }

    /**
     Moves a file into a directory

     If the destination does not exist, this function creates the directory first.

     - Note: `throws` if `into` is a file.
     - Parameter into: Destination directory
     - Parameter overwrite: If true overwrites any file that already exists at `into`.
     - Returns: The `Path` of destination filename.
     - SeeAlso: move(into:overwrite:)
     */
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

    /// Deletes the path, recursively if a directory.
    @inlinable
    public func delete() throws {
        try FileManager.default.removeItem(at: url)
    }

    /**
     Creates an empty file at this path.
     - Returns: `self` to allow chaining.
     */
    @inlinable
    @discardableResult
    func touch() throws -> Path {
        return try "".write(to: self)
    }

    /// Helper due to Linux Swift being incomplete.
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

    /**
     Creates the directory at this path.
     - Note: Does not create any intermediary directories.
     - Returns: `self` to allow chaining.
     */
    @discardableResult
    public func mkdir() throws -> Path {
        try _foo {
            try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: false, attributes: nil)
        }
        return self
    }

    /**
     Creates the directory at this path.
     - Note: Creates any intermediary directories, if required.
     - Returns: `self` to allow chaining.
     */
    @discardableResult
    public func mkpath() throws -> Path {
        try _foo {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return self
    }
}
