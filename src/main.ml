let () =
  let flush () = Ocolor_format.pp_print_flush Ocolor_format.std_formatter () in

  let _ = Printexc.record_backtrace true in

  let exit_code = Cli.main () in

  let _ = flush () in

  exit exit_code
