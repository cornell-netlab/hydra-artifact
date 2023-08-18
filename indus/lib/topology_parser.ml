(* for now a topology is a simple mapping from switch ID to a boolean. True is a leaf switch false is a core switch*)
type topology = { title : string; switches : int; topology : (int * bool) list }

let json2topology file =
  let json = Yojson.Basic.from_file file in
  let open Yojson.Basic.Util in
  let title = json |> member "title" |> to_string in
  let switches = json |> member "switches" |> to_int in
  let entries = json |> member "topology" |> to_list in
  let topology =
    List.map
      (fun json ->
        let id = member "id" json |> to_int in
        let leaf = member "leaf" json |> to_bool in
        (id, leaf))
      entries
  in
  { title; switches; topology }

let print_topology (topology : topology) : unit =
  let rec format_topology = function
    | [] -> ""
    | (id, leaf) :: t ->
        Printf.sprintf "id: %d, leaf: %b\n" id leaf ^ format_topology t
  in
  match topology with
  | { title; switches; topology } ->
      Printf.printf "%s: %d switches\n%s\n" title switches
        (format_topology topology)
