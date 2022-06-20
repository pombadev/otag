(lang dune 3.1)

(version 0.3)

(name otag)

; remove ugly `Dune__exe__` prefix
; https://dune.readthedocs.io/en/stable/dune-files.html#wrapped-executables-1
(wrapped_executables false)

; https://dune.readthedocs.io/en/stable/opam.html#opam-generation
(generate_opam_files true)

(license MIT)

(maintainers "Pomba Magar <pomba.magar@gmail.com>")

(authors "Pomba Magar <pomba.magar@gmail.com>")

(source
 (github pjmp/otag))

(package
 (name otag)
 (synopsis "Opinionated audio tag editor")
 (description "Otag is a commandline tool to edit meta data of various audio formats.

It supports both ID3v1 and ID3v2 for MP3 files, Ogg Vorbis
comments and ID3 tags and Vorbis comments in FLAC, MPC, Speex,
WavPack, TrueAudio, WAV, AIFF, MP4 and ASF files i.e whatever taglib
supports.
")
 (depends cmdliner taglib quests inquire fileutils)
 (tags
  (cli "mp3 tag editor")))
