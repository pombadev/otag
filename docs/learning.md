# Hello Ocaml

# Introduction

For long time I wanted to get into functional language, with following criteria was the language needs to be:

- ML syntax
- Practical
- General purpose
- Static & strongly typed

We have lots of choices such as Haskell, Elm, PureScript, ReasonScript, Ocaml etc I decided to go with `ocaml`.

However, coming for languages with great dependencies management story such as Rust's `cargo`, JavaScript's `npm/yarn`, ocaml ecosystem seemed very confusing to me so i wrote this as a learning exercise for me and anyone with similar background and experience as mine.


# Getting Started
- [Official website](https://ocaml.org/)
- Cursory overview to get [up and running](https://archive.is/gQLxv).
- [OCamlverse](https://ocamlverse.github.io/)<br />
*OCamlverse is an effort to document everything worth knowing about OCaml.*

# Ocaml Ecosystem

### [Opam: Package manager](https://opam.ocaml.org/)

[Official getting started page](https://opam.ocaml.org/doc/Usage.html)

### Initialize project

```bash
opam switch create .

# or if switch was created already then
opam install .
```

### Install a package

```bash
opam install <package>
```

> Switch is needed to install package locally i.e in the current project's directory.


## [Dune: Build system](https://dune.build/)

[Official getting started page](https://dune.readthedocs.io/en/stable/quick-start.html)

### Initialize project

```bash
# initialize with lib, bin and test
dune init proj project_name
```

or one of:

```bash
# initialize project
dune init proj myproj --libs base,cmdliner --inline-tests --ppx ppx_inline_test

# initialize project as binary (executable)
dune init exe myexe --libs base,containers,notty --ppx ppx_deriving

# initialize project as a library
dune init lib mylib src --libs core --inline-tests --public
```

### Full example, taken mostly from [OPAM for npm/yarn users](https://ocamlverse.github.io/content/opam_npm.html)

```bash
dune init proj --kind=exe otag
cd otag
cat << EOF > otag.opam
opam-version: "2.0"
name: "otag"
authors: "Author"
homepage: "<url>"
maintainer: "<email>"
dev-repo: "git+https://<url>.git"
bug-reports: "<url>"
version: "0.1"
synopsis: "A synopsis"
description: "A description"
build: [
  [ "dune" "subst" ] {pinned}
  [ "dune" "build" "-p" name "-j" jobs ]
]
depends: [
  "dune" {build}
]
EOF
opam switch create . 4.14.0 --deps-only
eval $(opam env)
dune build
dune exec otag
```

> dune fails, with `cannot find the root`, please make sure your dune is at least 3.1.1, or create `dune-project` file

### Adding a dependency

```bash
opam install minicli

# edit dune file, opam file
```

Note: opam does not modify the `opam` file during (opam install <pkg>) – it has to be done by hand. This is as simple as adding the name of the package in the depends field.


```diff
- depends: [
-  "dune" {build}
-  "opam-lock" {dev}
-]
+ depends: [
+  "dune" {build}
+  "opam-lock" {dev}
+  "<package>"
+]
```

Depending on what project you are building eg `bin`/`lib`, edit the `<type>/dune` file too

```diff
-(executable
- (public_name otag)
- (name main))
+(executable
+ (public_name otag)
+ (name main)
+ (libraries <package>))
```

Tips:

```bash
# create switch of default ocaml's installation version

opam switch create . $(opam switch list | grep 'default' | cut -d' ' -f26 | grep -o '[0-9].*') --deps-only
```