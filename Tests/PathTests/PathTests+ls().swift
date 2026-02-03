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

    func testFindMinDepth() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.mkdir().join("c").touch()
            try tmpdir.b.d.mkdir().join("e").touch()
            try tmpdir.b.d.f.mkdir().join("g").touch()

            do {
                let finder = tmpdir.find().depth(min: 2)
                XCTAssertEqual(finder.depth, 2...Int.max)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.b.c, tmpdir.b.d, tmpdir.b.d.e, tmpdir.b.d.f, tmpdir.b.d.f.g].map(Path.init)),
                    relativeTo: tmpdir)
              #endif
            }
        }
    }

    func testFindDepth0() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.mkdir().join("c").touch()
            try tmpdir.b.d.mkdir().join("e").touch()
            try tmpdir.b.d.f.mkdir().join("g").touch()

            do {
                let finder = tmpdir.find().depth(min: 0)
                XCTAssertEqual(finder.depth, 0...Int.max)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.a, tmpdir.b, tmpdir.b.c, tmpdir.b.d, tmpdir.b.d.e, tmpdir.b.d.f, tmpdir.b.d.f.g].map(Path.init)),
                    relativeTo: tmpdir)
              #endif
            }
            do {
                // this should work, even though it’s weird
                let finder = tmpdir.find().depth(min: -1)
                XCTAssertEqual(finder.depth, 0...Int.max)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.a, tmpdir.b, tmpdir.b.c, tmpdir.b.d, tmpdir.b.d.e, tmpdir.b.d.f, tmpdir.b.d.f.g].map(Path.init)),
                    relativeTo: tmpdir)
              #endif
            }
        }
    }

    func testFindDepthRange() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.mkdir().join("c").touch()
            try tmpdir.b.d.mkdir().join("e").touch()
            try tmpdir.b.d.f.mkdir().join("g").touch()

            do {
                let range = 2...3
                let finder = tmpdir.find().depth(range)
                XCTAssertEqual(finder.depth, range)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.b.d, tmpdir.b.c, tmpdir.b.d.e, tmpdir.b.d.f].map(Path.init)),
                    relativeTo: tmpdir)
              #endif
            }

            do {
                let range = 2..<4
                let finder = tmpdir.find().depth(range)
                XCTAssertEqual(finder.depth, 2...3)
              #if !os(Linux) || swift(>=5)
                XCTAssertEqual(
                    Set(finder),
                    Set([tmpdir.b.d, tmpdir.b.c, tmpdir.b.d.e, tmpdir.b.d.f].map(Path.init)),
                    relativeTo: tmpdir)
              #endif
            }
        }
    }

    func testFindHidden() throws {
        try Path.mktemp { tmpdir in
            let dotFoo = try tmpdir.join(".foo.txt").touch()
            let tmpDotA = try tmpdir.join(".a").mkdir()
            let tmpDotAFoo = try tmpdir.join(".a").join("foo.txt").touch()
            let tmpB = try tmpdir.b.mkdir()
            let tmpBFoo = try tmpdir.b.join("foo.txt").touch()

            XCTAssertEqual(
                Set(tmpdir.find().hidden(true)),
                Set([dotFoo,tmpDotA,tmpDotAFoo,tmpB,tmpBFoo]),
                relativeTo: tmpdir)
            
            #if !os(Linux) || swift(>=5)
            XCTAssertEqual(
                Set(tmpdir.find().hidden(false)),
                Set([tmpB,tmpBFoo]),
                relativeTo: tmpdir)
            #endif
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

    //NOTE this is how iterators work, so we have a test to validate that behavior
    func testFindCallingExecuteTwice() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.join("foo.json").touch()
            try tmpdir.join("bar.txt").touch()

            let finder = tmpdir.find()

            XCTAssertEqual(finder.map{ $0 }.count, 2)
            XCTAssertEqual(finder.map{ $0 }.count, 0)
        }
    }

    func testFindExecute() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.a.touch()
            try tmpdir.b.mkdir().join("c").touch()
            try tmpdir.b.d.mkdir().join("e").touch()
            try tmpdir.b.d.f.mkdir().join("g").touch()
          #if !os(Linux) || swift(>=5)
            do {
                var rv = Set<Path>()

                tmpdir.find().execute {
                    switch $0 {
                        case Path(tmpdir.b.d): return .skip
                        default:
                            rv.insert($0)
                            return .continue
                    }
                }

                XCTAssertEqual(rv, Set([tmpdir.a, tmpdir.b, tmpdir.b.c].map(Path.init)))
            }
          #endif
            do {
                var x = 0

                tmpdir.find().execute { _ in
                    x += 1
                    return .abort
                }

                XCTAssertEqual(x, 1)
            }
        }
    }

    func testFindTypes() throws {
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

    func testLsOnNonexistentDirectoryReturnsEmptyArray() throws {
        try Path.mktemp { tmpdir in
            XCTAssertEqual(tmpdir.a.ls(), [])
        }
    }

    func testFindOnNonexistentDirectoryHasNoContent() throws {
        try Path.mktemp { tmpdir in
            XCTAssertNil(tmpdir.a.find().next())
        }
    }
    
    func testLsUnsortedOption() throws {
        try Path.mktemp { tmpdir in
            // Create files with names that would be sorted differently
            try tmpdir.join("zebra.txt").touch()
            try tmpdir.join("apple.txt").touch()
            try tmpdir.join("banana.txt").touch()
            
            // Test default (sorted) behavior
            let sortedResults = tmpdir.ls()
            XCTAssertEqual(sortedResults.count, 3)
            XCTAssertEqual(sortedResults[0].basename(), "apple.txt")
            XCTAssertEqual(sortedResults[1].basename(), "banana.txt")
            XCTAssertEqual(sortedResults[2].basename(), "zebra.txt")
            
            // Test unsorted behavior - just verify we get all files, order doesn't matter
            let unsortedResults = tmpdir.ls(.unsorted)
            XCTAssertEqual(unsortedResults.count, 3)
            XCTAssertTrue(unsortedResults.contains(tmpdir.join("apple.txt")))
            XCTAssertTrue(unsortedResults.contains(tmpdir.join("banana.txt")))
            XCTAssertTrue(unsortedResults.contains(tmpdir.join("zebra.txt")))
        }
    }
    
    func testLsUnsortedWithHidden() throws {
        try Path.mktemp { tmpdir in
            // Create regular and hidden files
            try tmpdir.join("visible.txt").touch()
            try tmpdir.join(".hidden.txt").touch()
            try tmpdir.join("another.txt").touch()
            
            // Test .a (sorted with hidden)
            let sortedWithHidden = tmpdir.ls(.a)
            XCTAssertEqual(sortedWithHidden.count, 3)
            XCTAssertEqual(sortedWithHidden[0].basename(), ".hidden.txt")
            XCTAssertEqual(sortedWithHidden[1].basename(), "another.txt")
            XCTAssertEqual(sortedWithHidden[2].basename(), "visible.txt")
            
            // Test .aUnsorted (unsorted with hidden)
            let unsortedWithHidden = tmpdir.ls(.aUnsorted)
            XCTAssertEqual(unsortedWithHidden.count, 3)
            XCTAssertTrue(unsortedWithHidden.contains(tmpdir.join("visible.txt")))
            XCTAssertTrue(unsortedWithHidden.contains(tmpdir.join(".hidden.txt")))
            XCTAssertTrue(unsortedWithHidden.contains(tmpdir.join("another.txt")))
            
            // Test .unsorted (unsorted without hidden)
            let unsortedNoHidden = tmpdir.ls(.unsorted)
            XCTAssertEqual(unsortedNoHidden.count, 2)
            XCTAssertTrue(unsortedNoHidden.contains(tmpdir.join("visible.txt")))
            XCTAssertTrue(unsortedNoHidden.contains(tmpdir.join("another.txt")))
            XCTAssertFalse(unsortedNoHidden.contains(tmpdir.join(".hidden.txt")))
        }
    }
}
