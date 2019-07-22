import Foundation

public extension Path {
    /// The builder for `Path.find()`
    class Finder {
        fileprivate init(path: Path) {
            self.path = path
        }

        /// The `path` find operations operate on.
        public let path: Path
        /// The maximum directory depth find operations will dip. Zero means no subdirectories.
        fileprivate(set) public var maxDepth: Int? = nil
        /// The kinds of filesystem entries find operations will return.
        fileprivate(set) public var kinds: Set<Path.Kind>?
        /// The file extensions find operations will return. Files *and* directories unless you filter for `kinds`.
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
    /**
     Same as the `ls` command ∴ output is ”shallow” and unsorted.
     - Note: as per `ls`, by default we do *not* return hidden files. Specify `.a` for hidden files.
     - Parameter options: Configure the listing.
     - Important: On Linux the listing is always `ls -a`
     */
    func ls(_ options: ListDirectoryOptions? = nil) -> [Path] {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            fputs("warning: could not list: \(self)\n", stderr)
            return []
        }
        return urls.compactMap { url in
            guard let path = Path(url.path) else { return nil }
            if options != .a, path.basename().hasPrefix(".") { return nil }
            // ^^ we don’t use the Foundation `skipHiddenFiles` because it considers weird things hidden and we are mirroring `ls`
            return path
        }
    }

    /// Recursively find files under this path. If the path is a file, no files will be found.
    func find() -> Path.Finder {
        return .init(path: Path(self))
    }
}

/// Convenience functions for the arraies of `Path`
public extension Array where Element == Path {
    /// Filters the list of entries to be a list of Paths that are directories. Symlinks to directories are not returned.
    var directories: [Path] {
        return filter {
            $0.isDirectory
        }
    }

    /// Filters the list of entries to be a list of Paths that exist and are *not* directories. Thus expect symlinks, etc.
    /// - Note: symlinks that point to files that do not exist are *not* returned.
    var files: [Path] {
        return filter {
            $0.exists && !$0.isDirectory
        }
    }
}

/// Options for `Path.ls(_:)`
public enum ListDirectoryOptions {
    /// Creates intermediary directories; works the same as `mkdir -p`.
    case a
}
