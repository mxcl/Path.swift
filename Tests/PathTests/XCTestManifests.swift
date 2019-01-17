import XCTest

extension PathTests {
    static let __allTests = [
        ("testBasename", testBasename),
        ("testCodable", testCodable),
        ("testConcatenation", testConcatenation),
        ("testEnumeration", testEnumeration),
        ("testExists", testExists),
        ("testIsDirectory", testIsDirectory),
        ("testMkpathIfExists", testMkpathIfExists),
        ("testMktemp", testMktemp),
        ("testRelativePathCodable", testRelativePathCodable),
        ("testRelativeTo", testRelativeTo),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PathTests.__allTests),
    ]
}
#endif
