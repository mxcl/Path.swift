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
        ("testExtension", testExtension),
        ("testIsDirectory", testIsDirectory),
        ("testJoin", testJoin),
        ("testMkpathIfExists", testMkpathIfExists),
        ("testMktemp", testMktemp),
        ("testMoveInto", testMoveInto),
        ("testRelativePathCodable", testRelativePathCodable),
        ("testRelativeTo", testRelativeTo),
        ("testRename", testRename),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PathTests.__allTests),
    ]
}
#endif
