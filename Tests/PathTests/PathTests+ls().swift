import XCTest
import Path

extension PathTests {
    func testFindMaxDepth0() throws {
    #if !os(Linux) || swift(>=5)
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.touch()
            try tmpdir.c.mkdir().join("e").touch()

            XCTAssertEqual(
                Set(tmpdir.find().maxDepth(0).execute()),
                Set([tmpdir.a, tmpdir.b, tmpdir.c].map(Path.init)))
        }
    #endif
    }

    func testFindMaxDepth1() throws {
    #if !os(Linux) || swift(>=5)
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.mkdir().join("c").touch()
            try tmpdir.b.d.mkdir().join("e").touch()

        #if !os(Linux)
            XCTAssertEqual(
                Set(tmpdir.find().maxDepth(1).execute()),
                Set([tmpdir.a, tmpdir.b, tmpdir.b.c].map(Path.init)))
        #else
            // Linux behavior is different :-/
            XCTAssertEqual(
                Set(tmpdir.find().maxDepth(1).execute()),
                Set([tmpdir.a, tmpdir.b, tmpdir.b.d, tmpdir.b.c].map(Path.init)))
        #endif
        }
    #endif
    }

    func testFindExtension() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.join("foo.json").touch()
            try tmpdir.join("bar.txt").touch()

            XCTAssertEqual(
                Set(tmpdir.find().extension("json").execute()),
                [tmpdir.join("foo.json")])
            XCTAssertEqual(
                Set(tmpdir.find().extension("txt").extension("json").execute()),
                [tmpdir.join("foo.json"), tmpdir.join("bar.txt")])
        }
    }

    func testFindKinds() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.foo.mkdir()
            try tmpdir.bar.touch()

            XCTAssertEqual(
                Set(tmpdir.find().kind(.file).execute()),
                [tmpdir.join("bar")])
            XCTAssertEqual(
                Set(tmpdir.find().kind(.directory).execute()),
                [tmpdir.join("foo")])
            XCTAssertEqual(
                Set(tmpdir.find().kind(.file).kind(.directory).execute()),
                Set(["foo", "bar"].map(tmpdir.join)))
        }
    }
}
