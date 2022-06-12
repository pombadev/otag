let () =
  let _ = Printexc.record_backtrace true in

  (* Start here *)
  Fetcher.Napster.search ~qt:`Album ~query:"No Drum And Bass In The Jazz Room";

  (* Client.main (); *)
  exit (Cli.main ())

(* try
      with err ->
        let msg = Printexc.to_string err
        and stack = Printexc.get_backtrace () in
        Printf.eprintf "Error: %s\n%s\n" msg stack *)
