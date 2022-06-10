let get_audio_from_path dir =
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
      (fun file_name ->
        try
          let taglib_file = Taglib.File.open_file `Autodetect file_name in
          Some (file_name, taglib_file)
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

type 't grouped_album = { name : string; mutable tracks : 't list }
type 'a grouped_by = { artist : string; mutable albums : 'a grouped_album list }

let grouper path =
  let audio_of_path = path |> List.map get_audio_from_path |> List.flatten in

  let grouped_list =
    audio_of_path
    |> List.fold_left
         (fun init (_, current) ->
           let artist_from_tag = safe_get Taglib.tag_artist current in
           let album_from_tag = safe_get Taglib.tag_album current in

           let _ =
             match Hashtbl.find_opt init artist_from_tag with
             | None ->
                 Hashtbl.add init artist_from_tag
                   {
                     artist = artist_from_tag;
                     albums =
                       [ { name = album_from_tag; tracks = [ current ] } ];
                   }
             | Some grouped ->
                 let _ =
                   match
                     grouped.albums
                     |> List.find_opt (fun al -> al.name = album_from_tag)
                   with
                   | None ->
                       grouped.albums <-
                         grouped.albums
                         @ [ { name = album_from_tag; tracks = [ current ] } ]
                   | Some g_album ->
                       g_album.tracks <- g_album.tracks @ [ current ]
                 in
                 ()
           in

           init)
         (Hashtbl.create 64)
  in

  let _ =
    Hashtbl.iter
      (fun _ grouped ->
        Printf.printf "'%s' has '%d' album(s)\n" grouped.artist
          (List.length grouped.albums);

        grouped.albums
        |> List.iter (fun album ->
               Printf.printf "Album: %s\n" album.name;

               album.tracks
               |> List.sort (fun a b ->
                      let no_a = safe_get_int Taglib.tag_track a in
                      let no_b = safe_get_int Taglib.tag_track b in
                      if no_a < no_b then -1 else 1)
               |> List.iter (fun track ->
                      Printf.printf "[ %d ] %s\n"
                        (safe_get_int Taglib.tag_track track)
                        (safe_get Taglib.tag_title track))))
      grouped_list
  in

  (* audio_of_path
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
                       (Taglib.File.audioproperties_samplerate file))) *)
  ()

let run path format group infer =
  let act = parse_cli path format group infer in

  match act with
  | Group -> grouper path
  (* try
        with err ->
          let msg = Printexc.to_string err
          and stack = Printexc.get_backtrace () in
          Printf.eprintf "Error: %s\n%s\n" msg stack *)
  | Tag t -> (
      match t with
      | Some s ->
          Printf.printf "do other stuffs: %s\n" s;
          path
          |> List.map get_audio_from_path
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
