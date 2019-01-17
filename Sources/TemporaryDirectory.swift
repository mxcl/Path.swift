import Foundation

public class TemporaryDirectory {
    public let url: URL
    public var path: Path { return Path(string: url.path) }

    public init() throws {
    #if !os(Linux)
        url = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: "/"), create: true)
    #else
        let envs = ProcessInfo.processInfo.environment
        let env = envs["TMPDIR"] ?? envs["TEMP"] ?? envs["TMP"] ?? "/tmp"
        let dir = Path.root/env/"swift-sh.XXXXXX"
        var template = [UInt8](dir.string.utf8).map({ Int8($0) }) + [Int8(0)]
        guard mkdtemp(&template) != nil else { throw CocoaError.error(.featureUnsupported) }
        url = URL(fileURLWithPath: String(cString: template))
    #endif
    }

    deinit {
        _ = try? FileManager.default.removeItem(at: url)
    }
}

public extension Path {
    static func mktemp<T>(body: (Path) throws -> T) throws -> T {
        let tmp = try TemporaryDirectory()
        return try body(tmp.path)
    }
}
