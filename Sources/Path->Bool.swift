import Foundation
#if os(Linux)
import func Glibc.access
#else
import Darwin
#endif

public extension Pathish {

    //MARK: Filesystem Properties

    /**
     - Returns: `true` if the path represents an actual filesystem entry.
     - Note: If `self` is a symlink the return value represents the destination, thus if the destination doesn’t exist this returns `false` even if the symlink exists.
     - Note: To determine if a symlink exists, use `.type`.
     */
    var exists: Bool {
        return FileManager.default.fileExists(atPath: string)
    }

    /// Returns true if the path represents an actual filesystem entry that is *not* a directory.
    var isFile: Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: string, isDirectory: &isDir) && !isDir.boolValue
    }

    /// Returns true if the path represents an actual directory.
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: string, isDirectory: &isDir) && isDir.boolValue
    }

    /// Returns true if the path represents an actual file that is also readable by the current user.
    var isReadable: Bool {
        return FileManager.default.isReadableFile(atPath: string)
    }

    /// Returns true if the path represents an actual file that is also writable by the current user.
    var isWritable: Bool {
        return FileManager.default.isWritableFile(atPath: string)
    }
        
    /// Returns true if the path represents an actual file that is also deletable by the current user.
    var isDeletable: Bool {
    #if os(Linux) && !swift(>=5.1)
        return exists && access(parent.string, W_OK) == 0
    #else
        // FileManager.isDeletableFile returns true if there is *not* a file there
        return exists && FileManager.default.isDeletableFile(atPath: string)
    #endif
    }

    /// Returns true if the path represents an actual file that is also executable by the current user.
    var isExecutable: Bool {
        if access(string, X_OK) == 0 {
            // FileManager.isExxecutableFile returns true even if there is *not*
            // a file there *but* if there was it could be *made* executable
            return FileManager.default.isExecutableFile(atPath: string)
        } else {
            return false
        }
    }

    /// Returns `true` if the file is a symbolic-link (symlink).
    var isSymlink: Bool {
        var sbuf = stat()
        lstat(string, &sbuf)
        return (sbuf.st_mode & S_IFMT) == S_IFLNK 
    }
}
