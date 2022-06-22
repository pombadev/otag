open Utils

type options = {
  paths : string list;
  format : string option;
  tree : bool;
  infer : bool;
  organize_dest : string;
}

(** Print valid audio files as tree to stdout *)
let treeify opts =
  let { paths; _ } = opts in

  let grouped = audio_of_path paths in

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
               else
                 "├──"
             in

             Printf.printf "%s %s\n" pad album.name;

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

                    Printf.printf "%s %s [%d] %s\n" bar pad
                      (safe_get_int Taglib.tag_track track)
                      (safe_get Taglib.tag_title track))))
    grouped

(** Update metadata of valid audio files *)
let tag opts =
  let { paths; infer; _ } = opts in

  (* let _format = format in *)
  match infer with
  | true ->
      paths
      |> List.map get_audio_from_path
      |> List.iter (fun files ->
             files
             |> List.iter (fun (path, file) ->
                    let parts =
                      String.split_on_char (String.get Filename.dir_sep 0) path
                      |> List.rev
                    in

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

                    if !modified then
                      Taglib.file_save file |> ignore))
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

(** Move files to `Artist/Album/Tracks` structure, getting metadata from the embedded data *)
let organizer opts =
  let { paths; organize_dest; _ } = opts in

  let mkdir dir =
    let exist = try Sys.is_directory dir with _ -> false in
    if not exist then FileUtil.mkdir ~parent:true dir
  in

  let mv src dest =
    let copied =
      try
        FileUtil.cp ~force:Force ~recurse:true src dest;
        true
      with exn ->
        let msg = Printexc.to_string_default exn in

        Printf.eprintf "Unable to copy:\n  %s\n" msg;
        false
    in

    if copied then
      try FileUtil.rm ~force:Force ~recurse:true src
      with exn ->
        let msg = Printexc.to_string_default exn in

        Printf.eprintf "Unable to move:\n  %s\n" msg
  in

  audio_of_path paths
  |> Hashtbl.iter (fun artist group ->
         if String.length artist > 0 then (
           let dir = Filename.concat organize_dest artist in
           mkdir dir;

           group.albums
           |> List.iter (fun album ->
                  if String.length album.name > 0 then (
                    let dir = Filename.concat dir album.name in
                    mkdir dir;

                    let files =
                      album.tracks |> List.map (fun (path, _) -> path)
                    in
                    mv files dir))))

(** Main entry point for the cli *)
let run paths format tree infer organize =
  let opts = { paths; format; tree; infer; organize_dest = "" } in

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
