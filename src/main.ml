let () =
  let _ = Printexc.record_backtrace true in

  (* Start here *)
  (* let _f =
       Fetcher.Napster.search ~query_type:`Album
         ~query:"No Drum And Bass In The Jazz Room"
     in *)
  (* Lwt_main.run
     (Lwt_list.iter_s
        (fun f -> f ())
        [
          Fetcher.Napster.search ~query_type:`Album
            ~query:"No Drum And Bass In The Jazz Room";
        ]); *)
  (* Client.main (); *)
  exit (Cli.main ())

(* try
      with err ->
        let msg = Printexc.to_string err
        and stack = Printexc.get_backtrace () in
        Printf.eprintf "Error: %s\n%s\n" msg stack *)
