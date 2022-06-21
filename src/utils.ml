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
      with _ ->
        Printf.eprintf "[OTAG] Skipping '%s' file type detection failed\n"
          file_name;
        None)
    files

let safe_get tag file = try tag file with _ -> ""
let safe_get_int tag file = try tag file with _ -> 0

type 't grouped_album = { name : string; mutable tracks : (string * 't) list }
type 'a grouped_by = { artist : string; mutable albums : 'a grouped_album list }

let audio_of_path paths =
  let files =
    paths
    (* remove duplicates *)
    |> List.sort_uniq compare
    |> List.map get_audio_from_path
    |> List.flatten
  in

  let grouped =
    files
    |> List.fold_left
         (fun init (path, current) ->
           let artist_from_tag = safe_get Taglib.tag_artist current in
           let album_from_tag = safe_get Taglib.tag_album current in

           let _ =
             match Hashtbl.find_opt init artist_from_tag with
             | None ->
                 Hashtbl.add init artist_from_tag
                   {
                     artist = artist_from_tag;
                     albums =
                       [
                         { name = album_from_tag; tracks = [ (path, current) ] };
                       ];
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
                         @ [
                             {
                               name = album_from_tag;
                               tracks = [ (path, current) ];
                             };
                           ]
                   | Some g_album ->
                       g_album.tracks <-
                         g_album.tracks @ [ (path, current) ]
                         |> List.sort (fun (_, this) (_, that) ->
                                let no_a = safe_get_int Taglib.tag_track this in
                                let no_b = safe_get_int Taglib.tag_track that in
                                if no_a < no_b then -1 else 1)
                 in
                 ()
           in

           init)
         (Hashtbl.create (List.length paths))
  in
  grouped

let prompt ~choices ?(msg = "Select") ?(default = 0) () =
  Inquire.select msg ~options:choices ~default
