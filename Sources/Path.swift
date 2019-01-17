import Foundation

public struct Path: Equatable, Hashable, Comparable {
    public let string: String

    public static var cwd: Path {
        return Path(string: FileManager.default.currentDirectoryPath)
    }

    public static var root: Path {
        return Path(string: "/")
    }

    public static var home: Path {
        return Path(string: NSHomeDirectory())
    }

    @inlinable
    public var `extension`: String {
        return (string as NSString).pathExtension
    }

    /// - Note: always returns a valid path, `Path.root.parent` *is* `Path.root`
    public var parent: Path {
        return Path(string: (string as NSString).deletingLastPathComponent)
    }

    @inlinable
    public var url: URL {
        return URL(fileURLWithPath: string)
    }

    public func basename(dropExtension: Bool = false) -> String {
        let str = string as NSString
        if !dropExtension {
            return str.lastPathComponent
        } else {
            let ext = str.pathExtension
            if !ext.isEmpty {
                return String(str.lastPathComponent.dropLast(ext.count + 1))
            } else {
                return str.lastPathComponent
            }
        }
    }

    //TODO another variant that returns `nil` if result would start with `..`
    public func relative(to base: Path) -> String {
        // Split the two paths into their components.
        // FIXME: The is needs to be optimized to avoid unncessary copying.
        let pathComps = (string as NSString).pathComponents
        let baseComps = (base.string as NSString).pathComponents

        // It's common for the base to be an ancestor, so try that first.
        if pathComps.starts(with: baseComps) {
            // Special case, which is a plain path without `..` components.  It
            // might be an empty path (when self and the base are equal).
            let relComps = pathComps.dropFirst(baseComps.count)
            return relComps.joined(separator: "/")
        } else {
            // General case, in which we might well need `..` components to go
            // "up" before we can go "down" the directory tree.
            var newPathComps = ArraySlice(pathComps)
            var newBaseComps = ArraySlice(baseComps)
            while newPathComps.prefix(1) == newBaseComps.prefix(1) {
                // First component matches, so drop it.
                newPathComps = newPathComps.dropFirst()
                newBaseComps = newBaseComps.dropFirst()
            }
            // Now construct a path consisting of as many `..`s as are in the
            // `newBaseComps` followed by what remains in `newPathComps`.
            var relComps = Array(repeating: "..", count: newBaseComps.count)
            relComps.append(contentsOf: newPathComps)
            return relComps.joined(separator: "/")
        }
    }

    public func join<S>(_ part: S) -> Path where S: StringProtocol {
        //TODO standardizingPath does more than we want really (eg tilde expansion)
        let str = (string as NSString).appendingPathComponent(String(part))
        return Path(string: (str as NSString).standardizingPath)
    }

    @inlinable
    public static func <(lhs: Path, rhs: Path) -> Bool {
        return lhs.string.compare(rhs.string, locale: .current) == .orderedAscending
    }

    public struct Entry {
        public enum Kind {
            case file
            case directory
        }
        public let kind: Kind
        public let path: Path
    }
}

@inlinable
public func /<S>(lhs: Path, rhs: S) -> Path where S: StringProtocol {
    return lhs.join(rhs)
}
