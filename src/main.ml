let () =
  let reset_ppf = Spectrum.prepare_ppf Format.std_formatter in

  let _ = Printexc.record_backtrace true in

  let exit_code = Cli.main () in

  let _ = reset_ppf () in

  exit exit_code
