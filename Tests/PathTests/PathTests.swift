import XCTest
import Path

class PathTests: XCTestCase {
    func testConcatenation() {
        XCTAssertEqual((Path.root/"bar").string, "/bar")
        XCTAssertEqual(Path.cwd.string, FileManager.default.currentDirectoryPath)
        XCTAssertEqual((Path.root/"/bar").string, "/bar")
        XCTAssertEqual((Path.root/"///bar").string, "/bar")
        XCTAssertEqual((Path.root/"foo///bar////").string, "/foo/bar")
        XCTAssertEqual((Path.root/"foo"/"/bar").string, "/foo/bar")
    }

    func testEnumeration() throws {
        let tmpdir_ = try TemporaryDirectory()
        let tmpdir = tmpdir_.path
        try tmpdir.a.mkdir().c.touch()
        try tmpdir.join("b.swift").touch()
        try tmpdir.c.touch()
        try tmpdir.join(".d").mkdir().e.touch()

        var paths = Set<String>()
        let lsrv = try tmpdir.ls()
        var dirs = 0
        for entry in lsrv {
            if entry.kind == .directory {
                dirs += 1
            }
            paths.insert(entry.path.basename())
        }
        XCTAssertEqual(dirs, 2)
        XCTAssertEqual(dirs, lsrv.directories.count)
        XCTAssertEqual(["a", ".d"], Set(lsrv.directories.map{ $0.relative(to: tmpdir) }))
        XCTAssertEqual(["b.swift", "c"], Set(lsrv.files.map{ $0.relative(to: tmpdir) }))
        XCTAssertEqual(["b.swift"], Set(lsrv.files(withExtension: "swift").map{ $0.relative(to: tmpdir) }))
        XCTAssertEqual(["c"], Set(lsrv.files(withExtension: "").map{ $0.relative(to: tmpdir) }))
        XCTAssertEqual(paths, ["a", "b.swift", "c", ".d"])
        
    }

    func testEnumerationSkippingHiddenFiles() throws {
    #if !os(Linux)
        let tmpdir_ = try TemporaryDirectory()
        let tmpdir = tmpdir_.path
        try tmpdir.join("a").mkdir().join("c").touch()
        try tmpdir.join("b").touch()
        try tmpdir.join("c").touch()
        try tmpdir.join(".d").mkdir().join("e").touch()
        
        var paths = Set<String>()
        var dirs = 0
        for entry in try tmpdir.ls(includeHiddenFiles: false) {
            if entry.kind == .directory {
                dirs += 1
            }
            paths.insert(entry.path.basename())
        }
        XCTAssertEqual(dirs, 1)
        XCTAssertEqual(paths, ["a", "b", "c"])
    #endif
    }

    func testRelativeTo() {
        XCTAssertEqual((Path.root/"tmp/foo").relative(to: .root/"tmp"), "foo")
        XCTAssertEqual((Path.root/"tmp/foo/bar").relative(to: .root/"tmp/baz"), "../foo/bar")
    }

    func testExists() {
        XCTAssert(Path.root.exists)
        XCTAssert((Path.root/"bin").exists)
    }

    func testIsDirectory() {
        XCTAssert(Path.root.isDirectory)
        XCTAssert((Path.root/"bin").isDirectory)
    }

    func testExtension() {
        XCTAssertEqual(Path.root.join("a.swift").extension, "swift")
        XCTAssertEqual(Path.root.join("a").extension, "")
        XCTAssertEqual(Path.root.join("a.").extension, "")
        XCTAssertEqual(Path.root.join("a..").extension, "")
        XCTAssertEqual(Path.root.join("a..swift").extension, "swift")
        XCTAssertEqual(Path.root.join("a..swift.").extension, "")
        XCTAssertEqual(Path.root.join("a.tar.gz").extension, "tar.gz")
        XCTAssertEqual(Path.root.join("a..tar.gz").extension, "tar.gz")
        XCTAssertEqual(Path.root.join("a..tar..gz").extension, "gz")
    }

    func testMktemp() throws {
        var path: Path!
        try Path.mktemp {
            path = $0
            XCTAssert(path.isDirectory)
        }
        XCTAssert(!path.exists)
        XCTAssert(!path.isDirectory)
    }

