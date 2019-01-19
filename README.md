# Path.swift ![badge-platforms] ![badge-languages] [![Build Status](https://travis-ci.com/mxcl/Path.swift.svg)](https://travis-ci.com/mxcl/Path.swift)

A file-system pathing library focused on developer experience and robust
end‐results.

```swift
import Path

// convenient static members
let home = Path.home

// pleasant joining syntax
let docs = Path.home/"Documents"

// paths are *always* absolute thus avoiding common bugs
let path = Path(userInput) ?? Path.cwd/userInput

// chainable syntax so you have less boilerplate
try Path.home.join("foo").mkpath().join("bar").touch().chmod(0o555)

// easy file-management
try Path.root.join("foo").copy(to: Path.root/"bar")

// careful API to avoid common bugs
try Path.root.join("foo").copy(into: Path.root.mkdir("bar"))
// ^^ other libraries would make the `to:` form handle both these cases
// but that can easily lead to bugs where you accidentally write files that
// were meant to be directory destinations
```

We emphasize safety and correctness, just like Swift, and also just
like Swift, we provide a thoughtful and comprehensive (yet concise) API.

# Support mxcl

Hi, I’m Max Howell and I have written a lot of open source software, and
probably you already use some of it (Homebrew anyone?). Please help me so I
can continue to make tools and software you need and love. I appreciate it x.

<a href="https://www.patreon.com/mxcl">
	<img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>

# Handbook

Our [online API documentation] is automatically updated for new releases.

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

However, often you want to encode relative paths:

```swift
let encoder = JSONEncoder()
encoder.userInfo[.relativePath] = Path.home
encoder.encode([Path.home, Path.home/"foo"])
```

```json
[
    "",
    "foo",
]
```

**Note** make sure you decode with this key set *also*, otherwise we `fatal`
(unless the paths are absolute obv.)

```swift
let decoder = JSONDecoder()
decoder.userInfo[.relativePath] = Path.home
decoder.decode(from: data)
```

## Initializing from user-input

The `Path` initializer returns `nil` unless fed an absolute path; thus to
initialize from user-input that may contain a relative path use this form:

```swift
let path = Path(userInput) ?? Path.cwd/userInput
```

This is explicit, not hiding anything that code-review may miss and preventing
common bugs like accidentally creating `Path` objects from strings you did not
expect to be relative.

## Extensions

We have some extensions to Apple APIs:

```swift
let bashProfile = try String(contentsOf: Path.home/".bash_profile")
let history = try Data(contentsOf: Path.home/".history")

bashProfile += "\n\nfoo"

try bashProfile.write(to: Path.home/".bash_profile")

try Bundle.main.resources!.join("foo").copy(to: .home)
// ^^ `-> Path?` because the underlying `Bundle` function is `-> String?`
```

## Directory listings

We provide `ls()`, called because it behaves like the Terminal `ls` function,
the name thus implies its behavior, ie. that it is not recursive.

```swift
for entry in Path.home.ls() {
    print(entry.path)
    print(entry.kind)  // .directory or .file
}

for entry in Path.home.ls() where entry.kind == .file {
    //…
}

for entry in Path.home.ls() where entry.path.mtime > yesterday {
    //…
}

let dirs = Path.home.ls().directories().filter {
    //…
}

let swiftFiles = Path.home.ls().files(withExtension: "swift")
```

# Rules & Caveats

Paths are just string representations, there *might not* be a real file there.

```swift
Path.home/"b"      // => /Users/mxcl/b

// joining multiple strings works as you’d expect
Path.home/"b"/"c"  // => /Users/mxcl/b/c

// joining multiple parts at a time is fine
Path.home/"b/c"    // => /Users/mxcl/b/c

// joining with absolute paths omits prefixed slash
Path.home/"/b"     // => /Users/mxcl/b

// of course, feel free to join variables:
let b = "b"
let c = "c"
Path.home/b/c      // => /Users/mxcl/b/c

// tilde is not special here
Path.root/"~b"     // => /~b
Path.root/"~/b"    // => /~/b

// but is here
Path("~/foo")!     // => /Users/foo

// this does not work though
Path("~foo")       // => nil
```

# Installation

SwiftPM only:

```swift
package.append(.package(url: "https://github.com/mxcl/Path.swift", from: "0.0.0"))
```

### Get push notifications for new releases

https://codebasesaga.com/canopy/


[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg
[badge-languages]: https://img.shields.io/badge/swift-4.2-orange.svg
[online API documentation]: https://mxcl.github.io/Path.swift/
