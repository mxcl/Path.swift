import Foundation

public extension Path {
    /// Returns true if the path represents an actual file that is also writable by the current user.
    var isWritable: Bool {
        return FileManager.default.isWritableFile(atPath: string)
    }
    
    /// Returns true if the path represents an actual file that is also readable by the current user.
    var isReadable: Bool {
        return FileManager.default.isReadableFile(atPath: string)
    }
    
    /// Returns true if the path represents an actual file that is also deletable by the current user.
    var isDeletable: Bool {
        return FileManager.default.isDeletableFile(atPath: string)
    }

    /// Returns true if the path represents an actual directory.
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: string, isDirectory: &isDir) && isDir.boolValue
    }

    /// Returns true if the path represents an actual filesystem entry that is *not* a directory.
    var isFile: Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: string, isDirectory: &isDir) && !isDir.boolValue
    }

    /// Returns true if the path represents an actual file that is also executable by the current user.
    var isExecutable: Bool {
        return FileManager.default.isExecutableFile(atPath: string)
    }

    /// Returns true if the path represents an actual filesystem entry.
    var exists: Bool {
        return FileManager.default.fileExists(atPath: string)
    }
}
