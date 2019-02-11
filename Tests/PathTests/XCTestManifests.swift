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
        ("testDataExtensions", testDataExtensions),
        ("testDelete", testDelete),
        ("testDynamicMember", testDynamicMember),
        ("testEnumeration", testEnumeration),
        ("testEnumerationSkippingHiddenFiles", testEnumerationSkippingHiddenFiles),
        ("testExists", testExists),
        ("testExtension", testExtension),
        ("testFileHandleExtensions", testFileHandleExtensions),
        ("testFileReference", testFileReference),
        ("testFilesystemAttributes", testFilesystemAttributes),
        ("testInitializerForRelativePath", testInitializerForRelativePath),
        ("testIsDirectory", testIsDirectory),
        ("testJoin", testJoin),
        ("testLock", testLock),
        ("testMkpathIfExists", testMkpathIfExists),
        ("testMktemp", testMktemp),
        ("testMoveInto", testMoveInto),
        ("testMoveTo", testMoveTo),
        ("testNoUndesiredSymlinkResolution", testNoUndesiredSymlinkResolution),
        ("testReadlinkOnFileReturnsSelf", testReadlinkOnFileReturnsSelf),
        ("testReadlinkOnNonExistantFileThrows", testReadlinkOnNonExistantFileThrows),
        ("testReadlinkOnRelativeSymlink", testReadlinkOnRelativeSymlink),
        ("testReadlinkWhereLinkDestinationDoesNotExist", testReadlinkWhereLinkDestinationDoesNotExist),
        ("testRealpath", testRealpath),
        ("testRelativeCodable", testRelativeCodable),
        ("testRelativePathCodable", testRelativePathCodable),
        ("testRelativeTo", testRelativeTo),
        ("testRename", testRename),
        ("testSort", testSort),
        ("testStringConvertibles", testStringConvertibles),
        ("testStringExtensions", testStringExtensions),
        ("testSymlinkFunctions", testSymlinkFunctions),
        ("testTimes", testTimes),
        ("testTouchThrowsIfCannotWrite", testTouchThrowsIfCannotWrite),
        ("testURLInitializer", testURLInitializer),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PathTests.__allTests),
    ]
}
#endif
