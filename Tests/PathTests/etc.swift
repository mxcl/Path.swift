import XCTest
import Path

#if swift(>=5.3)
func XCTAssertEqual<P: Pathish>(_ set1: Set<Path>, _ set2: Set<Path>, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, relativeTo: P) {
    logic(set1, set2, relativeTo: relativeTo) {
        XCTFail($0, file: file, line: line)
    }
}
#else
func XCTAssertEqual<P: Pathish>(_ set1: Set<Path>, _ set2: Set<Path>, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, relativeTo: P) {
    logic(set1, set2, relativeTo: relativeTo) {
        XCTFail($0, file: file, line: line)
    }
}
#endif

private func logic<P: Pathish>(_ set1: Set<Path>, _ set2: Set<Path>, relativeTo: P, fail: (String) -> Void) {
    if set1 != set2 {
        let cvt: (Path) -> String = { $0.relative(to: relativeTo) }
        let out1 = set1.map(cvt).sorted()
        let out2 = set2.map(cvt).sorted()
        fail("Set(\(out1)) is not equal to Set(\(out2))")
    }
}

#if swift(>=5.3)
func XCTAssertEqual<P: Pathish, Q: Pathish>(_ p: P, _ q: Q, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(p.string, q.string, file: file, line: line)
}

func XCTAssertEqual<P: Pathish, Q: Pathish>(_ p: P?, _ q: Q?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(p?.string, q?.string, file: file, line: line)
}
#else
func XCTAssertEqual<P: Pathish, Q: Pathish>(_ p: P, _ q: Q, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(p.string, q.string, file: file, line: line)
}

func XCTAssertEqual<P: Pathish, Q: Pathish>(_ p: P?, _ q: Q?, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(p?.string, q?.string, file: file, line: line)
}
#endif
