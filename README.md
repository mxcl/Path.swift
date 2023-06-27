# Path.swift ![badge-platforms][] ![badge-languages][] [![badge-ci][]][travis] [![badge-jazzy][]][docs] [![badge-codecov][]][codecov] [![badge-version][]][cocoapods]

A file-system pathing library focused on developer experience and robust end
results.

```swift
import Path

// convenient static members
let home = Path.home

// pleasant joining syntax
let docs = Path.home/"Documents"

// paths are *always* absolute thus avoiding common bugs
let path = Path(userInput) ?? Path.cwd/userInput

// elegant, chainable syntax
try Path.home.join("foo").mkdir().join("bar").touch().chmod(0o555)

// sensible considerations
try Path.home.join("bar").mkdir()
try Path.home.join("bar").mkdir()  // doesn’t throw ∵ we already have the desired result

// easy file-management
let bar = try Path.root.join("foo").copy(to: Path.root/"bar")
print(bar)         // => /bar
print(bar.isFile)  // => true

// careful API considerations so as to avoid common bugs
let foo = try Path.root.join("foo").copy(into: Path.root.join("bar").mkdir())
print(foo)         // => /bar/foo
print(foo.isFile)  // => true
// ^^ the `into:` version will only copy *into* a directory, the `to:` version copies
// to a file at that path, thus you will not accidentally copy into directories you
// may not have realized existed.

// we support dynamic-member-syntax when joining named static members, eg:
let prefs = Path.home.Library.Preferences  // => /Users/mxcl/Library/Preferences

// a practical example: installing a helper executable
try Bundle.resources.helper.copy(into: Path.root.usr.local.bin).chmod(0o500)
```

We emphasize safety and correctness, just like Swift, and also (again like
Swift), we provide a thoughtful and comprehensive (yet concise) API.

# Sponsor @mxcl

Hi, I’m Max Howell and I have written a lot of open source software—generally
a good deal of my free time 👨🏻‍💻. Sponsorship helps me justify creating new open
source and maintaining it. Thank you.

[Sponsor @mxcl].

# Handbook

Our [online API documentation][docs] covers 100% of our public API and is
automatically updated for new releases.

## Codable

We support `Codable` as you would expect:

```swift
try JSONEncoder().encode([Path.home, Path.home/"foo"])
```

```json
[
    "/Users/mxcl",
    "/Users/mxcl/foo",
]
```

Though we recommend encoding *relative* paths‡:

```swift
let encoder = JSONEncoder()
encoder.userInfo[.relativePath] = Path.home
encoder.encode([Path.home, Path.home/"foo", Path.home/"../baz"])
```

```json
[
    "",
    "foo",
    "../baz"
]
```

**Note** if you encode with this key set you *must* decode with the key
set also:

```swift
let decoder = JSONDecoder()
decoder.userInfo[.relativePath] = Path.home
try decoder.decode(from: data)  // would throw if `.relativePath` not set
```

> ‡ If you are saving files to a system provided location, eg. Documents then
> the directory could change at Apple’s choice, or if say the user changes their
> username. Using relative paths also provides you with the flexibility in
> future to change where you are storing your files without hassle.

## Dynamic members

We support `@dynamicMemberLookup`:

```swift
let ls = Path.root.usr.bin.ls  // => /usr/bin/ls
```

We only provide this for “starting” function, eg. `Path.home` or `Bundle.path`.
This is because we found in practice it was easy to write incorrect code, since
everything would compile if we allowed arbituary variables to take *any* named
property as valid syntax. What we have is what you want most of the time but
much less (potentially) dangerous (at runtime).

### Pathish

`Path`, and `DynamicPath` (the result of eg. `Path.root`) both conform to
`Pathish` which is a protocol that contains all pathing functions. Thus if
you create objects from a mixture of both you need to create generic
functions or convert any `DynamicPath`s to `Path` first:

```swift
let path1 = Path("/usr/lib")!
let path2 = Path.root.usr.bin
var paths = [Path]()
paths.append(path1)        // fine
paths.append(path2)        // error
paths.append(Path(path2))  // ok
```

This is inconvenient but as Swift stands there’s nothing we can think of
that would help.

## Initializing from user-input

The `Path` initializer returns `nil` unless fed an absolute path; thus to
initialize from user-input that may contain a relative path use this form:

```swift
let path = Path(userInput) ?? Path.cwd/userInput
```

This is explicit, not hiding anything that code-review may miss and preventing
common bugs like accidentally creating `Path` objects from strings you did not
expect to be relative.

