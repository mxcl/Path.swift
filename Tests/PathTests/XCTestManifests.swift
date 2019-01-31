import XCTest

extension PathTests {
    static let __allTests = [
        ("testBasename", testBasename),
        ("testBundleExtensions", testBundleExtensions),
        ("testCodable", testCodable),
        ("testCommonDirectories", testCommonDirectories),
        ("testConcatenation", testConcatenation),
        ("testCopyInto", testCopyInto),
        ("testCopyTo", testCopyTo),
        ("testDataExentsions", testDataExentsions),
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
        ("testMoveTo", testMoveTo),
        ("testRelativeCodable", testRelativeCodable),
        ("testRelativePathCodable", testRelativePathCodable),
        ("testRelativeTo", testRelativeTo),
        ("testRename", testRename),
        ("testStringConvertibles", testStringConvertibles),
        ("testStringExentsions", testStringExentsions),
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
