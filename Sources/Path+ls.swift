import Foundation

public extension Path {
    /**
     Same as the `ls -a` command ∴ is ”shallow”
     - Parameter includeHiddenFiles: If `true`, hidden files are included in the results. Defaults to `true`.
     - Important: `includeHiddenFiles` does not work on Linux
     */
    func ls(includeHiddenFiles: Bool = true) throws -> [Entry] {
        var opts = FileManager.DirectoryEnumerationOptions()
    #if !os(Linux)
        if !includeHiddenFiles {
            opts.insert(.skipsHiddenFiles)
        }
    #endif
        let paths = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: opts)
        func convert(url: URL) -> Entry? {
            guard let path = Path(url.path) else { return nil }
            return Entry(kind: path.isDirectory ? .directory : .file, path: path)
        }
        return paths.compactMap(convert)
    }
}

public extension Array where Element == Path.Entry {
    /// Filters the list of entries to be a list of Paths that are directories.
    var directories: [Path] {
        return compactMap {
            $0.kind == .directory ? $0.path : nil
        }
    }

    /// Filters the list of entries to be a list of Paths that are files with the specified extension
    func files(withExtension ext: String) -> [Path] {
        return compactMap {
            $0.kind == .file && $0.path.extension == ext ? $0.path : nil
        }
    }
}
