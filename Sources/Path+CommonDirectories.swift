import Foundation

extension Path {
    //MARK: Common Directories
    
    /// Returns a `Path` containing `FileManager.default.currentDirectoryPath`.
    public static var cwd: Path {
        return Path(string: FileManager.default.currentDirectoryPath)
    }

    /// Returns a `Path` representing the root path.
    public static var root: Path {
        return Path(string: "/")
    }

    /// Returns a `Path` representing the user’s home directory
    public static var home: Path {
        let string: String
      #if os(macOS)
        if #available(OSX 10.12, *) {
            string = FileManager.default.homeDirectoryForCurrentUser.path
        } else {
            string = NSHomeDirectory()
        }
      #else
        string = NSHomeDirectory()
      #endif
        return Path(string: string)
    }

    /// Helper to allow search path and domain mask to be passed in.
    private static func path(for searchPath: FileManager.SearchPathDirectory) -> Path {
    #if os(Linux)
        // the urls(for:in:) function is not implemented on Linux
        //TODO strictly we should first try to use the provided binary tool

        let foo = { ProcessInfo.processInfo.environment[$0].flatMap(Path.init) ?? $1 }

        switch searchPath {
        case .documentDirectory:
            return Path.home/"Documents"
        case .applicationSupportDirectory:
            return foo("XDG_DATA_HOME", Path.home/".local/share")
        case .cachesDirectory:
            return foo("XDG_CACHE_HOME", Path.home/".cache")
        default:
            fatalError()
        }
    #else    
        guard let pathString = FileManager.default.urls(for: searchPath, in: .userDomainMask).first?.path else { return defaultUrl(for: searchPath) }
        return Path(string: pathString)
    #endif
    }

    /**
     The root for user documents.
     - Note: There is no standard location for documents on Linux, thus we return `~/Documents`.
     - Note: You should create a subdirectory before creating any files.
     */
    public static var documents: Path {
        return path(for: .documentDirectory)
    }

    /**
     The root for cache files.
     - Note: On Linux this is `XDG_CACHE_HOME`.
     - Note: You should create a subdirectory before creating any files.
     */
    public static var caches: Path {
        return path(for: .cachesDirectory)
    }

    /**
     For data that supports your running application.
     - Note: On Linux is `XDG_DATA_HOME`.
     - Note: You should create a subdirectory before creating any files.
     */
    public static var applicationSupport: Path {
        return path(for: .applicationSupportDirectory)
    }
}

#if !os(Linux)
func defaultUrl(for searchPath: FileManager.SearchPathDirectory) -> Path {
    switch searchPath {
    case .documentDirectory:
        return Path.home/"Documents"
    case .applicationSupportDirectory:
        return Path.home/"Library/Application Support"
    case .cachesDirectory:
        return Path.home/"Library/Caches"
    default:
        fatalError()
    }
}
#endif

