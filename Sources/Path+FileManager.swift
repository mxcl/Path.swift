import Foundation
#if os(Linux)
import Glibc
#endif

public extension Path {
    //MARK: File Management
    
    /**
     Copies a file.

         try Path.root.join("bar").copy(to: Path.home/"foo")
         // => "/Users/mxcl/foo"

     - Note: `throws` if `to` is a directory.
     - Parameter to: Destination filename.
     - Parameter overwrite: If `true` and both `self` and `to` are files, overwrites `to`.
     - Note: If either `self` or `to are directories, `overwrite` is ignored.
     - Note: Throws if `overwrite` is `false` yet `to` is *already* identical to
      `self` because even though *Path.swift’s* policy is to noop if the desired
       end result preexists, checking for this condition is too expensive a
       trade-off.
     - Returns: `to` to allow chaining
     - SeeAlso: `copy(into:overwrite:)`
     */
    @discardableResult
    func copy(to: Path, overwrite: Bool = false) throws -> Path {
        if overwrite, to.isFile, isFile {
            try FileManager.default.removeItem(at: to.url)
        }
    #if os(Linux) && !swift(>=5.1) // check if fixed
        if !overwrite, to.isFile {
            throw CocoaError.error(.fileWriteFileExists)
        }
    #endif
        try FileManager.default.copyItem(atPath: string, toPath: to.string)
        return to
    }

    /**
     Copies a file into a directory

         try Path.root.join("bar").copy(into: .home)
         // => "/Users/mxcl/bar"

         // Create ~/.local/bin, copy `ls` there and make the new copy executable
         try Path.root.join("bin/ls").copy(into: Path.home.join(".local/bin").mkdir(.p)).chmod(0o500)

     If the destination does not exist, this function creates the directory
     (including intermediary directories if necessary) first.

     - Parameter into: Destination directory
     - Parameter overwrite: If true overwrites any file that already exists at `into`.
     - Returns: The `Path` of the newly copied file.
     - Note: `throws` if `into` is a file.
     - Note: Throws if `overwrite` is `false` yet `to` is *already* identical to
      `self` because even though *Path.swift’s* policy is to noop if the desired
       end result preexists, checking for this condition is too expensive a
       trade-off.
     - SeeAlso: `copy(to:overwrite:)`
     */
    @discardableResult
    func copy(into: Path, overwrite: Bool = false) throws -> Path {
        if !into.exists {
            try into.mkdir(.p)
        }
        let rv = into/basename()
        if overwrite, rv.isFile {
            try rv.delete()
        }
    #if os(Linux) && !swift(>=5.1) // check if fixed
        if !overwrite, rv.isFile {
            throw CocoaError.error(.fileWriteFileExists)
        }
    #endif
        try FileManager.default.copyItem(at: url, to: rv.url)
        return rv
    }

    /**
     Moves a file.

         try Path.root.join("bar").move(to: Path.home/"foo")
         // => "/Users/mxcl/foo"

     - Parameter to: Destination filename.
     - Parameter overwrite: If true overwrites any file that already exists at `to`.
     - Returns: `to` to allow chaining
     - Note: `throws` if `to` is a directory.
     - Note: Throws if `overwrite` is `false` yet `to` is *already* identical to
       `self` because even though *Path.swift’s* policy is to noop if the desired
       end result preexists, checking for this condition is too expensive a
       trade-off.
     - SeeAlso: `move(into:overwrite:)`
     */
    @discardableResult
    func move(to: Path, overwrite: Bool = false) throws -> Path {
        if overwrite, to.isFile {
            try FileManager.default.removeItem(at: to.url)
        }
        try FileManager.default.moveItem(at: url, to: to.url)
        return to
    }