Our initializer is nameless to be consistent with the equivalent operation for
converting strings to `Int`, `Float` etc. in the standard library.

## Initializing from known strings

There’s no need to use the optional initializer in general if you have known
strings that you need to be paths:

```swift
let absolutePath = "/known/path"
let path1 = Path.root/absolutePath

let pathWithoutInitialSlash = "known/path"
let path2 = Path.root/pathWithoutInitialSlash

assert(path1 == path2)

let path3 = Path(absolutePath)!  // at your options

assert(path2 == path3)

// be cautious:
let path4 = Path(pathWithoutInitialSlash)!  // CRASH!
```

## Extensions

We have some extensions to Apple APIs:

```swift
let bashProfile = try String(contentsOf: Path.home/".bash_profile")
let history = try Data(contentsOf: Path.home/".history")

bashProfile += "\n\nfoo"

try bashProfile.write(to: Path.home/".bash_profile")

try Bundle.main.resources.join("foo").copy(to: .home)
```

## Directory listings

We provide `ls()`, called because it behaves like the Terminal `ls` function,
the name thus implies its behavior, ie. that it is not recursive and doesn’t
list hidden files.

```swift
for path in Path.home.ls() {
    //…
}

for path in Path.home.ls() where path.isFile {
    //…
}

for path in Path.home.ls() where path.mtime > yesterday {
    //…
}

let dirs = Path.home.ls().directories
// ^^ directories that *exist*

let files = Path.home.ls().files
// ^^ files that both *exist* and are *not* directories

let swiftFiles = Path.home.ls().files.filter{ $0.extension == "swift" }

let includingHiddenFiles = Path.home.ls(.a)
```

**Note** `ls()` does not throw, instead outputing a warning to the console if it
fails to list the directory. The rationale for this is weak, please open a
ticket for discussion.

We provide `find()` for recursive listing:

```swift
for path in Path.home.find() {
    // descends all directories, and includes hidden files by default
    // so it behaves the same as the terminal command `find`
}
```

It is configurable:

```swift
for path in Path.home.find().depth(max: 1).extension("swift").type(.file).hidden(false) {
    //…
}
```

It can be controlled with a closure syntax:

```swift
Path.home.find().depth(2...3).execute { path in
    guard path.basename() != "foo.lock" else { return .abort }
    if path.basename() == ".build", path.isDirectory { return .skip }
    //…
    return .continue
}
```

Or get everything at once as an array:

```swift
let paths = Path.home.find().map(\.self)
```

# `Path.swift` is robust

Some parts of `FileManager` are not exactly idiomatic. For example
`isExecutableFile` returns `true` even if there is no file there, it is instead
telling you that *if* you made a file there it *could* be executable. Thus we
check the POSIX permissions of the file first, before returning the result of
`isExecutableFile`. `Path.swift` has done the leg-work for you so you can just
get on with it and not have to worry.

There is also some magic going on in Foundation’s filesystem APIs, which we look
for and ensure our API is deterministic, eg. [this test].

[this test]: https://github.com/mxcl/Path.swift/blob/master/Tests/PathTests/PathTests.swift#L539-L554

# `Path.swift` is properly cross-platform

`FileManager` on Linux is full of holes. We have found the holes and worked
round them where necessary.

# Rules & Caveats

Paths are just (normalized) string representations, there *might not* be a real
file there.

```swift
Path.home/"b"      // => /Users/mxcl/b

// joining multiple strings works as you’d expect
Path.home/"b"/"c"  // => /Users/mxcl/b/c

// joining multiple parts simultaneously is fine
Path.home/"b/c"    // => /Users/mxcl/b/c

// joining with absolute paths omits prefixed slash
Path.home/"/b"     // => /Users/mxcl/b

// joining with .. or . works as expected
Path.home.foo.bar.join("..")  // => /Users/mxcl/foo
Path.home.foo.bar.join(".")   // => /Users/mxcl/foo/bar

// though note that we provide `.parent`:
Path.home.foo.bar.parent      // => /Users/mxcl/foo

// of course, feel free to join variables:
let b = "b"
let c = "c"
Path.home/b/c      // => /Users/mxcl/b/c

// tilde is not special here
Path.root/"~b"     // => /~b
Path.root/"~/b"    // => /~/b

// but is here
Path("~/foo")!     // => /Users/mxcl/foo

// this works provided the user `Guest` exists
Path("~Guest")     // => /Users/Guest

// but if the user does not exist
Path("~foo")       // => nil

// paths with .. or . are resolved
Path("/foo/bar/../baz")  // => /foo/baz

// symlinks are not resolved
Path.root.bar.symlink(as: "foo")
Path("/foo")        // => /foo
Path.root.foo       // => /foo

// unless you do it explicitly
try Path.root.foo.readlink()  // => /bar
                              // `readlink` only resolves the *final* path component,
                              // thus use `realpath` if there are multiple symlinks
```

