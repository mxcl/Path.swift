import Foundation

public extension Path {
    /**
     A file entry from a directory listing.
     - SeeAlso: `ls()`
    */
    struct Entry {
        /// The kind of this directory entry.
        public enum Kind {
            /// The path is a file.
            case file
            /// The path is a directory.
            case directory
        }
        /// The kind of this entry.
        public let kind: Kind
        /// The path of this entry.
        public let path: Path
    }

    class Finder {
        fileprivate init(path: Path) {
            self.path = path
        }

        public let path: Path
        fileprivate(set) public var maxDepth: Int? = nil
        fileprivate(set) public var kinds: Set<Path.Kind>?
        fileprivate(set) public var extensions: Set<String>?
    }
}

public extension Path.Finder {
    /// Multiple calls will configure the Finder for the final depth call only.
    func maxDepth(_ maxDepth: Int) -> Path.Finder {
    #if os(Linux) && !swift(>=5.0)
        fputs("warning: maxDepth not implemented for Swift < 5\n", stderr)
    #endif
        self.maxDepth = maxDepth
        return self
    }

    /// Multiple calls will configure the Finder with multiple kinds.
    func kind(_ kind: Path.Kind) -> Path.Finder {
        kinds = kinds ?? []
        kinds!.insert(kind)
        return self
    }

    /// Multiple calls will configure the Finder with for multiple extensions
    func `extension`(_ ext: String) -> Path.Finder {
        extensions = extensions ?? []
        extensions!.insert(ext)
        return self
    }

    /// Enumerate and return all results, note that this may take a while since we are recursive.
    func execute() -> [Path] {
        var rv: [Path] = []
        execute{ rv.append($0); return .continue }
        return rv
    }

    /// The return type for `Path.Finder`
    enum ControlFlow {
        /// Stop enumerating this directory, return to the parent.
        case skip
        /// Stop enumerating all together.
        case abort
        /// Keep going.
        case `continue`
    }

    /// Enumerate, one file at a time.
    func execute(_ closure: (Path) throws -> ControlFlow) rethrows {
        guard let finder = FileManager.default.enumerator(atPath: path.string) else {
            fputs("warning: could not enumerate: \(path)\n", stderr)
            return
        }
        while let relativePath = finder.nextObject() as? String {
        #if !os(Linux) || swift(>=5.0)
            if let maxDepth = maxDepth, finder.level > maxDepth {
                finder.skipDescendants()
            }
        #endif
            let path = self.path/relativePath
            if path == self.path { continue }
            if let kinds = kinds, let kind = path.kind, !kinds.contains(kind) { continue }
            if let exts = extensions, !exts.contains(path.extension) { continue }

            switch try closure(path) {
            case .skip:
                finder.skipDescendants()
            case .abort:
                return
            case .continue:
                break
            }
        }
    }
}

public extension Pathish {    
    //MARK: Directory Listings

    /**
     Same as the `ls` command ∴ output is ”shallow” and unsorted.
     - Note: as per `ls`, by default we do *not* return hidden files. Specify `.a` for hidden files.
     - Parameter options: Configure the listing.
     - Important: On Linux the listing is always `ls -a`
     */
    func ls(_ options: ListDirectoryOptions? = nil) -> [Path.Entry] {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            fputs("warning: could not list: \(self)\n", stderr)
            return []
        }
        return urls.compactMap { url in
            guard let path = Path(url.path) else { return nil }
            if options != .a, path.basename().hasPrefix(".") { return nil }
            // ^^ we don’t use the Foundation `skipHiddenFiles` because it considers weird things hidden and we are mirroring `ls`
            return .init(kind: path.isDirectory ? .directory : .file, path: path)
        }
    }

    func find() -> Path.Finder {
        return .init(path: Path(self))
    }
}

/// Convenience functions for the array return value of `Path.ls()`
public extension Array where Element == Path.Entry {
    /// Filters the list of entries to be a list of Paths that are directories.
    var directories: [Path] {
        return compactMap {
            $0.kind == .directory ? $0.path : nil
        }
    }

    /// Filters the list of entries to be a list of Paths that are files.
    var files: [Path] {
        return compactMap {
            $0.kind == .file ? $0.path : nil
        }
    }

    /// Filters the list of entries to be a list of Paths that are files with the specified extension.
    func files(withExtension ext: String) -> [Path] {
        return compactMap {
            $0.kind == .file && $0.path.extension == ext ? $0.path : nil
        }
    }
}

/// Options for `Path.mkdir(_:)`
public enum ListDirectoryOptions {
    /// Creates intermediary directories; works the same as `mkdir -p`.
    case a
}
