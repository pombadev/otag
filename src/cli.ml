open Cmdliner

let format =
  let info =
    Arg.info [ "f"; "format" ] ~docv:"FORMAT"
      ~doc:"Format the input file(s) are in."
  in
  Arg.value (Arg.opt (Arg.some Arg.string) None info)

let path =
  let info =
    Arg.info [] ~docv:"PATH" ~doc:"Path to audio file(s) or folders(s)."
  in
  Arg.non_empty (Arg.pos_all Arg.file [] info)

let tree =
  Arg.(value & flag & info [ "t"; "tree-view" ] ~doc:"Visualize input as tree.")

let infer_from_path =
  Arg.(
    value
    & flag
    & info [ "i"; "infer-from-path" ]
        ~doc:
          {|
        Infer metadata from path.

        Files are expected to be in `Artist/Album/Track` file system.
        |})

let organize =
  let info =
    Arg.info [ "o"; "organize" ] ~docv:"DEST"
      ~doc:"Organize audio(s) to folders."
  in
  Arg.value (Arg.opt (Arg.some Arg.dir) None info)

let dry_run =
  let info =
    Arg.info [ "dry-run" ]
      ~doc:
        "Run the command without doing anything; just show what would happen."
  in
  Arg.value (Arg.flag info)

let documentation =
  let envs =
    [ Cmd.Env.info "NAPSTER_APIKEY" ~doc:"API key if napster is used" ]
  in
  let man =
    [
      `S Manpage.s_description;
      `P Opam.File.synopsis;
      `Noblank;
      `P Opam.File.description;
      `S Manpage.s_examples;
      `Pre "$(tname) test.mp3";
      `Noblank;
      `Pre "$(tname) test/";
      `Noblank;
      `Pre
        "$(tname) Artist-Album-01 Track.mp3 --format=artist-album-track_num \
         track";
      `S Manpage.s_environment;
      `S Manpage.s_authors;
      `P "Pomba Magar <pomba.magar@gmail.com>";
      `S Manpage.s_bugs;
      `P
        ("Improve docs, code and suggestions, bugs report at "
        ^ Opam.File.homepage);
      `S Manpage.s_see_also;
      `P "TagLib - https://taglib.org";
      `Noblank;
      `P "ocaml-taglib - https://github.com/savonet/ocaml-taglib";
    ]
  in
  (man, envs)

let main () =
  let cmd =
    let man, envs = documentation in
    let info =
      Cmd.info "otag" ~version:Opam.File.version ~doc:Opam.File.synopsis
        ~exits:[] ~man ~envs
    in
    Cmd.v info
      Term.(
        const Commands.run
        $ path
        $ format
        $ tree
        $ infer_from_path
        $ organize
        $ dry_run)
  in

  Cmd.eval cmd
