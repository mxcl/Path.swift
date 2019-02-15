import Foundation
#if !os(Linux)
import func Darwin.realpath
let _realpath = Darwin.realpath
#else
import func Glibc.realpath
let _realpath = Glibc.realpath
#endif

/**
 A `Path` represents an absolute path on a filesystem.

 All functions on `Path` are chainable and short to facilitate doing sequences
 of file operations in a concise manner.

 `Path` supports `Codable`, and can be configured to
 [encode paths *relatively*](https://github.com/mxcl/Path.swift/#codable).

 Sorting a `Sequence` of paths will return the locale-aware sort order, which
 will give you the same order as Finder.

 Converting from a `String` is a common first step, here are the recommended
 ways to do that:

     let p1 = Path.root/pathString
     let p2 = Path.root/url.path
     let p3 = Path.cwd/relativePathString
     let p4 = Path(userInput) ?? Path.cwd/userInput

 If you are constructing paths from static-strings we provide support for
 dynamic members:

     let p1 = Path.root.usr.bin.ls  // => /usr/bin/ls

 - Note: A `Path` does not necessarily represent an actual filesystem entry.
 */

@dynamicMemberLookup
public struct Path: Equatable, Hashable, Comparable {

    init(string: String) {
        assert(string.first == "/")
        assert(string.last != "/" || string == "/")
        assert(string.split(separator: "/").contains("..") == false)
        self.string = string
    }

    /**
     Creates a new absolute, standardized path.
     - Note: Resolves any .. or . components.
     - Note: Removes multiple subsequent and trailing occurences of `/`.
     - Note: Does *not* resolve any symlinks.
     - Note: On macOS, removes an initial component of “/private/var/automount”, “/var/automount”, or “/private” from the path, if the result still indicates an existing file or directory (checked by consulting the file system).
     - Returns: The path or `nil` if fed a relative path or a `~foo` string where there is no user `foo`.
     */
    public init?(_ description: String) {
        var pathComponents = description.split(separator: "/")
        switch description.first {
        case "/":
            break
        case "~":
            if description == "~" {
                self = Path.home
                return
            }
            let tilded: String
            if description.hasPrefix("~/") {
                tilded = Path.home.string
            } else {
                let username = String(pathComponents[0].dropFirst())
            #if os(macOS) || os(Linux)
                if #available(OSX 10.12, *) {
                    guard let url = FileManager.default.homeDirectory(forUser: username) else { return nil }
                    assert(url.scheme == "file")
                    tilded = url.path
                } else {
                    guard let dir = NSHomeDirectoryForUser(username) else { return nil }
                    tilded = dir
                }
            #else
                return nil  // there are no usernames on iOS, etc.
            #endif
            }
            pathComponents.remove(at: 0)
            pathComponents.insert(contentsOf: tilded.split(separator: "/"), at: 0)
        default:
            return nil
        }

    #if os(macOS)
        func ifExists(withPrefix prefix: String, removeFirst n: Int) {
            assert(prefix.split(separator: "/").count == n)

            if description.hasPrefix(prefix), FileManager.default.fileExists(atPath: description) {
                pathComponents.removeFirst(n)
            }
        }

        ifExists(withPrefix: "/private/var/automount", removeFirst: 3)
        ifExists(withPrefix: "/var/automount", removeFirst: 2)
        ifExists(withPrefix: "/private", removeFirst: 1)
    #endif

        self.string = join_(prefix: "/", pathComponents: pathComponents)
    }

    /**
     Creates a new absolute, standardized path from the provided file-scheme URL.
     - Note: If the URL is not a file URL, returns `nil`.
    */
    public init?(url: URL) {
        guard url.scheme == "file" else { return nil }
        self.init(url.path)
        //NOTE: URL cannot be a file-reference url, unlike NSURL, so this always works
    }

    /**
     Creates a new absolute, standardized path from the provided file-scheme URL.
     - Note: If the URL is not a file URL, returns `nil`.
     - Note: If the URL is a file reference URL, converts it to a POSIX path first.
    */
    public init?(url: NSURL) {
        guard url.scheme == "file", let path = url.path else { return nil }
        self.init(string: path)
        // ^^ works even if the url is a file-reference url
    }

    /// :nodoc:
    public subscript(dynamicMember addendum: String) -> Path {
        //NOTE it’s possible for the string to be anything if we are invoked via
        // explicit subscript thus we use our fully sanitized `join` function
        return Path(string: join_(prefix: string, appending: addendum))
    }

