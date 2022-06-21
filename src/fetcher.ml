let content_type = ("Content-Type", "application/json")

let user_agent =
  let os, os_ver = Sys.(os_type, ocaml_version) in
  let app_ver = Lazy.force DuneProject.version in
  let ua = Printf.sprintf "OTag/%s (%s) %s" app_ver os os_ver in
  ("User-Agent", ua)

module Napster = struct
  type search_type = [ `Album | `Artist | `Track ]

  let api_key =
    Option.value
      (Sys.getenv_opt "NAPSTER_APIKEY")
      ~default:"YTkxZTRhNzAtODdlNy00ZjMzLTg0MWItOTc0NmZmNjU4Yzk4"

  let base_url = "http://api.napster.com/v2.2"

  type href_t = { href : string }
  type links_t = { tracks : href_t; artists : href_t }
  type date_t = { year : string; month : string; day : string }

  type response = {
    id : string;
    href : string;
    album : string;
    kind : string;
    released : date_t;
    label : string;
    copyright : string;
    links : links_t;
    artist : string;
  }

  (** Parse response from napster to json *)
  let parse data =
    let open Yojson.Basic.Util in
    let discographies =
      data
      |> member "albums"
      |> to_list
      |> List.map (fun d ->
             let kind = member "type" d |> to_string in
             let id = member "id" d |> to_string in
             let href = member "href" d |> to_string in
             let album = member "name" d |> to_string in
             let label = member "label" d |> to_string in
             let copyright = member "copyright" d |> to_string in
             let artist = member "artistName" d |> to_string in
             let released =
               member "released" d
               |> to_string
               |> String.split_on_char '-'
               |> List.fold_left
                    (fun init current ->
                      match
                        ( String.length init.year,
                          String.length init.month,
                          String.length init.day )
                      with
                      | 0, _, _ -> { init with year = current }
                      | _, 0, _ -> { init with month = current }
                      | _, _, 0 ->
                          let day =
                            String.split_on_char 'T' current |> List.hd
                          in
                          { init with day }
                      | _ -> init)
                    { year = ""; month = ""; day = "" }
             in
             let links =
               member "links" d
               |> to_assoc
               |> List.fold_left
                    (fun init (key, json_obj) ->
                      match key with
                      | "tracks" ->
                          {
                            init with
                            tracks =
                              { href = member "href" json_obj |> to_string };
                          }
                      | "artists" ->
                          {
                            init with
                            artists =
                              { href = member "href" json_obj |> to_string };
                          }
                      | _ -> init)
                    { tracks = { href = "" }; artists = { href = "" } }
             in

             {
               kind;
               id;
               href;
               album;
               links;
               label;
               copyright;
               released;
               artist;
             })
    in
    discographies

  let search ~query_type ~query () =
    let qt =
      match query_type with
      | `Album -> "album"
      | `Artist -> "artist"
      | `Track -> "track"
    in

    let query = String.split_on_char ' ' query |> String.concat "+" in

    let url =
      Printf.sprintf "%s/search?apikey=%s&query=%s&type=%s" base_url api_key
        query qt
    in
    Printf.printf "Parsed to %s\n" url;

    let response = Quests.get ~headers:[ content_type; user_agent ] url in

    let body = Lwt_main.run response in

    let json = body |> Quests.Response.json in

    (* let json = Yojson.Safe.from_file "src/napster.search.json" in *)
    let json = Yojson.Safe.to_basic json in

    let open Yojson.Basic.Util in
    let data =
      json
      |> member "search"
      |> to_assoc
      |> List.find (fun (a, _) ->
             match a with
             | "data" -> true
             | _ -> false)
    in

    let albums = parse (snd data) in

    let _ =
      albums
      |> List.iter (fun album ->
             print_endline "==========";
             print_endline ("artist = " ^ album.artist);
             print_endline ("album = " ^ album.album);
             print_endline ("href = " ^ album.href);
             print_endline
               ("date = "
               ^ album.released.year
               ^ "/"
               ^ album.released.month
               ^ "/"
               ^ album.released.day);
             print_endline ("label = " ^ album.label);
             print_endline ("copyright = " ^ album.copyright);
             print_endline ("id = " ^ album.id))
    in
    albums
end
