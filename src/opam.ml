module File : sig
  val version : string
  val description : string
  val synopsis : string
  val homepage : string
  val print : unit -> unit
end = struct
  open OpamParserTypes.FullPos
  module StringExtra = Utils.StringExtra

  type shape = {
    version : string;
    synopsis : string;
    description : string;
    homepage : string;
  }

  let file =
    let file = OpamParser.FullPos.string [%blob "otag.opam"] "otag.opam" in

    let value =
      List.fold_right
        (fun item init ->
          match item.pelem with
          | Variable (name, value) -> (
              match name.pelem with
              | "version" ->
                  let version = OpamPrinter.FullPos.value value in
                  let version =
                    StringExtra.replace_all version ~pattern:"\"" ~with_:""
                  in
                  { init with version }
              | "synopsis" ->
                  let synopsis = OpamPrinter.FullPos.value value in
                  let synopsis =
                    StringExtra.replace_all synopsis ~pattern:"\"" ~with_:""
                  in
                  { init with synopsis }
              | "description" ->
                  let desc = OpamPrinter.FullPos.value value in
                  let desc =
                    StringExtra.replace_all desc ~pattern:"\"\"\"" ~with_:""
                  in
                  { init with description = desc }
              | "homepage" ->
                  let homepage = OpamPrinter.FullPos.value value in
                  let homepage =
                    StringExtra.replace_all homepage ~pattern:"\"" ~with_:""
                  in
                  { init with homepage }
              | _ -> init)
          | _ -> init)
        file.file_contents
        { version = ""; synopsis = ""; description = ""; homepage = "" }
    in

    assert (String.length value.description > 0);
    assert (String.length value.version > 0);
    assert (String.length value.synopsis > 0);
    assert (String.length value.homepage > 0);

    value

  let version = file.version
  let description = file.description
  let synopsis = file.synopsis
  let homepage = file.homepage

  let print () =
    (* so that if we add any new fields this this will remind us to update *)
    let { version; synopsis; description; homepage } = file in
    Printf.printf
      "version = %s\nsynopsis = %s\ndescription = %s\nhomepage = %s\n" version
      synopsis description homepage
end
