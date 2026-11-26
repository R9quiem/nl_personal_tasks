let read_numbers path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () ->
      let rec read_lines reversed =
        match input_line channel with
        | line ->
            let tokens =
              String.map (function '\t' | '\r' | '\011' | '\012' -> ' ' | c -> c) line
              |> String.split_on_char ' '
              |> List.filter (fun token -> token <> "")
            in
            read_lines (List.rev_append tokens reversed)
        | exception End_of_file -> List.rev reversed
      in
      List.map
        (fun token ->
          match int_of_string_opt token with
          | Some number -> number
          | None -> invalid_arg ("Invalid integer: " ^ token))
        (read_lines []))

let read_graph path =
  match read_numbers path with
  | vertices :: edges :: values ->
      if vertices < 0 || edges < 0 then
        invalid_arg "Vertex and edge counts must be nonnegative";
      let graph = Array.make vertices [] in
      let seen = Hashtbl.create 16 in
      let rec add_edges remaining numbers =
        match remaining, numbers with
        | 0, [] -> graph
        | 0, _ -> invalid_arg "Unexpected data after edges"
        | _, first :: second :: rest ->
            if first < 0 || first >= vertices || second < 0 || second >= vertices then
              invalid_arg "Vertex index is outside the graph";
            if first = second then invalid_arg "Self-loops are not supported";
            let edge = min first second, max first second in
            if Hashtbl.mem seen edge then invalid_arg "Duplicate edge";
            Hashtbl.add seen edge ();
            graph.(first) <- second :: graph.(first);
            graph.(second) <- first :: graph.(second);
            add_edges (remaining - 1) rest
        | _, _ -> invalid_arg "Not enough edge endpoints"
      in
      add_edges edges values
  | _ -> invalid_arg "Expected vertex count and edge count"

let find_bridges graph =
  let discovered = Array.make (Array.length graph) (-1) in
  let low = Array.make (Array.length graph) (-1) in
  let timer = ref 0 in
  let bridges = ref [] in
  let rec visit vertex parent =
    discovered.(vertex) <- !timer;
    low.(vertex) <- !timer;
    incr timer;
    List.iter
      (fun neighbor ->
        if neighbor <> parent then
          if discovered.(neighbor) = -1 then begin
            visit neighbor vertex;
            low.(vertex) <- min low.(vertex) low.(neighbor);
            if low.(neighbor) > discovered.(vertex) then
              bridges := (min vertex neighbor, max vertex neighbor) :: !bridges
          end else
            low.(vertex) <- min low.(vertex) discovered.(neighbor))
      graph.(vertex)
  in
  for vertex = 0 to Array.length graph - 1 do
    if discovered.(vertex) = -1 then visit vertex (-1)
  done;
  List.sort compare !bridges

let run () =
  if Array.length Sys.argv <> 2 then invalid_arg "Usage: bridges <file>";
  let graph = read_graph Sys.argv.(1) in
  let bridges = find_bridges graph in
  Printf.printf "Bridges: %d\n" (List.length bridges);
  List.iter (fun (first, second) -> Printf.printf "%d %d\n" first second) bridges

let () =
  try run () with
  | Invalid_argument message | Sys_error message ->
      prerr_endline ("Error: " ^ message);
      exit 1
  | Stack_overflow ->
      prerr_endline "Error: graph exceeds the recursive DFS stack capacity";
      exit 1
