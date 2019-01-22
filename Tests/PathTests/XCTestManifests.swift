import XCTest

extension PathTests {
    static let __allTests = [
        ("testBasename", testBasename),
        ("testCodable", testCodable),
        ("testConcatenation", testConcatenation),
        ("testCopyInto", testCopyInto),
        ("testDynamicMember", testDynamicMember),
        ("testEnumeration", testEnumeration),
        ("testEnumerationSkippingHiddenFiles", testEnumerationSkippingHiddenFiles),
        ("testExists", testExists),
        ("testIsDirectory", testIsDirectory),
        ("testJoin", testJoin),
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
