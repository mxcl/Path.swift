@testable import Path
import XCTest

class PathTests: XCTestCase {
    func testConcatenation() {
        XCTAssertEqual((Path.root/"bar").string, "/bar")
        XCTAssertEqual(Path.cwd.string, FileManager.default.currentDirectoryPath)
        XCTAssertEqual((Path.root/"/bar").string, "/bar")
        XCTAssertEqual((Path.root/"///bar").string, "/bar")
        XCTAssertEqual((Path.root/"foo///bar////").string, "/foo/bar")
        XCTAssertEqual((Path.root/"foo"/"/bar").string, "/foo/bar")

        XCTAssertEqual(Path.root.foo.bar.join(".."), Path.root.foo)
        XCTAssertEqual(Path.root.foo.bar.join("."), Path.root.foo.bar)
        XCTAssertEqual(Path.root.foo.bar.join("../baz"), Path.root.foo.baz)
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
        for prefix in [Path.root, Path.root.foo, Path.root.foo.bar] {
            XCTAssertEqual(prefix.join("a.swift").extension, "swift")
            XCTAssertEqual(prefix.join("a").extension, "")
            XCTAssertEqual(prefix.join("a.").extension, "")
            XCTAssertEqual(prefix.join("a..").extension, "")
            XCTAssertEqual(prefix.join("a..swift").extension, "swift")
            XCTAssertEqual(prefix.join("a..swift.").extension, "")
            XCTAssertEqual(prefix.join("a.tar.gz").extension, "tar.gz")
            XCTAssertEqual(prefix.join("a.tar.bz2").extension, "tar.bz2")
            XCTAssertEqual(prefix.join("a.tar.xz").extension, "tar.xz")
            XCTAssertEqual(prefix.join("a..tar.bz").extension, "tar.bz")
            XCTAssertEqual(prefix.join("a..tar..xz").extension, "xz")
        }
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
        for prefix in [Path.root, Path.root.foo, Path.root.foo.bar] {
            XCTAssertEqual(prefix.join("foo.bar").basename(dropExtension: true), "foo")
            XCTAssertEqual(prefix.join("foo").basename(dropExtension: true), "foo")
            XCTAssertEqual(prefix.join("foo.").basename(dropExtension: true), "foo.")
            XCTAssertEqual(prefix.join("foo.bar.baz").basename(dropExtension: true), "foo.bar")
        }
    }

    func testCodable() throws {
        let input = [Path.root.foo, Path.root.foo.bar, Path.root]
        XCTAssertEqual(try JSONDecoder().decode([Path].self, from: try JSONEncoder().encode(input)), input)
    }

    func testRelativePathCodable() throws {
        let root = Path.root.foo
        let input = [
            Path.root,
            root,
            root.bar
        ]

        let encoder = JSONEncoder()
        encoder.userInfo[.relativePath] = root
        let data = try encoder.encode(input)

        XCTAssertEqual(try JSONSerialization.jsonObject(with: data) as? [String], ["..", "", "bar"])

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
        XCTAssertEqual(Path("~"), Path.home)
        XCTAssertEqual(Path("~/"), Path.home)
        XCTAssertEqual(Path("~///"), Path.home)
        XCTAssertEqual(Path("/~///"), Path.root/"~")
        XCTAssertNil(Path("~foo"))
        XCTAssertNil(Path("~foo/bar"))

        XCTAssertEqual(Path("~\(NSUserName())"), Path.home)

        XCTAssertEqual(Path.root/"a/foo"/"../bar", Path.root/"a/bar")
        XCTAssertEqual(Path.root/"a/foo"/"/../bar", Path.root/"a/bar")
        XCTAssertEqual(Path.root/"a/foo"/"../../bar", Path.root/"bar")
        XCTAssertEqual(Path.root/"a/foo"/"../../../bar", Path.root/"bar")
    }

