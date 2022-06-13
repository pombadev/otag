open Utils

let treeify path =
  let grouped = audio_of_path path in

  let _ =
    let count = ref 0 in
    let artist_count = Hashtbl.length grouped in

    Hashtbl.iter
      (fun _ grouped ->
        incr count;

        Printf.printf "%s\n" grouped.artist;

        let album_count = List.length grouped.albums in

        grouped.albums
        |> List.iteri (fun index album ->
               let current_artist = index + 1 in
               let pad =
                 if !count = artist_count then
                   match List.nth_opt grouped.albums current_artist with
                   | None -> "└──"
                   | Some _ -> "├──"
                 else "├──"
               in

               Printf.printf "%s %s\n" pad album.name;

               let tracks_count = List.length album.tracks in

               album.tracks
               |> List.iteri (fun index track ->
                      let current_track = index + 1 in
                      let stop =
                        !count = artist_count && current_artist = album_count
                      in

                      let pad =
                        if current_track = tracks_count then "└──" else "├──"
                      in

                      let bar = if stop then " " else "│" in

                      Printf.printf "%s  %s  [%d] %s\n" bar pad
                        (safe_get_int Taglib.tag_track track)
                        (safe_get Taglib.tag_title track))))
      grouped
  in
  ()

let tag ~path ~format ~infer =
  Printf.printf "format = %s\ninfer = %b\n"
    (Option.value format ~default:"default")
    infer;
  let grouped = audio_of_path path in
  let () =
    grouped
    |> Hashtbl.iter (fun artist group ->
           print_endline ("Artist " ^ artist);

           group.albums
           |> List.iter (fun album ->
                  album.tracks
                  |> List.iter (fun track ->
                         Printf.printf "[%d] %s\n"
                           (safe_get_int Taglib.tag_track track)
                           (safe_get Taglib.tag_title track)))
           (* path
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
                              Taglib.File.file_save file |> ignore))) *))
  in
  ()

let run path format tree infer =
  match tree with true -> treeify path | false -> tag ~path ~format ~infer
