module Greeter = struct
  let greet ?(msg = "World") () = Printf.printf "Hello, %s!\n" msg
end