    func testDynamicMember() {
        XCTAssertEqual(Path.root.Documents, Path.root/"Documents")

        let a = Path.home.foo
        XCTAssertEqual(a.Documents, Path.home/"foo/Documents")

        // verify use of the dynamic-member-subscript works according to our rules
        XCTAssertEqual(Path.home[dynamicMember: "../~foo"].string, "\(Path.home.parent.string)/~foo")
    }

    func testCopyTo() throws {
        try Path.mktemp { root in
            try root.foo.touch().copy(to: root.bar)
            XCTAssert(root.foo.isFile)
            XCTAssert(root.bar.isFile)
            XCTAssertThrowsError(try root.foo.copy(to: root.bar))
            try root.foo.copy(to: root.bar, overwrite: true)
        }

        // test copy errors if directory exists at destination, even with overwrite
        try Path.mktemp { root in
            try root.foo.touch()
            XCTAssert(root.foo.isFile)
            XCTAssertThrowsError(try root.foo.copy(to: root.bar.mkdir()))
            XCTAssertThrowsError(try root.foo.copy(to: root.bar, overwrite: true))
        }
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

            // test creates intermediary directories
            try bar1.copy(into: root1.create.directories)

            // test doesn’t replace file if “copy into” a file
            let d = try root1.fuz.touch()
            XCTAssertThrowsError(try root1.baz.touch().copy(into: d))
            XCTAssert(d.isFile)
            XCTAssert(root1.baz.isFile)
        }
    }

    func testMoveTo() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.foo.touch().move(to: tmpdir.bar)
            XCTAssertFalse(tmpdir.foo.exists)
            XCTAssert(tmpdir.bar.isFile)
            XCTAssertThrowsError(try tmpdir.foo.touch().move(to: tmpdir.bar))
            try tmpdir.foo.move(to: tmpdir.bar, overwrite: true)
        }

        // test move errors if directory exists at destination, even with overwrite
        try Path.mktemp { root in
            try root.foo.touch()
            XCTAssert(root.foo.isFile)
            XCTAssertThrowsError(try root.foo.move(to: root.bar.mkdir()))
            XCTAssertThrowsError(try root.foo.move(to: root.bar, overwrite: true))
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

            // test creates intermediary directories
            try root1.baz.touch().move(into: root1.create.directories)
            XCTAssertFalse(root1.baz.exists)
            XCTAssert(root1.create.directories.baz.isFile)

            // test doesn’t replace file if “move into” a file
            let d = try root1.fuz.touch()
            XCTAssertThrowsError(try root1.baz.touch().move(into: d))
            XCTAssert(d.isFile)
            XCTAssert(root1.baz.isFile)
        }
    }

    func testRename() throws {
        try Path.mktemp { root in
            do {
                let file = try root.bar.touch()
                let foo = try file.rename(to: "foo")
                XCTAssertFalse(file.exists)
                XCTAssertTrue(foo.isFile)
            }
            do {
                let file = try root.bar.touch()
                XCTAssertThrowsError(try file.rename(to: "foo"))
            }
        }
    }

    func testCommonDirectories() {
        XCTAssertEqual(Path.root.string, "/")
        XCTAssertEqual(Path.home.string, NSHomeDirectory())
        XCTAssertEqual(Path.documents.string, NSHomeDirectory() + "/Documents")
    #if !os(Linux)
        XCTAssertEqual(Path.caches.string, NSHomeDirectory() + "/Library/Caches")
        XCTAssertEqual(Path.cwd.string, FileManager.default.currentDirectoryPath)
        XCTAssertEqual(Path.applicationSupport.string, NSHomeDirectory() + "/Library/Application Support")

        _ = defaultUrl(for: .documentDirectory)
        _ = defaultUrl(for: .cachesDirectory)
        _ = defaultUrl(for: .applicationSupportDirectory)
    #endif
    }

    func testStringConvertibles() {
        XCTAssertEqual(Path.root.description, "/")
        XCTAssertEqual(Path.root.debugDescription, "Path(/)")
    }

    func testFilesystemAttributes() throws {
        XCTAssert(Path(#file)!.isFile)
        XCTAssert(Path(#file)!.isReadable)
        XCTAssert(Path(#file)!.isWritable)
        XCTAssert(Path(#file)!.isDeletable)
        XCTAssert(Path(#file)!.parent.isDirectory)

        try Path.mktemp { tmpdir in
            XCTAssertTrue(tmpdir.isDirectory)
            XCTAssertFalse(tmpdir.isFile)

            let bar = try tmpdir.bar.touch().chmod(0o000)
            XCTAssertFalse(bar.isReadable)
            XCTAssertFalse(bar.isWritable)
            XCTAssertFalse(bar.isDirectory)
            XCTAssertFalse(bar.isExecutable)
            XCTAssertTrue(bar.isFile)
            XCTAssertTrue(bar.isDeletable)  // can delete even if no read permissions

            try bar.chmod(0o777)
            XCTAssertTrue(bar.isReadable)
            XCTAssertTrue(bar.isWritable)
            XCTAssertTrue(bar.isDeletable)
            XCTAssertTrue(bar.isExecutable)

            try bar.delete()
            XCTAssertFalse(bar.exists)
            XCTAssertFalse(bar.isReadable)
            XCTAssertFalse(bar.isWritable)
            XCTAssertFalse(bar.isExecutable)
            XCTAssertFalse(bar.isDeletable)

            let nonExistantFile = tmpdir.baz
            XCTAssertFalse(nonExistantFile.exists)
            XCTAssertFalse(nonExistantFile.isExecutable)
            XCTAssertFalse(nonExistantFile.isReadable)
            XCTAssertFalse(nonExistantFile.isWritable)
            XCTAssertFalse(nonExistantFile.isDeletable)
            XCTAssertFalse(nonExistantFile.isDirectory)
            XCTAssertFalse(nonExistantFile.isFile)

            let baz = try tmpdir.baz.touch()
            XCTAssertTrue(baz.isDeletable)
            try tmpdir.chmod(0o500)  // remove write permission on directory
            XCTAssertFalse(baz.isDeletable)  // this is how deletion is prevented on UNIX
        }
    }

    func testTimes() throws {
        try Path.mktemp { tmpdir in
            let foo = try tmpdir.foo.touch()
            let now1 = Date().timeIntervalSince1970.rounded(.down)
        #if !os(Linux)
            XCTAssertEqual(foo.ctime?.timeIntervalSince1970.rounded(.down), now1)  //FIXME flakey
        #endif
            XCTAssertEqual(foo.mtime?.timeIntervalSince1970.rounded(.down), now1)  //FIXME flakey
            sleep(1)
            try foo.touch()
            let now2 = Date().timeIntervalSince1970.rounded(.down)
            XCTAssertNotEqual(now1, now2)
            XCTAssertEqual(foo.mtime?.timeIntervalSince1970.rounded(.down), now2)  //FIXME flakey

            XCTAssertNil(tmpdir.void.mtime)
            XCTAssertNil(tmpdir.void.ctime)
        }
    }

    func testDelete() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.bar1.delete()
            try tmpdir.bar2.touch().delete()
            try tmpdir.bar3.touch().chmod(0o000).delete()
        #if !os(Linux)
            XCTAssertThrowsError(try tmpdir.bar3.touch().lock().delete())
        #endif
        }
    }

    func testRelativeCodable() throws {
        let path = Path.home.foo
        let encoder = JSONEncoder()
        encoder.userInfo[.relativePath] = Path.home
        let data = try encoder.encode([path])
        let decoder = JSONDecoder()
        decoder.userInfo[.relativePath] = Path.home
        XCTAssertEqual(try decoder.decode([Path].self, from: data), [path])
        decoder.userInfo[.relativePath] = Path.documents
        XCTAssertEqual(try decoder.decode([Path].self, from: data), [Path.documents.foo])
        XCTAssertThrowsError(try JSONDecoder().decode([Path].self, from: data))
    }

    func testBundleExtensions() throws {
        try Path.mktemp { tmpdir in
            let bndl = Bundle(path: tmpdir.string)!
            XCTAssertEqual(bndl.path, tmpdir)
            XCTAssertEqual(bndl.sharedFrameworks, tmpdir.SharedFrameworks)
            XCTAssertEqual(bndl.privateFrameworks, tmpdir.Frameworks)
            XCTAssertEqual(bndl.resources, tmpdir)
            XCTAssertNil(bndl.path(forResource: "foo", ofType: "bar"))

        #if os(macOS)
            XCTAssertEqual(bndl.defaultSharedFrameworksPath, tmpdir.Contents.Frameworks)
            XCTAssertEqual(bndl.defaultResourcesPath, tmpdir.Contents.Resources)
        #elseif os(tvOS) || os(iOS)
            XCTAssertEqual(bndl.defaultSharedFrameworksPath, tmpdir.Frameworks)
            XCTAssertEqual(bndl.defaultResourcesPath, tmpdir)
        #else
            XCTAssertEqual(bndl.defaultSharedFrameworksPath, tmpdir.lib)
            XCTAssertEqual(bndl.defaultResourcesPath, tmpdir.share)
        #endif
        }
    }

    func testDataExtensions() throws {
        let data = try Data(contentsOf: Path(#file)!)
        try Path.mktemp { tmpdir in
            _ = try data.write(to: tmpdir.foo)
            _ = try data.write(to: tmpdir.foo, atomically: true)
        }
    }

    func testStringExtensions() throws {
        let string = try String(contentsOf: Path(#file)!)
        try Path.mktemp { tmpdir in
            _ = try string.write(to: tmpdir.foo)
        }
    }

    func testFileHandleExtensions() throws {
        _ = try FileHandle(forReadingAt: Path(#file)!)
        _ = try FileHandle(forWritingAt: Path(#file)!)
        _ = try FileHandle(forUpdatingAt: Path(#file)!)
    }

    func testSort() {
        XCTAssertEqual([Path.root.a, Path.root.c, Path.root.b].sorted(), [Path.root.a, Path.root.b, Path.root.c])
    }

    func testLock() throws {
    #if !os(Linux)
        try Path.mktemp { tmpdir in
            let bar = try tmpdir.bar.touch()
            try bar.lock()
            XCTAssertThrowsError(try bar.touch())
            try bar.unlock()
            try bar.touch()

            // a non existant file is already “unlocked”
            try tmpdir.nonExit.unlock()
        }
    #endif
    }

    func testTouchThrowsIfCannotWrite() throws {
        try Path.mktemp { tmpdir in
            try tmpdir.chmod(0o000)
            XCTAssertThrowsError(try tmpdir.bar.touch())
        }
    }

    func testSymlinkFunctions() throws {
        try Path.mktemp { tmpdir in
            let foo = try tmpdir.foo.touch()
            let bar = try foo.symlink(as: tmpdir.bar)
            XCTAssert(bar.isSymlink)
            XCTAssertEqual(try bar.readlink(), foo)
        }

        try Path.mktemp { tmpdir in
            let foo1 = try tmpdir.foo.touch()
            let foo2 = try foo1.symlink(into: tmpdir.bar)
            XCTAssert(foo2.isSymlink)
            XCTAssert(tmpdir.bar.isDirectory)
            XCTAssertEqual(try foo2.readlink(), foo1)

            // cannot symlink into when `into` is an existing entry that is not a directory
            let baz = try tmpdir.baz.touch()
            XCTAssertThrowsError(try foo1.symlink(into: baz))
        }

        try Path.mktemp { tmpdir in
            let foo = try tmpdir.foo.touch()
            let bar = try tmpdir.bar.mkdir()
            XCTAssertThrowsError(try foo.symlink(as: bar))
            XCTAssert(try foo.symlink(as: bar.foo).isSymlink)
        }
    }

    func testReadlinkOnRelativeSymlink() throws {
        //TODO how to test on iOS etc.?
    #if os(macOS) || os(Linux)
        try Path.mktemp { tmpdir in
            let foo = try tmpdir.foo.mkdir()
            let bar = try tmpdir.bar.touch()

            let task = Process()
            task.currentDirectoryPath = foo.string
            task.launchPath = "/bin/ln"
            task.arguments = ["-s", "../bar", "baz"]
            task.launch()
            task.waitUntilExit()
            XCTAssertEqual(task.terminationStatus, 0)

            XCTAssert(tmpdir.foo.baz.isSymlink)

            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: tmpdir.foo.baz.string), "../bar")

            XCTAssertEqual(try tmpdir.foo.baz.readlink(), bar)
        }
    #endif
    }

    func testReadlinkOnFileReturnsSelf() throws {
        try Path.mktemp { tmpdir in
            XCTAssertEqual(try tmpdir.foo.touch(), tmpdir.foo)
            XCTAssertEqual(try tmpdir.foo.readlink(), tmpdir.foo)
        }
    }

    func testReadlinkOnNonExistantFileThrows() throws {
        try Path.mktemp { tmpdir in
            XCTAssertThrowsError(try tmpdir.bar.readlink())
        }
    }

    func testReadlinkWhereLinkDestinationDoesNotExist() throws {
        try Path.mktemp { tmpdir in
            let bar = try tmpdir.foo.symlink(as: tmpdir.bar)
            XCTAssertEqual(try bar.readlink(), tmpdir.foo)
        }
    }

    func testNoUndesiredSymlinkResolution() throws {

        // this test because NSString.standardizingPath will resolve symlinks
        // if the path you give it contains .. and the result is an actual entry

        try Path.mktemp { tmpdir in
            let foo = try tmpdir.foo.mkdir()
            try foo.bar.mkdir().fuz.touch()
            let baz = try foo.symlink(as: tmpdir.baz)
            XCTAssert(baz.isSymlink)
            XCTAssert(baz.bar.isDirectory)
            XCTAssertEqual(baz.bar.join("..").string, "\(tmpdir)/baz")

            XCTAssertEqual(Path("\(tmpdir)/baz/bar/..")?.string, "\(tmpdir)/baz")
        }
    }

    func testRealpath() throws {
        try Path.mktemp { tmpdir in
            let b = try tmpdir.a.b.mkdir(.p)
            let c = try tmpdir.a.c.touch()
            let e = try c.symlink(as: b.e)
            let f = try e.symlink(as: tmpdir.f)
            XCTAssertEqual(try f.readlink(), e)
            XCTAssertEqual(try f.realpath(), c)
        }

        try Path.mktemp { tmpdir in
            XCTAssertThrowsError(try tmpdir.foo.realpath())
        }
    }

    func testFileReference() throws {
        let ref = Path.home.fileReferenceURL
    #if !os(Linux)
        XCTAssertTrue(ref?.isFileReferenceURL() ?? false)
    #endif
        XCTAssertEqual(ref?.path, Path.home.string)
    }

    func testURLInitializer() throws {
        XCTAssertEqual(Path(url: Path.home.url), Path.home)
        XCTAssertEqual(Path.home.fileReferenceURL.flatMap(Path.init), Path.home)
        XCTAssertNil(Path(url: URL(string: "https://foo.com")!))
        XCTAssertNil(Path(url: NSURL(string: "https://foo.com")!))
    }

    func testInitializerForRelativePath() throws {
        XCTAssertNil(Path("foo"))
        XCTAssertNil(Path("../foo"))
        XCTAssertNil(Path("./foo"))
    }

    func testPathComponents() throws {
        XCTAssertEqual(Path.root.foo.bar.components, ["/", "foo", "bar"])
        XCTAssertEqual(Path.root.components, ["/"])
    }
}
