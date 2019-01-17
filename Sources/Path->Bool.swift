import Foundation

public extension Path {
    var isWritable: Bool {
        return FileManager.default.isWritableFile(atPath: string)
    }

    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: string, isDirectory: &isDir) && isDir.boolValue
    }

    var isFile: Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: string, isDirectory: &isDir) && !isDir.boolValue
    }

    var isExecutable: Bool {
        return FileManager.default.isExecutableFile(atPath: string)
    }

    var exists: Bool {
        return FileManager.default.fileExists(atPath: string)
    }
}
