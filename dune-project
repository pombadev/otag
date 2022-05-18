(lang dune 3.1)

(version 0.1)

(name hello_ocaml)

; remove ugly `Dune__exe__` prefix
; https://dune.readthedocs.io/en/stable/dune-files.html#wrapped-executables-1

(wrapped_executables false)

; https://dune.readthedocs.io/en/stable/opam.html#opam-generation

(generate_opam_files true)

(license MIT)

(maintainers "Pomba Magar <pomba.magar@gmail.com>")

(authors "Pomba Magar <pomba.magar@gmail.com>")

(source
 (github pjmp/hello_ocaml))

(package
 (name hello_ocaml)
 (synopsis "Beginner's guide to Ocaml ecosystem")
 (depends cmdliner taglib)
 (tags
  (cli "mp3 tag editor"))
 (description "Beginner's guide to Ocaml ecosystem"))
