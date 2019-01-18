import Foundation

extension Path {
    // helper to allow search path and domain mask to be passed in
    private static func pathFor(searchPathDirectory path: FileManager.SearchPathDirectory, domain: FileManager.SearchPathDomainMask = .userDomainMask) -> Path? {
        guard let pathString = FileManager.default.urls(for: path, in: .userDomainMask).last?.relativeString else {
            return nil
        }

        return Path(string: pathString)
    }

    public static var documents: Path? {
        return pathFor(searchPathDirectory: .documentDirectory)
    }

    public static var caches: Path? {
        return pathFor(searchPathDirectory: .cachesDirectory)
    }

    public static var applicationSupport: Path? {
        return pathFor(searchPathDirectory: .applicationSupportDirectory)
    }
}
