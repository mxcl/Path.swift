
/// A type that represents a filesystem path, if you conform your type
/// to `Pathish` it is your responsibility to ensure the string is correctly normalized
public protocol Pathish: Hashable, Comparable {
    /// The normalized string representation of the underlying filesystem path
    var string: String { get }
}

public extension Pathish {
    static func ==<P: Pathish> (lhs: Self, rhs: P) -> Bool {
        return lhs.string == rhs.string
    }
}
