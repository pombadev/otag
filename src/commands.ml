let get_audio_files dir =
  let rec loop result = function
    | f :: fs when try Sys.is_directory f with _ -> false ->
        Sys.readdir f
        |> Array.to_list
        |> List.map (Filename.concat f)
        |> List.append fs
        |> loop result
    | f :: fs -> loop (f :: result) fs
    | [] -> result
  in
  let files = loop [] [ dir ] in
    List.filter_map
      (fun file ->
        try
          let taglib_file = Taglib.File.open_file `Autodetect file in
          Some (file, taglib_file)
        with _ -> None)
    files
  [@@ocamlformat "disable"]

(* type track = {
     genre : string;
     comment : string;
     title : string;
     artist : string;
     year : string;
     track : string;
     album : string;
   } *)

type action = Group | Tag of string option

let safe_get tag file = try tag file with _ -> ""
let safe_get_int tag file = try tag file with _ -> 0

let parse_cli path format group infer =
  Printf.printf "path = %s\nformat = %s\nformat src = %b\ngroup = %b\n\n\n"
    (String.concat ", " path)
    (match format with
    | Some f -> Printf.sprintf "%s" f
    | None -> Printf.sprintf "Default format")
    infer group;

  let ret = match group with true -> Group | false -> Tag (Some "") in

  ret

type 'a fooz = { artist : string; files : 'a list }

let run path format group infer =
  let act = parse_cli path format group infer in

  match act with
  | Group ->
      let artist_group = path |> List.map get_audio_files in
      let g =
        artist_group
        |> List.map (fun ag ->
               ag
               |> List.fold_left
                    (fun init (_, file) ->
                      let r =
                        {
                          artist = safe_get Taglib.tag_artist file;
                          files = init.files @ [ file ];
                        }
                      in
                      r)
                    { artist = ""; files = [] })
      in

      print_endline ("---" ^ string_of_int (List.length g));

      g
      |> List.iter (fun f ->
             print_endline ("f.artist " ^ f.artist);

             f.files
             |> List.iter (fun a ->
                    Printf.printf "[ %d ] %s\n"
                      (safe_get_int Taglib.tag_track a)
                      (safe_get Taglib.tag_title a)));

      artist_group
      |> List.iter (fun path_files ->
             path_files
             |> List.iter (fun (path, file) ->
                    if true then ()
                    else
                      Printf.printf
                        "== %s ==\n\
                         Genre = %s\n\
                         Comment = %s\n\
                         Title = %s\n\
                         Artist = %s\n\
                         Year = %d\n\
                         Track = %d\n\
                         Album = %s\n\
                         Bitrate = %d Kbps\n\
                         Channels = %d\n\
                         Length = %d Secs\n\
                         Samplerate = %d Hz\n\n"
                        path
                        (safe_get Taglib.tag_genre file)
                        (safe_get Taglib.tag_comment file)
                        (safe_get Taglib.tag_title file)
                        (safe_get Taglib.tag_artist file)
                        (safe_get_int Taglib.tag_year file)
                        (safe_get_int Taglib.tag_track file)
                        (safe_get Taglib.tag_album file)
                        (Taglib.File.audioproperties_bitrate file)
                        (Taglib.File.audioproperties_channels file)
                        (Taglib.File.audioproperties_length file)
                        (Taglib.File.audioproperties_samplerate file)))
      (* try
            with err ->
              let msg = Printexc.to_string err
              and stack = Printexc.get_backtrace () in
              Printf.eprintf "Error: %s\n%s\n" msg stack *)
  | Tag t -> (
      match t with
      | Some s ->
          Printf.printf "do other stuffs: %s\n" s;
          path |> List.map get_audio_files
          |> List.iter (fun path_files ->
                 path_files
                 |> List.iter (fun (path, file) ->
                        if infer then (
                          let s =
                            String.split_on_char
                              (String.get Filename.dir_sep 0)
                              path
                            |> List.rev
                          in

                          let artist =
                            Option.value (List.nth_opt s 2) ~default:""
                          in
                          let album =
                            Option.value (List.nth_opt s 1) ~default:""
                          in
                          let track =
                            Option.value (List.nth_opt s 0) ~default:""
                          in

                          Printf.printf
                            "Inferred\ntrack = %s\nalbum = %s\nartist = %s\n\n"
                            track album artist;

                          Taglib.tag_set_album file album;
                          Taglib.tag_set_artist file artist;
                          Taglib.tag_set_title file track;
                          Taglib.file_save file |> ignore;
                          Taglib.File.file_save file |> ignore)))
      | None ->
          print_endline "do other stuffs..";
          ())