//MARK: Properties

    /// The underlying filesystem path
    public let string: String

    /// Returns a `URL` representing this file path.
    public var url: URL {
        return URL(fileURLWithPath: string)
    }

    /**
     Returns a file-reference URL.
     - Note: Only NSURL can be a file-reference-URL, hence we return NSURL.
     - SeeAlso: https://developer.apple.com/documentation/foundation/nsurl/1408631-filereferenceurl
     - Important: On Linux returns an file scheme NSURL for this path string.
     */
    public var fileReferenceURL: NSURL? {
    #if !os(Linux)
        // https://bugs.swift.org/browse/SR-2728
        return (url as NSURL).perform(#selector(NSURL.fileReferenceURL))?.takeUnretainedValue() as? NSURL
    #else
        return NSURL(fileURLWithPath: string)
    #endif
    }

    /**
     Returns the parent directory for this path.

     Path is not aware of the nature of the underlying file, but this is
     irrlevant since the operation is the same irrespective of this fact.

     - Note: always returns a valid path, `Path.root.parent` *is* `Path.root`.
     */
    public var parent: Path {
        let index = string.lastIndex(of: "/")!
        let substr = string[string.indices.startIndex..<index]
        return Path(string: String(substr))
    }

    /**
     Returns the filename extension of this path.
     - Remark: If there is no extension returns "".
     - Remark: If the filename ends with any number of ".", returns "".
     - Note: We special case eg. `foo.tar.gz`.
     */
    @inlinable
    public var `extension`: String {
        //FIXME efficiency
        switch true {
        case string.hasSuffix(".tar.gz"):
            return "tar.gz"
        case string.hasSuffix(".tar.bz"):
            return "tar.bz"
        case string.hasSuffix(".tar.bz2"):
            return "tar.bz2"
        case string.hasSuffix(".tar.xz"):
            return "tar.xz"
        default:
            let slash = string.lastIndex(of: "/")!
            if let dot = string.lastIndex(of: "."), slash < dot {
                let foo = string.index(after: dot)
                return String(string[foo...])
            } else {
                return ""
            }
        }
    }

    /**
     Splits the string representation on the directory separator.
     - Important: The first element is always "/" to be consistent with `NSString.pathComponents`.
    */
    @inlinable
    public var components: [String] {
        return ["/"] + string.split(separator: "/").map(String.init)
    }

//MARK: Pathing

    /**
     Joins a path and a string to produce a new path.

         Path.root.join("a")             // => /a
         Path.root.join("a/b")           // => /a/b
         Path.root.join("a").join("b")   // => /a/b
         Path.root.join("a").join("/b")  // => /a/b

     - Note: `..` and `.` components are interpreted.
     - Note: pathComponent *may* be multiple components.
     - Note: symlinks are *not* resolved.
     - Parameter pathComponent: The string to join with this path.
     - Returns: A new joined path.
     - SeeAlso: `Path./(_:_:)`
     */
    public func join<S>(_ addendum: S) -> Path where S: StringProtocol {
        return Path(string: join_(prefix: string, appending: addendum))
    }

    /**
     Joins a path and a string to produce a new path.

         Path.root/"a"       // => /a
         Path.root/"a/b"     // => /a/b
         Path.root/"a"/"b"   // => /a/b
         Path.root/"a"/"/b"  // => /a/b

     - Note: `..` and `.` components are interpreted.
     - Note: pathComponent *may* be multiple components.
     - Note: symlinks are *not* resolved.
     - Parameter lhs: The base path to join with `rhs`.
     - Parameter rhs: The string to join with this `lhs`.
     - Returns: A new joined path.
     - SeeAlso: `join(_:)`
     */
    @inlinable
    public static func /<S>(lhs: Path, rhs: S) -> Path where S: StringProtocol {
        return lhs.join(rhs)
    }

    /**
     Returns a string representing the relative path to `base`.

     - Note: If `base` is not a logical prefix for `self` your result will be prefixed some number of `../` components.
     - Parameter base: The base to which we calculate the relative path.
     - ToDo: Another variant that returns `nil` if result would start with `..`
     */
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

    /**
     The basename for the provided file, optionally dropping the file extension.

         Path.root.join("foo.swift").basename()  // => "foo.swift"
         Path.root.join("foo.swift").basename(dropExtension: true)  // => "foo"

     - Returns: A string that is the filename’s basename.
     - Parameter dropExtension: If `true` returns the basename without its file extension.
     */
    public func basename(dropExtension: Bool = false) -> String {
        var lastPathComponent: Substring {
            let slash = string.lastIndex(of: "/")!
            let index = string.index(after: slash)
            return string[index...]
        }
        var go: Substring {
            if !dropExtension {
                return lastPathComponent
            } else {
                let ext = self.extension
                if !ext.isEmpty {
                    return lastPathComponent.dropLast(ext.count + 1)
                } else {
                    return lastPathComponent
                }
            }
        }
        return String(go)
    }

    /**
     If the path represents an actual entry that is a symlink, returns the symlink’s
     absolute destination.

     - Important: This is not exhaustive, the resulting path may still contain
     symlink.
     - Important: The path will only be different if the last path component is a
     symlink, any symlinks in prior components are not resolved.
     - Note: If file exists but isn’t a symlink, returns `self`.
     - Note: If symlink destination does not exist, is **not** an error.
     */
    public func readlink() throws -> Path {
        do {
            let rv = try FileManager.default.destinationOfSymbolicLink(atPath: string)
            return Path(rv) ?? parent/rv
        } catch CocoaError.fileReadUnknown {
            // file is not symlink, return `self`
            assert(exists)
            return self
        } catch {
        #if os(Linux)
            // ugh: Swift on Linux
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == CocoaError.fileReadUnknown.rawValue, exists {
                return self
            }
        #endif
            throw error
        }
    }

    /// Recursively resolves symlinks in this path.
    public func realpath() throws -> Path {
        guard let rv = _realpath(string, nil) else { throw CocoaError.error(.fileNoSuchFile) }
        defer { free(rv) }
        guard let rvv = String(validatingUTF8: rv) else { throw CocoaError.error(.fileReadUnknownStringEncoding) }

        // “Removing an initial component of “/private/var/automount”, “/var/automount”,
        // or “/private” from the path, if the result still indicates an existing file or
        // directory (checked by consulting the file system).”
        // ^^ we do this to not conflict with the results that other Apple APIs give
        // which is necessary if we are to have equality checks work reliably
        let rvvv = (rvv as NSString).standardizingPath

        return Path(string: rvvv)
    }

    /// Returns the locale-aware sort order for the two paths.
    /// :nodoc:
    @inlinable
    public static func <(lhs: Path, rhs: Path) -> Bool {
        return lhs.string.compare(rhs.string, locale: .current) == .orderedAscending
    }
}

@inline(__always)
private func join_<S>(prefix: String, appending: S) -> String where S: StringProtocol {
    return join_(prefix: prefix, pathComponents: appending.split(separator: "/"))
}

private func join_<S>(prefix: String, pathComponents: S) -> String where S: Sequence, S.Element: StringProtocol {
    assert(prefix.first == "/")

    var rv = prefix
    for component in pathComponents {

        assert(!component.contains("/"))

        switch component {
        case "..":
            let start = rv.indices.startIndex
            let index = rv.lastIndex(of: "/")!
            if start == index {
                rv = "/"
            } else {
                rv = String(rv[start..<index])
            }
        case ".":
            break
        default:
            if rv == "/" {
                rv = "/\(component)"
            } else {
                rv = "\(rv)/\(component)"
            }
        }
    }
    return rv
}
