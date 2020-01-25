import XCTest
import Path

func XCTAssertEqual<P: Pathish>(_ set1: Set<Path>, _ set2: Set<Path>, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, relativeTo: P) {
    if set1 != set2 {
        let cvt: (Path) -> String = { $0.relative(to: relativeTo) }
        let out1 = set1.map(cvt).sorted()
        let out2 = set1.map(cvt).sorted()
        XCTFail("Set(\(out1)) is not equal to Set(\(out2))", file: file, line: line)
    }
}
