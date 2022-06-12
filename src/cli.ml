open Cmdliner

let format =
  let info =
    Arg.info [ "f"; "format" ] ~docv:"FORMAT"
      ~doc:"Format the input file(s) are in"
  in
  Arg.value (Arg.opt (Arg.some Arg.string) None info)

let path =
  let info =
    Arg.info [] ~docv:"PATH" ~doc:"Path to audio file(s) or folders(s)"
  in
  Arg.non_empty (Arg.pos_all Arg.file [] info)

let tree =
  Arg.(
    value & flag
    & info [ "t"; "tree-view" ] ~docv:"TREE" ~doc:"visualize input as tree")

let infer_from_path =
  Arg.(
    value & flag
    & info [ "I"; "infer-from-path" ] ~docv:"INFER"
        ~doc:"Infer metadata from path")

let documentation =
  let man =
    [
      `S Manpage.s_description;
      `P
        "$(tname) is a commandline tool to edit meta data of various audio \
         formats.";
      `Noblank;
      `P
        "Currently it supports both ID3v1 and ID3v2 for MP3 files, Ogg Vorbis \
         comments and ID3 tags and Vorbis comments in FLAC, MPC, Speex, \
         WavPack, TrueAudio, WAV, AIFF, MP4 and ASF files.";
      `S Manpage.s_examples;
      `Pre "$(tname) test.mp3";
      `Noblank;
      `Pre "$(tname) test/";
      `Noblank;
      `Pre
        "$(tname) Artist-Album-01 Track.mp3 --format=artist-album-track_num \
         track";
      `S Manpage.s_authors;
      `P "Pomba Magar <pomba.magar@gmail.com>";
      `S Manpage.s_bugs;
      `P
        "Improve docs, code and suggestions, bugs report at \
         https://github.com/pjmp/otag";
      `S Manpage.s_see_also;
      `P "TagLib - https://taglib.org";
      `Noblank;
      `P "ocaml-taglib - https://github.com/savonet/ocaml-taglib";
    ]
  in
  let doc = "opinionated audio tag editor" in
  (man, doc)

let cmd =
  let man, doc = documentation in
  let info = Cmd.info "otag" ~version:"0.1" ~doc ~man in
  Cmd.v info Term.(const Commands.run $ path $ format $ tree $ infer_from_path)

let main () = Cmd.eval cmd
