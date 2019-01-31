import XCTest

extension PathTests {
    static let __allTests = [
        ("testBasename", testBasename),
        ("testBundleExtensions", testBundleExtensions),
        ("testCodable", testCodable),
        ("testCommonDirectories", testCommonDirectories),
        ("testConcatenation", testConcatenation),
        ("testCopyInto", testCopyInto),
        ("testDelete", testDelete),
        ("testDynamicMember", testDynamicMember),
        ("testEnumeration", testEnumeration),
        ("testEnumerationSkippingHiddenFiles", testEnumerationSkippingHiddenFiles),
        ("testExists", testExists),
        ("testExtension", testExtension),
        ("testFileHandleExtensions", testFileHandleExtensions),
        ("testFilesystemAttributes", testFilesystemAttributes),
        ("testIsDirectory", testIsDirectory),
        ("testJoin", testJoin),
        ("testMkpathIfExists", testMkpathIfExists),
        ("testMktemp", testMktemp),
        ("testMoveInto", testMoveInto),
        ("testRelativeCodable", testRelativeCodable),
        ("testRelativePathCodable", testRelativePathCodable),
        ("testRelativeTo", testRelativeTo),
        ("testRename", testRename),
        ("testStringConvertibles", testStringConvertibles),
        ("testTimes", testTimes),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PathTests.__allTests),
    ]
}
#endif
