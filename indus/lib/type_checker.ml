open Ast
module Env = Map.Make (String)

exception TypeError of string
exception UndeclaredVar of string
exception DuplicateDecl of string

(*TODO: Add type checking for dictionary list*)
(*TODO: dictionary lookup var type list cannot be empty*)
let empty_env = Env.empty

let add_type env id ((net_typ : Ast.net_type option), (typ : Ast.var_type)) =
  if Env.mem id env then
    raise (DuplicateDecl ("Variable " ^ id ^ " has already been declared"))
  else Env.add id (net_typ, typ) env

let get_type (env : (net_type option * var_type) Env.t) id : var_type =
  match Env.find id env with
  | exception Not_found -> raise (UndeclaredVar ("Undeclared variable " ^ id))
  | net_typ, typ -> typ

let get_net_type (env : (net_type option * var_type) Env.t) id : net_type option
    =
  match Env.find id env with
  | exception Not_found -> raise (UndeclaredVar ("Undeclared variable " ^ id))
  | net_typ, typ -> net_typ

let type2str typ =
  Format.asprintf "@[%a@]" Pp.to_fmt (Pretty.format_var_type typ)

let rec tequal t1 t2 ctxt =
  match (t1, t2) with
  | Bit _, Bit _ -> Bit 0
  | Bool, Bool -> Bool
  | List (typ, _), List (typ2, _) -> List (tequal typ typ2 ctxt, 0)
  | Set typ, Set typ2 -> Set (tequal typ typ2 ctxt)
  | Dict (typ, typ2), Dict (typ3, typ4) ->
      failwith "Should never compare 2 dicts"
      (* Dict (tequal typ typ3 ctxt, tequal typ3 typ4 ctxt) *)
  | _ ->
      raise
        (TypeError
           (Printf.sprintf "Issue with %s, types %s and %s" ctxt (type2str t1)
              (type2str t2)))

let check_dec net_typ var_typ =
  match (net_typ, var_typ) with
  | Tele, Bool -> ()
  | Tele, Bit n -> ()
  | Tele, List (t, n) -> ()
  | Sensor, Bool -> ()
  | Sensor, Bit n -> ()
  | Header loc, Bool -> ()
  | Header loc, Bit n -> ()
  | Control, _ -> ()
  | net, var ->
      raise
        (TypeError
           (Format.asprintf "@[Declaration types %a and %a not allowed@]"
              Pp.to_fmt
              (Pretty.format_net_type net)
              Pp.to_fmt
              (Pretty.format_var_type var)))

let extend_env_dec env = function
  | Decl (net_t, var_t, id) ->
      check_dec net_t var_t;
      add_type env id (Some net_t, var_t)

(* let rec add_decs env decs_list =
   match decs_list with
   | [] -> env
   | Decl (net_t, var_t, id) :: t ->
       let new_env = add_type env id var_t in
       add_decs new_env t *)

let add_decs env decs_list = List.fold_left extend_env_dec env decs_list

let rec type_value = function
  | Int _ -> Bit 0
  | Bool_const _ -> Bool
  | List_const l -> (
      match l with
      | [] -> raise (TypeError "Cannot have empty list value")
      | h :: t -> List (check_list l, 0))

and check_list = function
  | h :: [] -> type_value h
  | h :: t ->
      let h_typ = type_value h in
      let t_typ = check_list t in
      tequal h_typ t_typ "list"
  | [] -> failwith "impossible"

let rec check_expr env expr : var_type =
  match expr with
  | Var id -> get_type env id
  | Value v -> type_value v
  | Binop (bop, e1, e2) -> check_binop env bop e1 e2
  | Uop (uop, e) -> check_uop env uop e
  | ListIndex (e1, e2) -> check_index env e1 e2
  | DictLookup (id, tup) -> check_dict_lookup env id tup
  | Keyword k -> (
      match k with
      | Path -> List (Bit 0, 0)
      | Path_length -> Bit 0
      | Packet_length -> Bit 0
      | Last_hop -> Bool
      | First_hop -> Bool
      | To_be_dropped -> Bool)

and check_binop env bop e1 e2 =
  let t1 = check_expr env e1 in
  let t2 = check_expr env e2 in
  let bop_str = Format.asprintf "@[%a@]" Pp.to_fmt (Pretty.format_bop bop) in
  match bop with
  | In -> check_binop_in t1 t2
  | Notin -> failwith "Unimplemented"
  | Land | Lor ->
      let typ = tequal t1 t2 bop_str in
      tequal typ Bool bop_str
  | Equals | NEqual | Lt | Le | Gt | Ge ->
      let typ = tequal t1 t2 bop_str in
      ignore (tequal typ (Bit 0) bop_str);
      Bool
  | Plus | Minus | Times | Divide | Mod | Band | Bor | Bxor | Min | Max ->
      let typ = tequal t1 t2 bop_str in
      tequal typ (Bit 0) bop_str

