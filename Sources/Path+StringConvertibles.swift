extension Path: CustomStringConvertible {    
    /// Returns `Path.string`
    public var description: String {
        return string
    }
}

extension Path: CustomDebugStringConvertible {
    /// Returns eg. `Path(string: "/foo")`
    public var debugDescription: String {
        return "Path(\(string))"
    }
}

extension DynamicPath: CustomStringConvertible {
    /// Returns `Path.string`
    public var description: String {
        return string
    }
}

extension DynamicPath: CustomDebugStringConvertible {
    /// Returns eg. `Path(string: "/foo")`
    public var debugDescription: String {
        return "Path(\(string))"
    }
}
