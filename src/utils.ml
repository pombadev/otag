(** Authored by Rudi Grinberg, licensed under MIT. *)
module StringExtra = struct
  exception Exit
  exception Found_int of int

  let substr_eq ?(start = 0) s ~pattern =
    try
      for i = 0 to String.length pattern - 1 do
        if s.[i + start] <> pattern.[i] then raise Exit
      done;
      true
    with _ -> false

  let find_from ?(start = 0) str ~pattern =
    try
      for i = start to String.length str - String.length pattern do
        if substr_eq ~start:i str ~pattern then
          raise (Found_int i)
      done;
      None
    with
    | Found_int i -> Some i
    | _ -> None

  let replace_all str ~pattern ~with_ =
    let slen, plen = String.(length str, length pattern) in
    let buf = Buffer.create slen in
    let rec loop i =
      match find_from ~start:i str ~pattern with
      | None ->
          Buffer.add_substring buf str i (slen - i);
          Buffer.contents buf
      | Some j ->
          Buffer.add_substring buf str i (j - i);
          Buffer.add_string buf with_;
          loop (j + plen)
    in
    loop 0
end

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
      with _ ->
        (* Printf.eprintf "[OTAG] Skipping '%s' file type detection failed\n"
           file_name; *)
        None)
    files

let random_state =
  let _ = Random.self_init () in
  Printf.sprintf "%LX" (Random.bits64 ())

let safe_get tag file = try tag file with _ -> random_state

let safe_get_int tag file =
  try
    let track = tag file in
    string_of_int track
  with _ -> random_state

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
                                let safe_get_int tag file =
                                  try tag file with _ -> 0
                                in
                                let no_a = safe_get_int Taglib.tag_track this in
                                let no_b = safe_get_int Taglib.tag_track that in
                                compare no_a no_b)
                 in
                 ()
           in

           init)
         (Hashtbl.create (List.length paths))
  in
  grouped

let prompt ~choices ?(msg = "Select") ?(default = 0) () =
  Inquire.select msg ~options:choices ~default