and check_binop_in t1 t2 =
  (*t2 has to be a list and of list type t1*)
  (*returns bool*)
  match t2 with
  | List (typ, _) ->
      ignore (tequal typ t1 "IN expression");
      Bool
  | _ -> raise (TypeError "IN expression must operate on List")

and check_push t1 t2 =
  (* t2 is a list and of list type t1*)
  (*returns list of type t2*)
  match t1 with
  | List (typ, _) ->
      ignore (tequal typ t2 "push expression");
      ()
  | _ -> raise (TypeError "Push expression must operate on List")

and check_uop env uop e =
  let typ = check_expr env e in
  match uop with
  | Bnot -> tequal typ (Bit 0) "Bnot"
  | Abs -> tequal typ (Bit 0) "Abs"
  | Lnot -> tequal typ Bool "Lnot"
  | Length -> (
      match typ with
      | List (_, _) -> Bit 0
      | _ -> raise (TypeError "length expression must operate on a List"))

and check_index env e1 e2 =
  let t1 = get_type env e1 in
  let t2 = check_expr env e2 in
  match t1 with
  | List (typ, _) ->
      ignore (tequal t2 (Bit 0) "List index");
      typ
  | Dict (typ1, typ2) ->
      failwith "impossible to have dict in list index"
      (* ignore (tequal t2 typ1 "Dictionary index");
         typ2 *)
  | _ -> raise (TypeError "indexing must operate on List")

and check_dict_lookup env id tup =
  let () =
    match get_net_type env id with
    | Some Control -> ()
    | _ -> raise (TypeError "dict lookup must be a control type variable")
  in
  let t1 = get_type env id in
  let in_types = List.map (get_type env) tup in
  match t1 with
  | Dict (typ_list, typ) ->
      ignore (List.map2 (fun x y -> tequal x y "Dict lookup") in_types typ_list);
      typ
  | _ -> raise (TypeError "dict lookup must operate on Dict")

let check_assignment env id expr =
  let id_type = get_type env id in
  let expr_type = check_expr env expr in
  (*make sure header type is read-only*)
  (match get_net_type env id with
  | Some (Header loc) ->
      raise
        (TypeError "Header type is read-only and cannot be in an assignment")
  | Some Control ->
      raise
        (TypeError "Control type is read-only and cannot be in an assignment")
  | _ -> ());
  ignore (tequal id_type expr_type "assignment")

let rec check_codeblock env codeblock =
  match codeblock with
  | [] -> ()
  | statement :: t -> (
      match check_statement env statement with
      | Some new_env -> check_codeblock new_env t
      | None -> check_codeblock env t)

and check_statement env statement =
  match statement with
  | Pass -> None
  | Push (id, expr) ->
      let t1 = get_type env id in
      let t2 = check_expr env expr in
      check_push t1 t2;
      None
  | Local_dec (typ, id, expr) ->
      let new_env = check_local_dec env typ id expr in
      Some new_env
  | Assignment (id, expr) ->
      check_assignment env id expr;
      None
  | For (p1, p2, code) ->
      check_for env p1 p2 code;
      None
  | Branch (expr, code, elifs, els) ->
      check_branch env expr code elifs els;
      None
  | Exception exn -> None

and check_branch env expr code elifs els =
  check_conditional env expr code;
  ignore
    (List.map
       (function Elif (expr, code) -> check_conditional env expr code)
       elifs);
  match els with Some c -> check_codeblock env c | None -> ()

and check_conditional env expr code =
  let expr_type = check_expr env expr in
  ignore (tequal expr_type Bool "If guard");
  check_codeblock env code

(* make sure lengths are the same of p1 and p2. Make sure all of P2 are lists
   Create new declarations of each of P1 with type of P2 list and then use that env to check code *)
and check_for env p1 p2 code =
  let rec create_env env p1 p2 =
    match (p1, p2) with
    | h1 :: t1, h2 :: t2 -> (
        match get_type env h2 with
        | List (typ, _) -> create_env (add_type env h1 (None, typ)) t1 t2
        | _ -> raise (TypeError "RHS of for loop must be list type"))
    | [], [] -> env
    | _ -> raise (TypeError "patterns in for loop must be the same length")
  in
  let new_env = create_env env p1 p2 in
  check_codeblock new_env code

and check_local_dec env typ id expr =
  let new_env = add_type env id (None, typ) in
  let expr_type = check_expr env expr in
  ignore (tequal typ expr_type "local declaration");
  new_env

let check_program (prog : Ast.program) =
  match prog with
  | Program (decl_list, Init c1, Telemetry c2, Check c3) ->
      let env = add_decs empty_env decl_list in
      check_codeblock env c1;
      check_codeblock env c2;
      check_codeblock env c3
