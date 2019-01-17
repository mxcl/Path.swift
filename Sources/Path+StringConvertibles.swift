import class Foundation.NSString

extension Path: LosslessStringConvertible {
    /// Returns `nil` unless fed an absolute path
    public init?(_ description: String) {
        guard description.starts(with: "/") || description.starts(with: "~/") else { return nil }
        self.init(string: (description as NSString).standardizingPath)
    }
}

extension Path: CustomStringConvertible {
    public var description: String {
        return string
    }
}

extension Path: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Path(string: \(string))"
    }
}