    /**
     Moves a file into a directory

         try Path.root.join("bar").move(into: .home)
         // => "/Users/mxcl/bar"

     If the destination does not exist, this function creates the directory
     (including intermediary directories if necessary) first.

     - Parameter into: Destination directory
     - Parameter overwrite: If true *overwrites* any file that already exists at `into`.
     - Note: `throws` if `into` is a file.
     - Returns: The `Path` of destination filename.
     - SeeAlso: `move(to:overwrite:)`
     */
    @discardableResult
    func move(into: Path, overwrite: Bool = false) throws -> Path {
        if !into.exists {
            try into.mkdir(.p)
        } else if !into.isDirectory {
            throw CocoaError.error(.fileWriteFileExists)
        }
        let rv = into/basename()
        if overwrite, rv.isFile {
            try FileManager.default.removeItem(at: rv.url)
        }
        try FileManager.default.moveItem(at: url, to: rv.url)
        return rv
    }

    /**
     Deletes the path, recursively if a directory.
     - Note: noop: if the path doesn’t exist
     ∵ *Path.swift* doesn’t error if desired end result preexists.
     - Note: On UNIX will this function will succeed if the parent directory is writable and the current user has permission.
     - Note: This function will fail if the file or directory is “locked”
     - SeeAlso: `lock()`
    */
    @inlinable
    func delete() throws {
        if exists {
            try FileManager.default.removeItem(at: url)
        }
    }

    /**
     Creates an empty file at this path or if the file exists, updates its modification time.
     - Returns: `self` to allow chaining.
     */
    @inlinable
    @discardableResult
    func touch() throws -> Path {
        if !exists {
            guard FileManager.default.createFile(atPath: string, contents: nil) else {
                throw CocoaError.error(.fileWriteUnknown)
            }
        } else {
        #if os(Linux)
            let fd = open(string, O_WRONLY)
            defer { close(fd) }
            futimens(fd, nil)
        #else
            try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: string)
        #endif
        }
        return self
    }

    /**
     Creates the directory at this path.
     - Parameter options: Specify `mkdir(.p)` to create intermediary directories.
     - Note: We do not error if the directory already exists (even without `.p`)
       because *Path.swift* noops if the desired end result preexists.
     - Returns: `self` to allow chaining.
     */
    @discardableResult
    func mkdir(_ options: MakeDirectoryOptions? = nil) throws -> Path {
        do {
            let wid = options == .p
            try FileManager.default.createDirectory(at: self.url, withIntermediateDirectories: wid, attributes: nil)
        } catch CocoaError.Code.fileWriteFileExists {
            //noop (fails to trigger on Linux)
        } catch {
        #if os(Linux)
            let error = error as NSError
            guard error.domain == NSCocoaErrorDomain, error.code == CocoaError.Code.fileWriteFileExists.rawValue else {
                throw error
            }
        #else
            throw error
        #endif
        }
        return self
    }

    /**
     Renames the file at path.

         Path.root.foo.bar.rename(to: "baz")  // => /foo/baz

     - Parameter to: the new basename for the file
     - Returns: The renamed path.
     */
    @discardableResult
    func rename(to newname: String) throws -> Path {
        let newpath = parent/newname
        try FileManager.default.moveItem(atPath: string, toPath: newpath.string)
        return newpath
    }

    /**
     Creates a symlink of this file at `as`.
     - Note: If `self` does not exist, is **not** an error.
     */
    @discardableResult
    func symlink(as: Path) throws -> Path {
        try FileManager.default.createSymbolicLink(atPath: `as`.string, withDestinationPath: string)
        return `as`
    }

    /**
     Creates a symlink of this file with the same filename in the `into` directory.
     - Note: If into does not exist, creates the directory with intermediate directories if necessary.
     */
    @discardableResult
    func symlink(into dir: Path) throws -> Path {
        if !dir.exists {
            try dir.mkdir(.p)
        } else if !dir.isDirectory {
            throw CocoaError.error(.fileWriteFileExists)
        }
        let dst = dir/basename()
        try FileManager.default.createSymbolicLink(atPath: dst.string, withDestinationPath: string)
        return dst
    }
}

/// Options for `Path.mkdir(_:)`
public enum MakeDirectoryOptions {
    /// Creates intermediary directories; works the same as `mkdir -p`.
    case p
}
