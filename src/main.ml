let () =
  let _ = Printexc.record_backtrace true in

  (* Start here *)
  Fetcher.Napster.search ~qt:`Album ~query:"No Drum And Bass In The Jazz Room";

  (* Client.main (); *)
  exit (Cli.main ())
