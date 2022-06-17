let () =
  let _ = Printexc.record_backtrace true in
  exit (Cli.main ())
