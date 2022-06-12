let get_audio_from_path dir =
  let rec loop result = function
    | f :: fs when try Sys.is_directory f with _ -> false ->
        Sys.readdir f |> Array.to_list
        |> List.map (Filename.concat f)
        |> List.append fs |> loop result
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

type action = Tree | Tag of string option

let safe_get tag file = try tag file with _ -> ""
let safe_get_int tag file = try tag file with _ -> 0

let parse_cli path format tree infer =
  Printf.printf "tree = %b\npath = %s\nformat = %s\nformat src = %b\n\n\n" tree
    (String.concat ", " path)
    (match format with
    | Some f -> Printf.sprintf "%s" f
    | None -> Printf.sprintf "Default format")
    infer;

  let ret = match tree with true -> Tree | false -> Tag (Some "") in

  ret

type 't grouped_album = { name : string; mutable tracks : 't list }
type 'a grouped_by = { artist : string; mutable albums : 'a grouped_album list }

let audio_of_path path =
  let files =
    path
    (* remove duplicates *)
    |> List.sort_uniq compare
    |> List.map get_audio_from_path
    |> List.flatten
  in

  let grouped =
    files
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
                       let _ = g_album.tracks <- g_album.tracks @ [ current ] in
                       let _ =
                         g_album.tracks
                         |> List.sort (fun this that ->
                                let no_a = safe_get_int Taglib.tag_track this in
                                let no_b = safe_get_int Taglib.tag_track that in
                                if no_a < no_b then -1 else 1)
                       in
                       ()
                 in
                 ()
           in

           init)
         (Hashtbl.create (List.length path))
  in
  grouped
