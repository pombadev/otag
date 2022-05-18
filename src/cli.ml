open Cmdliner

let dirwalk path =
  Printf.printf "[dirwalk]: %s\n" path;

  let rec loop p =
    match p with
    | [] -> []
    | h :: t ->
        Printf.printf "curr: %s\n" h;
        loop t
  in

  let is_dir =
    try Sys.is_directory path
    with _ ->
      (* let msg = Printexc.to_string err and stack = Printexc.get_backtrace () in
         Printf.eprintf "Error: %s\n%s\n" msg stack; *)
      (* Sys.file_exists path *)
      false
  in

  let f =
    match is_dir with
    | true -> Sys.readdir path |> Array.to_list |> loop
    | false ->
        Printf.printf "%s is a file\n" path;
        []
  in

  ignore f
(* match is_dir with
   | true ->
       (* Printf.printf "path: %s\n" path; *)
       Sys.readdir path
       |> Array.iter (fun dir ->
              Printf.printf "%s is a dir\n" dir;
              dirwalk dir)
   | false -> Printf.printf "%s is a file\n" path; *)

let run path format group =
  Printf.printf "path = %s\nformat = %s\ngroup = %b\n" (String.concat ", " path)
    (match format with
    | Some f -> Printf.sprintf "%s" f
    | None -> Printf.sprintf "Default format")
    group;

  (* let a =
       List.map
         (fun con ->
           let ret =
             if Sys.is_directory con then Sys.readdir con else Array.make 1 con
           in
           ret |> Array.to_list |> List.map (fun x -> x))
         path
     in
     (); *)
  path |> List.iter dirwalk;

  (* let a = Taglib.file_type; *)
  match group with
  | true ->
      (* dirwalk path (fun p -> print_endline p); *)
      print_endline "grouping..";

      path
      |> List.iter (fun p ->
             if Sys.is_directory p then
               Sys.readdir p |> Array.iter (fun c -> print_endline c)
             else
               try
                 let f = Taglib.File.open_file `Autodetect p in
                 let prop = Taglib.File.properties f in
                 Hashtbl.iter
                   (fun t v ->
                     let v = String.concat " / " v in
                     Printf.printf " - %s : %s\n%!" t v)
                   prop;
                 Taglib.File.close_file f
               with err ->
                 let msg = Printexc.to_string err
                 and stack = Printexc.get_backtrace () in
                 Printf.eprintf "Error: %s\n%s\n" msg stack)
  | false ->
      print_endline "do other stuffs..";

      (* let f = Taglib.File.open_file `Autodetect (List.hd p) in
         let prop = Taglib.File.properties f in
         Hashtbl.iter
           (fun t v ->
             let v = String.concat " / " v in
             Printf.printf " - %s : %s\n%!" t v)
           prop;
         Taglib.File.close_file f; *)
      ()

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

let group =
  Arg.(
    value & flag
    & info [ "g"; "group-view" ] ~docv:"GROUP" ~doc:"group input by artist")

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
  Cmd.v info Term.(const run $ path $ format $ group)

let main () =
  Printexc.record_backtrace true;
  Cmd.eval cmd
