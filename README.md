# otag
> opinionated audio metadata editor

`otag` is a audio metadata editor written in OCaml using [taglib](https://taglib.org).

# Prerequisites

- [taglib](https://taglib.org)
- [opam](https://opam.ocaml.org)

# Installation

### From the source

```bash
git clone https://github.com/pjmp/otag.git

cd otag

opam switch create . 4.14.0 --deps-only

eval $(opam env)

dune build

dune exec otag -- --help
```

# From opam

To be published

# Motivations

This is a beginners project exploring ocaml and it's ecosystem.

For more info please checkout [learnings](./learning.md).