    func testMkpathIfExists() throws {
        try Path.mktemp {
            for _ in 0...1 {
                try $0.join("a").mkdir()
                try $0.join("b/c").mkdir(.p)
            }
        }
    }

    func testBasename() {
        XCTAssertEqual(Path.root.join("foo.bar").basename(dropExtension: true), "foo")
        XCTAssertEqual(Path.root.join("foo").basename(dropExtension: true), "foo")
        XCTAssertEqual(Path.root.join("foo.").basename(dropExtension: true), "foo.")
        XCTAssertEqual(Path.root.join("foo.bar.baz").basename(dropExtension: true), "foo.bar")
    }

    func testCodable() throws {
        let input = [Path.root/"bar"]
        XCTAssertEqual(try JSONDecoder().decode([Path].self, from: try JSONEncoder().encode(input)), input)
    }

    func testRelativePathCodable() throws {
        let root = Path.root/"bar"
        let input = [
            root/"foo"
        ]

        let encoder = JSONEncoder()
        encoder.userInfo[.relativePath] = root
        let data = try encoder.encode(input)

        XCTAssertEqual(try JSONSerialization.jsonObject(with: data) as? [String], ["foo"])

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode([Path].self, from: data))
        decoder.userInfo[.relativePath] = root
        XCTAssertEqual(try decoder.decode([Path].self, from: data), input)
    }

    func testJoin() {
        let prefix = Path.root/"Users/mxcl"

        XCTAssertEqual(prefix/"b", Path("/Users/mxcl/b"))
        XCTAssertEqual(prefix/"b"/"c", Path("/Users/mxcl/b/c"))
        XCTAssertEqual(prefix/"b/c", Path("/Users/mxcl/b/c"))
        XCTAssertEqual(prefix/"/b", Path("/Users/mxcl/b"))
        let b = "b"
        let c = "c"
        XCTAssertEqual(prefix/b/c, Path("/Users/mxcl/b/c"))
        XCTAssertEqual(Path.root/"~b", Path("/~b"))
        XCTAssertEqual(Path.root/"~/b", Path("/~/b"))
        XCTAssertEqual(Path("~/foo"), Path.home/"foo")
        XCTAssertNil(Path("~foo"))

        XCTAssertEqual(Path.root/"a/foo"/"../bar", Path.root/"a/bar")
        XCTAssertEqual(Path.root/"a/foo"/"/../bar", Path.root/"a/bar")
        XCTAssertEqual(Path.root/"a/foo"/"../../bar", Path.root/"bar")
        XCTAssertEqual(Path.root/"a/foo"/"../../../bar", Path.root/"bar")
    }

    func testDynamicMember() {
        XCTAssertEqual(Path.root.Documents, Path.root/"Documents")

        let a = Path.home.foo
        XCTAssertEqual(a.Documents, Path.home/"foo/Documents")
    }

    func testCopyInto() throws {
        try Path.mktemp { root1 in
            let bar1 = try root1.join("bar").touch()
            try Path.mktemp { root2 in
                let bar2 = try root2.join("bar").touch()
                XCTAssertThrowsError(try bar1.copy(into: root2))
                try bar1.copy(into: root2, overwrite: true)
                XCTAssertTrue(bar1.exists)
                XCTAssertTrue(bar2.exists)
            }
        }
    }

    func testMoveInto() throws {
        try Path.mktemp { root1 in
            let bar1 = try root1.join("bar").touch()
            try Path.mktemp { root2 in
                let bar2 = try root2.join("bar").touch()
                XCTAssertThrowsError(try bar1.move(into: root2))
                try bar1.move(into: root2, overwrite: true)
                XCTAssertFalse(bar1.exists)
                XCTAssertTrue(bar2.exists)
            }
        }
    }

    func testRename() throws {
        try Path.mktemp { root in
            do {
                let file = try root.bar.touch()
                let foo = try file.rename("foo")
                XCTAssertFalse(file.exists)
                XCTAssertTrue(foo.isFile)
            }
            do {
                let file = try root.bar.touch()
                XCTAssertThrowsError(try file.rename("foo"))
            }
        }
    }
}