*Path.swift* has the general policy that if the desired end result preexists,
then it’s a noop:

* If you try to delete a file, but the file doesn't exist, we do nothing.
* If you try to make a directory and it already exists, we do nothing.
* If you call `readlink` on a non-symlink, we return `self`

However notably if you try to copy or move a file without specifying `overwrite`
and the file already exists at the destination and is identical, we don’t check
for that as the check was deemed too expensive to be worthwhile.

## Symbolic links

* Two paths may represent the same *resolved* path yet not be equal due to
    symlinks in such cases you should use `realpath` on both first if an
    equality check is required.
* There are several symlink paths on Mac that are typically automatically
    resolved by Foundation, eg. `/private`, we attempt to do the same for
    functions that you would expect it (notably `realpath`), we *do* the same
    for `Path.init`, but *do not* if you are joining a path that ends up being
    one of these paths, (eg. `Path.root.join("var/private')`).

If a `Path` is a symlink but the destination of the link does not exist `exists`
returns `false`. This seems to be the correct thing to do since symlinks are
meant to be an abstraction for filesystems. To instead verify that there is
no filesystem entry there at all check if `type` is `nil`.


## We do not provide change directory functionality

Changing directory is dangerous, you should *always* try to avoid it and thus
we don’t even provide the method. If you are executing a sub-process then
use `Process.currentDirectoryURL` to change *its* working directory when it
executes.

If you must change directory then use `FileManager.changeCurrentDirectory` as
early in your process as *possible*. Altering the global state of your app’s
environment is fundamentally dangerous creating hard to debug issues that
you won‘t find for potentially *years*.

# I thought I should only use `URL`s?

Apple recommend this because they provide a magic translation for
[file-references embodied by URLs][file-refs], which gives you URLs like so:

    file:///.file/id=6571367.15106761

Therefore, if you are not using this feature you are fine. If you have URLs the
correct way to get a `Path` is:

```swift
if let path = Path(url: url) {
    /*…*/
}
```

Our initializer calls `path` on the URL which resolves any reference to an
actual filesystem path, however we also check the URL has a `file` scheme first.

[file-refs]: https://developer.apple.com/documentation/foundation/nsurl/1408631-filereferenceurl

# In defense of our naming scheme

Chainable syntax demands short method names, thus we adopted the naming scheme
of the terminal, which is absolutely not very “Apple” when it comes to how they
design their APIs, however for users of the terminal (which *surely* is most
developers) it is snappy and familiar.

# Installation

SwiftPM:

```swift
package.append(
    .package(url: "https://github.com/mxcl/Path.swift.git", from: "1.0.0")
)

package.targets.append(
    .target(name: "Foo", dependencies: [
        .product(name: "Path", package: "Path.swift")
    ])
)
```

CocoaPods:

```ruby
pod 'Path.swift', '~> 1.0.0'
```

Carthage:

> Waiting on: [@Carthage#1945](https://github.com/Carthage/Carthage/pull/1945).

# Naming Conflicts with `SwiftUI.Path`, etc.

We have a typealias of `PathStruct` you can use instead.

# Alternatives

* [Pathos](https://github.com/dduan/Pathos) by Daniel Duan
* [PathKit](https://github.com/kylef/PathKit) by Kyle Fuller
* [Files](https://github.com/JohnSundell/Files) by John Sundell
* [Utility](https://github.com/apple/swift-package-manager) by Apple


[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg
[badge-languages]: https://img.shields.io/badge/swift-4.2%20%7C%205.x-orange.svg
[docs]: https://mxcl.dev/Path.swift/Structs/Path.html
[badge-jazzy]: https://raw.githubusercontent.com/mxcl/Path.swift/gh-pages/badge.svg?sanitize=true
[badge-codecov]: https://codecov.io/gh/mxcl/Path.swift/branch/master/graph/badge.svg
[badge-ci]: https://github.com/mxcl/Path.swift/workflows/Checks/badge.svg
[travis]: https://travis-ci.com/mxcl/Path.swift
[codecov]: https://codecov.io/gh/mxcl/Path.swift
[badge-version]: https://img.shields.io/cocoapods/v/Path.swift.svg?label=version
[cocoapods]: https://cocoapods.org/pods/Path.swift
[Sponsor @mxcl]: https://github.com/sponsors/mxcl
