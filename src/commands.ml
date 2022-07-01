open Utils

type options = {
  paths : string list;
  format : string option;
  tree : bool;
  infer : bool;
  organize_dest : string;
  dry_run : bool;
}

let colorify = Spectrum.Simple.printf

(** Print valid audio files as tree to stdout *)
let treeify opts =
  let { paths; _ } = opts in

  let grouped = audio_of_path paths in

  let count = ref 0 in

  let artist_count = Hashtbl.length grouped in

  Hashtbl.iter
    (fun _ grouped ->
      incr count;

      colorify "@{<bold,yellow>%s@}\n" grouped.artist;

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

             colorify "%s @{<bold,green>%s@}\n" pad album.name;

             let tracks_count = List.length album.tracks in

             album.tracks
             |> List.iteri (fun index (_, track) ->
                    let current_track = index + 1 in
                    let stop =
                      !count = artist_count && current_artist = album_count
                    in

                    let pad =
                      if current_track = tracks_count then "└──" else "├──"
                    in

                    let bar = if stop then " " else "│" in

                    colorify "%s %s @{<fuchsia>[%s]@} @{<bold,teal>%s@}\n" bar
                      pad
                      (safe_get_int Taglib.tag_track track)
                      (safe_get Taglib.tag_title track))))
    grouped

(** Update metadata of valid audio files *)
let tag opts =
  let { paths; infer; format; _ } = opts in

  print_endline
    (match format with
    | Some fmt -> fmt
    | None -> "default");

  (* let _format = format in *)
  match infer with
  | true ->
      paths
      |> List.map get_audio_from_path
      |> List.iter (fun files ->
             files
             |> List.iter (fun (path, file) ->
                    let parts =
                      path
                      |> String.split_on_char (String.get Filename.dir_sep 0)
                      |> List.rev
                    in

                    if List.length parts = 0 then
                      failwith
                        (Printf.sprintf
                           "'%s' should be nested like this \
                            'Artist/Album/Track'"
                           path);

                    let modified = ref false in

                    let _ =
                      match List.nth_opt parts 2 with
                      | Some artist ->
                          Taglib.tag_set_artist file artist;
                          modified := true
                      | None -> ()
                    in

                    let _ =
                      match List.nth_opt parts 1 with
                      | Some album ->
                          Taglib.tag_set_album file album;
                          modified := true
                      | None -> ()
                    in

                    let _ =
                      match List.nth_opt parts 0 with
                      | Some track ->
                          Taglib.tag_set_title file track;
                          modified := true
                      | None -> ()
                    in

                    if !modified then Taglib.file_save file |> ignore))
  | false ->
      let grouped = audio_of_path paths in

      let discog =
        Hashtbl.fold
          (fun artist group init ->
            let albums = group.albums |> List.map (fun album -> album.name) in

            init @ [ (artist, albums) ])
          grouped []
      in
      let open Fetcher.Napster in
      let tasks =
        discog
        |> List.map (fun (_, albums) ->
               albums
               |> List.map (fun album ->
                      let res =
                        Fetcher.Napster.search ~query_type:`Album ~query:album
                          ()
                      in

                      let ans =
                        Utils.prompt
                          ~choices:
                            (res
                            |> List.map (fun a -> a.album ^ " by " ^ a.artist))
                          ~msg:"Multiple matches found, please select one" ()
                      in

                      print_endline ("Answer " ^ ans);

                      fun () -> Lwt.return_unit))
        |> List.flatten
      in

      Lwt_main.run (Lwt_list.iter_p (fun f -> f ()) tasks)

(* type summaries = { artist : string; tracks : string list; released : string } *)

(** Move files to `Artist/Album/Tracks` structure, getting metadata from the embedded data *)
let organizer opts =
  let { paths; organize_dest; dry_run; _ } = opts in

  let dir_exist dir = try Sys.is_directory dir with _ -> false in

  let mkdir dir =
    let exist = dir_exist dir in
    if not exist then Unix.mkdir dir 0o0777
  in

  let audio_files = audio_of_path paths in

  (* let _metadata =
       Hashtbl.fold (fun a b c -> c) audio_files ([] : summaries list)
     in *)
  audio_files
  |> Hashtbl.iter (fun artist group ->
         if String.length artist > 0 then (
           print_endline ("Artist: " ^ artist);

           let artist_dir = Filename.concat organize_dest artist in
           if not dry_run then mkdir artist_dir;

           group.albums
           |> List.iter (fun album ->
                  if String.length album.name > 0 then (
                    print_endline ("Album: " ^ album.name);

                    let album_dir =
                      let maybe_year =
                        album.tracks
                        |> List.find_map (fun (_, track) ->
                               try
                                 let track = Taglib.tag_year track in
                                 Some track
                               with _ -> None)
                      in

                      let prefix =
                        match maybe_year with
                        | None -> ""
                        | Some track -> Printf.sprintf "[%d] " track
                      in

                      Filename.concat artist_dir (prefix ^ album.name)
                    in

                    if not dry_run then mkdir album_dir;

                    album.tracks
                    |> List.iter (fun (path, track) ->
                           let title_from_metadata =
                             safe_get Taglib.tag_title track
                           in

                           let file =
                             let file_name = Filename.basename path in

                             let name =
                               if title_from_metadata <> Utils.random_state then
                                 let ext = Filename.extension file_name in
                                 title_from_metadata ^ ext
                               else file_name
                             in

                             name
                           in

                           let dest = Filename.concat album_dir file in

                           match path = dest with
                           | true -> print_endline "nothing to do"
                           | false -> begin
                               match dry_run with
                               | true ->
                                   (* colorify "@{<green>+ %s@}\n@{<red>- %s@}\n"
                                      dest path; *)
                                   print_endline
                                     ("Rename from\n" ^ path ^ "\nTo\n" ^ dest)
                               | false -> Unix.rename path dest
                             end)))))

(** Main entry point for the cli *)
let run paths format tree infer organize dry_run =
  let opts = { paths; format; tree; infer; organize_dest = ""; dry_run } in

  let action =
    match tree with
    | true -> `Tree
    | false -> (
        match organize with
        | Some s -> `Organize s
        | None -> `Tag)
  in

  match action with
  | `Tree -> treeify opts
  | `Organize dest ->
      let opts = { opts with organize_dest = dest } in
      organizer opts
  | `Tag -> tag opts
