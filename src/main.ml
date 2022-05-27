let () =
  let _ = Printexc.record_backtrace true in

  (* Start here *)
  (* let json_string =
       {|
     {"number" : 42,
      "string" : "yes",
      "list": ["for", "sure", 42]}|}
     in

     let json = Yojson.Basic.from_string json_string in

     (* let json = Yojson.Safe.from_string json_string in *)
     let n =
       json |> Yojson.Basic.Util.member "number" |> Yojson.Basic.Util.to_int
     in
     let s =
       json |> Yojson.Basic.Util.member "string" |> Yojson.Basic.Util.to_string
     in

     (* Format.printf "Parsed to %a\n" Yojson.Basic.pp json *)
     print_endline ("number: " ^ string_of_int n);
     print_endline ("string: " ^ s); *)
  Fetcher.Napster.search ~qt:`Album ~query:"No Drum And Bass In The Jazz Room";

  (* Client.main (); *)
  exit (Cli.main ())
