import XCTest
import Path

extension PathTests {
    func testFindMaxDepth1() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.touch()
            try tmpdir.c.mkdir().join("e").touch()

            do {
                let finder = tmpdir.find().depth(max: 1)
                XCTAssertEqual(finder.depth, 1...1)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(Set(finder), Set([tmpdir.a, tmpdir.b, tmpdir.c].map(Path.init)))
              #endif
            }
            do {
                let finder = tmpdir.find().depth(max: 0)
                XCTAssertEqual(finder.depth, 0...0)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(Set(finder), Set())
              #endif
            }
        }
    }

    func testFindMaxDepth2() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.mkdir().join("c").touch()
            try tmpdir.b.d.mkdir().join("e").touch()

            do {
                let finder = tmpdir.find().depth(max: 2)
                XCTAssertEqual(finder.depth, 1...2)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.a, tmpdir.b, tmpdir.b.d, tmpdir.b.c].map(Path.init)))
              #endif
            }
            do {
                let finder = tmpdir.find().depth(max: 3)
                XCTAssertEqual(finder.depth, 1...3)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.a, tmpdir.b, tmpdir.b.d, tmpdir.b.c, tmpdir.b.d.e].map(Path.init)))
              #endif
            }
        }
    }

    func testFindExtension() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.join("foo.json").touch()
            try tmpdir.join("bar.txt").touch()

            XCTAssertEqual(
                Set(tmpdir.find().extension("json")),
                [tmpdir.join("foo.json")])
            XCTAssertEqual(
                Set(tmpdir.find().extension("txt").extension("json")),
                [tmpdir.join("foo.json"), tmpdir.join("bar.txt")])
        }
    }

    func testFindKinds() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.foo.mkdir()
            try tmpdir.bar.touch()

            XCTAssertEqual(
                Set(tmpdir.find().type(.file)),
                [tmpdir.join("bar")])
            XCTAssertEqual(
                Set(tmpdir.find().type(.directory)),
                [tmpdir.join("foo")])
            XCTAssertEqual(
                Set(tmpdir.find().type(.file).type(.directory)),
                Set(["foo", "bar"].map(tmpdir.join)))
        }
    }
}
