# Path.swift

A file-system pathing library focused on developer experience and robust
end‐results.

```swift
// convenient static members
let home = Path.home

// pleasant joining syntax
let docs = Path.home/"Documents"

// paths are *always* absolute thus avoiding common bugs
let path = Path(userInput) ?? Path.cwd/userInput

// chainable syntax so you have less boilerplate
try Path.home.join("foo").mkpath().join("bar").chmod(0o555)

// easy file-management
try Path.root.join("foo").copy(to: Path.root.join("bar"))

// careful API to avoid common bugs
try Path.root.join("foo").copy(into: Path.root.mkdir("bar"))
// ^^ other libraries would make the `to:` form handle both these cases
// but that can easily lead to bugs where you accidentally write files that
// were meant to be directory destinations
```

Paths are just string representations, there *may not* be a real file there.

# Support mxcl

Hi, I’m Max Howell and I have written a lot of open source software, and
probably you already use some of it (Homebrew anyone?). Please help me so I
can continue to make tools and software you need and love. I appreciate it x.

<a href="https://www.patreon.com/mxcl">
	<img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>

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
for path in Path.home.ls() {
    print(path.path)
    print(path.kind)  // .directory or .file
}

for path in Path.home.ls() where path.kind == .file {
    //…
}

for path in Path.home.ls() where path.mtime > yesterday {
    //…
}

let dirs = Path.home.ls().directories().filter {
    //…
}

let swiftFiles = Path.home.ls().files(withExtension: "swift")
```

# Installation

SwiftPM only:

```swift
package.append(.package(url: "https://github.com/mxcl/Path.swift", from: "0.0.0"))
```

### Get push notifications for new releases

https://codebasesaga.com/canopy/
