/// A type that represents a filesystem path, if you conform your type
/// to `Pathish` it is your responsibility to ensure the string is correctly normalized
public protocol Pathish: Hashable, Comparable {
    /// The normalized string representation of the underlying filesystem path
    var string: String { get }
}
