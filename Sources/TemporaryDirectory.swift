import Foundation

public class TemporaryDirectory {
    public let url: URL
    public var path: Path { return Path(string: url.path) }

    public init() throws {
        url = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: "/"), create: true)
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
