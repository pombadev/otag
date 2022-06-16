exception Done

let read_file ~(cond : string ref -> bool)
    ~(parse : string ref -> string option) =
  let cwd = Sys.getcwd () in

  let chan = open_in (Printf.sprintf "%s%sdune-project" cwd Filename.dir_sep) in

  let contents = ref "" in
  let ret =
    try
      while true do
        let line = input_line chan in
        contents := line;

        if cond contents then raise_notrace Done
      done;
      None
    with
    | Done -> parse contents
    | _ -> None
  in
  ret

let synopsis =
  let value =
    read_file
      ~cond:(fun contents -> String.starts_with ~prefix:" (synopsis " !contents)
      ~parse:(fun contents ->
        List.nth_opt (!contents |> String.split_on_char '"') 1)
  in
  lazy (Option.value value ~default:"")

let version =
  let value =
    read_file
      ~cond:(fun contents -> String.starts_with ~prefix:"(version " !contents)
      ~parse:(fun contents ->
        match List.nth_opt (String.split_on_char ' ' !contents) 1 with
        | None -> None
        | Some x ->
            let s =
              String.fold_right
                (fun current init ->
                  match current with
                  | '(' | ')' | '\n' | '\t' | ' ' -> init
                  | c -> Printf.sprintf "%c%s" c init)
                x ""
            in
            Some s)
  in

  lazy (Option.value value ~default:"0.2")
