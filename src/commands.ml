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

type 't albm = { name : string; tracks : 't list }
type 'a group_by = { artist : string; albums : 'a albm list }

let replace l pos a = List.mapi (fun i x -> if i = pos then a else x) l

let grouper path =
  let audio_of_path = path |> List.map get_audio_from_path in

  let f = audio_of_path |> List.flatten in
  let hash =
    f
    |> List.fold_left
         (fun init (_, item) ->
           let artist = safe_get Taglib.tag_artist item in

           let _ =
             match Hashtbl.find_opt init artist with
             | None ->
                 let album = Hashtbl.create 64 in
                 Hashtbl.add album (safe_get Taglib.tag_album item) [ item ];
                 Hashtbl.add init artist album;
                 ()
             | Some bucket ->
                 let performer = Hashtbl.find_opt bucket artist in

                 let tracks =
                   match performer with
                   | Some a -> a @ [ item ]
                   | None -> [ item ]
                 in

                 Hashtbl.add bucket (safe_get Taglib.tag_album item) tracks
           in

           init)
         (Hashtbl.create (List.length f) ~random:false)
  in
  let disco =
    Hashtbl.fold
      (fun a b c ->
        (* print_endline ("Artist " ^ a); *)
        let album =
          Hashtbl.fold
            (fun x y z ->
              match z.name with
              | "" -> { name = x; tracks = y }
              | _ -> { z with tracks = z.tracks @ y })
            b { name = ""; tracks = [] }
        in

        (* let item = Hashtbl.find b a in
           let item = List.hd item in *)
        (* print_endline ("Track: " ^ safe_get Taglib.tag_title item); *)
        (* let ret = { artist = a; albums = {
             name =
           }} in *)
        c @ [ (a, album) ])
      hash []
  in

  disco
  |> List.iter (fun (artist, album) ->
         Printf.printf "Artist: %s\n" artist;

         Printf.printf "Album: %s\n" album.name;

         album.tracks
         |> List.iter (fun track ->
                Printf.printf "[%d] %s\n"
                  (safe_get_int Taglib.tag_track track)
                  (safe_get Taglib.tag_title track)));

  (* Hashtbl.iter
     (fun a b ->
       Printf.printf "Artist: %s\n" a;
       b
       |> Hashtbl.iter (fun _ d ->
              (* Printf.printf "Album: %s\n" c; *)
              d
              |> List.iter (fun t ->
                     Printf.printf "[%d] %s\n"
                       (safe_get_int Taglib.tag_track t)
                       (safe_get Taglib.tag_title t)));
       ())
     hash; *)

  (* let discographies =
       audio_of_path |> List.flatten
       |> List.mapi (fun index item -> (index, item))
       |> List.fold_left
            (fun init (index, (_, item)) ->
              let artist = safe_get Taglib.tag_artist item in
              let inserted = List.find_opt (fun a -> a.artist = artist) init in

              match inserted with
              | Some g ->
                  let inserted_album =
                    List.find_opt
                      (fun a -> a.name = safe_get Taglib.tag_album item)
                      g.albums
                  in
                  let alb =
                    match inserted_album with
                    | Some a ->
                        let ts = a.tracks @ [ item ] in
                        { a with tracks = ts }
                    | None ->
                        {
                          name = safe_get Taglib.tag_album item;
                          tracks = [ item ];
                        }
                  in
                  let s = { g with albums = g.albums @ [ alb ] } in
                  let ret = replace init index s in
                  ret
              | None ->
                  let init =
                    init
                    @ [
                        {
                          artist = safe_get Taglib.tag_artist item;
                          albums =
                            [
                              {
                                name = safe_get Taglib.tag_album item;
                                tracks = [ item ];
                              };
                            ];
                        };
                      ]
                  in

                  (* print_endline ("None " ^ artist);
                     print_endline ("Init " ^ string_of_int (List.length init)); *)
                  init)
            []
     in

     discographies
     |> List.iter (fun item ->
            print_endline ("Artist: " ^ item.artist);
            print_endline
              ("No of albums: " ^ string_of_int (List.length item.albums));
            item.albums
            |> List.iter (fun album ->
                   print_endline ("Album: " ^ album.name);
                   print_endline
                     ("No of tracks: " ^ string_of_int (List.length album.tracks));
                   album.tracks
                   |> List.iter (fun track ->
                          Printf.printf "[%d] %s\n"
                            (safe_get_int Taglib.tag_track track)
                            (safe_get Taglib.tag_title track)));
            print_endline "----------------");

     print_endline ("Discographies: " ^ string_of_int (List.length discographies)); *)

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
