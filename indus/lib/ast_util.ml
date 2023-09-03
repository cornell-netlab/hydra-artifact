open Ast
module SymbolTable = Map.Make (String)

let empty_symbol_table = SymbolTable.empty

let add_decl symbol_t (Decl (net_t, var_t, id)) =
  SymbolTable.add id (net_t, var_t) symbol_t

let get_symbol symbol_t id =
  match SymbolTable.find id symbol_t with
  | (net_typ, v_typ) as x -> x
  | exception Not_found ->
      failwith "Impossible for symbol to not be found if type-checked"

let get_net_typ symbol_t id =
  match SymbolTable.find id symbol_t with net_typ, v_typ -> net_typ

let get_var_typ symbol_t id =
  match SymbolTable.find id symbol_t with
  | net_typ, v_typ -> v_typ
  | exception Not_found ->
      failwith "Impossible for symbol to not be found if type-checked"

(* map from ident names to a pair of net_type and var_type.
   Should have helpers to get just net_type and var_type from map*)
let symbol_table (Program (decl_list, _, _, _)) =
  List.fold_left add_decl empty_symbol_table decl_list

let symbol_table_decl_list decl_list =
  List.fold_left add_decl empty_symbol_table decl_list

(*dict lookup. Returns option with the name of the dict variable*)
let st_contains_dict_lookup statement : expr list =
  let rec expr_contains_dict_lookup = function
    | DictLookup (id, tup) as lookup -> [ lookup ]
    | Var id -> []
    | Value v -> []
    | Binop (bop, e1, e2) ->
        expr_contains_dict_lookup e1 @ expr_contains_dict_lookup e2
    | Uop (uop, expr) -> expr_contains_dict_lookup expr
    | ListIndex (id, expr) -> expr_contains_dict_lookup expr
    | Keyword k -> []
  in
  match statement with
  | Pass -> []
  | Push (id, expr) -> expr_contains_dict_lookup expr
  | Local_dec (vt, id, expr) -> expr_contains_dict_lookup expr
  | Assignment (id, expr) -> expr_contains_dict_lookup expr
  | For (_, _, _) -> []
  | Branch (expr, code, elifs, els) -> expr_contains_dict_lookup expr
  | Exception e -> []

let rec get_codeblock_lookups codeblock : expr list =
  match codeblock with
  | stmt :: t ->
      let lookups = st_contains_dict_lookup stmt in
      let recurse_lookups =
        match stmt with
        | Pass -> []
        | Push (id, expr) -> []
        | Local_dec (vt, id, expr) -> []
        | Assignment (id, expr) -> []
        | For (_, _, code) -> get_codeblock_lookups code
        | Branch (expr, code, _, Some els) ->
            get_codeblock_lookups code @ get_codeblock_lookups els
        | Branch (expr, code, _, None) -> get_codeblock_lookups code
        | Exception e -> []
      in
      lookups @ recurse_lookups @ get_codeblock_lookups t
  | [] -> []

let get_cp_non_dict symbol_t =
  let is_cp_non_dict = function
    | name, (Control, Dict (_, _)) -> false
    | name, (Control, _) -> true
    | _ -> false
  in
  let bindings = SymbolTable.bindings symbol_t in
  List.filter is_cp_non_dict bindings

(* used for push variables and strip telemetry*)
let get_tele_vars symbol_t =
  let is_tele = function name, (Tele, _) -> true | _ -> false in
  let bindings = SymbolTable.bindings symbol_t in
  List.filter is_tele bindings |> List.map (fun (name, (_, _)) -> name)

let get_control_vars symbol_t =
  let is_control = function name, (Control, _) -> true | _ -> false in
  let bindings = SymbolTable.bindings symbol_t in
  List.filter is_control bindings |> List.map (fun (name, (_, _)) -> name)

let get_sensor_vars symbol_t =
  let is_sensor = function name, (Sensor, _) -> true | _ -> false in
  let bindings = SymbolTable.bindings symbol_t in
  List.filter is_sensor bindings |> List.map (fun (name, (_, _)) -> name)

let get_list_vars symbol_t =
  let is_list = function name, (_, List (_, _)) -> true | _ -> false in
  let bindings = SymbolTable.bindings symbol_t in
  List.filter is_list bindings |> List.map (fun (name, (_, _)) -> name)

let get_dict_vars symbol_t =
  let is_dict = function name, (_, Dict (_, _)) -> true | _ -> false in
  let bindings = SymbolTable.bindings symbol_t in
  List.filter is_dict bindings |> List.map (fun (name, (_, _)) -> name)

let get_header_loc symbol_t var =
  match get_symbol symbol_t var with
  | Header loc, _ -> loc (*when Header gets a loc value update this*)
  | _ -> failwith "get_header_loc can only be called with header variables"

let remove_duplicates strings =
  let seen = Hashtbl.create (List.length strings) in
  List.fold_left
    (fun acc str ->
      if not (Hashtbl.mem seen str) then (
        Hashtbl.add seen str ();
        str :: acc)
      else acc)
    [] (List.rev strings)
  |> List.rev

let rec expression_contains_sensor expr symbol_t : string list =
  let is_sensor symbol_t id =
    match get_net_typ symbol_t id with
    | Sensor -> true
    | _ -> false
    | exception Not_found -> false
  in
  remove_duplicates
    (match expr with
    | DictLookup (id, tup) ->
        List.filter (is_sensor symbol_t) tup
        (*look at every id in tuple to see if it's a sensor*)
    | Var id -> List.filter (is_sensor symbol_t) [ id ]
    | Value v -> []
    | Binop (bop, e1, e2) ->
        expression_contains_sensor e1 symbol_t
        @ expression_contains_sensor e2 symbol_t
    | Uop (uop, expr) -> expression_contains_sensor expr symbol_t
    | ListIndex (id, expr) -> expression_contains_sensor expr symbol_t
    | Keyword k -> [])

let statement_contains_sensor statement symbol_t : string list =
  remove_duplicates
    (match statement with
    | Pass -> []
    | Push (id, expr) -> expression_contains_sensor expr symbol_t
    | Local_dec (vt, id, expr) -> expression_contains_sensor expr symbol_t
    | Assignment (id, expr) -> expression_contains_sensor expr symbol_t
    | For (_, _, _) -> []
    | Branch (expr, code, elifs, els) ->
        expression_contains_sensor expr symbol_t
    | Exception e -> [])
(*ignore the case where sensor is on LHS of assignment*)

let rec get_codeblock_sensors codeblock symbol_t : string list =
  remove_duplicates
    (match codeblock with
    | Branch (expr, code, _, els) :: t ->
        (expression_contains_sensor expr symbol_t
        @ get_codeblock_sensors code symbol_t
        @
        match els with Some c -> get_codeblock_sensors c symbol_t | None -> [])
        @ get_codeblock_sensors t symbol_t
    | head :: t ->
        statement_contains_sensor head symbol_t
        @ get_codeblock_sensors t symbol_t
    | [] -> [])
