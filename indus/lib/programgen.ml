open Ast
open Petr4
open Ast_util

(* open Petr4.Unix *)
include Codegen

let hydra_header = "hydra_header"

(*set all the metadata variabless from the lookup, then call the action*)
let get_var_name symbol_t var =
  match get_net_typ symbol_t var with
  | Header loc ->
      Surface.Expression.Name
        {
          tags = p4info_tpc;
          name = mk_p4name (String.sub loc 1 (String.length loc - 1));
        }
  | Control -> mk_named_expression_member "hydra_metadata" var
  | Tele -> mk_named_expression_member2 "hydra_header" "variables" var
  | Sensor ->
      mk_named_expression_member "hydra_metadata" var
      (*TODO: This should probably change*)
  | exception Not_found (*local var*) ->
      Surface.Expression.Name
        { tags = p4info_tpc; name = BareName (mk_p4string var) }

let check_valid_list idx loop =
  Surface.Expression.FunctionCall
    {
      tags = p4info_tpc;
      func =
        Name
          {
            tags = p4info_tpc;
            name =
              mk_p4name
                (Printf.sprintf "%s.%s[%d].isValid" hydra_header loop idx);
          };
      type_args = [];
      args = [];
    }

let mk_array_access iter list =
  Surface.Expression.ArrayAccess
    {
      tags = p4info_tpc;
      array =
        Surface.Expression.Name
          { tags = p4info_tpc; name = mk_p4name (hydra_header ^ "." ^ list) };
      index = Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int iter };
    }

let rec transform_binop bop expr1 expr2 symbol_t : Petr4.Surface.Expression.t =
  Surface.Expression.BinaryOp
    {
      tags = p4info_tpc;
      op =
        (match bop with
        | Plus -> Surface.Op.Plus { tags = p4info_tpc }
        | Minus -> Surface.Op.Minus { tags = p4info_tpc }
        | Times -> Surface.Op.Mul { tags = p4info_tpc }
        | Divide -> Surface.Op.Div { tags = p4info_tpc }
        | Mod -> Surface.Op.Mod { tags = p4info_tpc }
        | Band -> Surface.Op.BitAnd { tags = p4info_tpc }
        | Bor -> Surface.Op.BitOr { tags = p4info_tpc }
        | Bxor -> Surface.Op.BitXor { tags = p4info_tpc }
        | Equals -> Surface.Op.Eq { tags = p4info_tpc }
        | NEqual -> Surface.Op.NotEq { tags = p4info_tpc }
        | Lt -> Surface.Op.Lt { tags = p4info_tpc }
        | Le -> Surface.Op.Le { tags = p4info_tpc }
        | Gt -> Surface.Op.Gt { tags = p4info_tpc }
        | Ge -> Surface.Op.Ge { tags = p4info_tpc }
        | Land -> Surface.Op.And { tags = p4info_tpc }
        | Lor -> Surface.Op.Or { tags = p4info_tpc }
        | In -> failwith "impossible to match on In"
        | Notin -> failwith "Not in unimplemented"
        | Min -> failwith "Min unimplemented"
        | Max -> failwith "Max unimplemented");
      args = (transform_expr expr1 symbol_t, transform_expr expr2 symbol_t);
    }

and transform_uop uop expr symbol_t : Petr4.Surface.Expression.t =
  Surface.Expression.UnaryOp
    {
      tags = p4info_tpc;
      op =
        (match uop with
        | Bnot -> Surface.Op.BitNot { tags = p4info_tpc }
        | Lnot -> Surface.Op.Not { tags = p4info_tpc }
        | Abs -> failwith "Abs unimplemented"
        | Length -> failwith "length unimplemented");
      arg = transform_expr expr symbol_t;
    }

and transform_list_idx expr1 expr2 symbol_t =
  let array_access =
    Surface.Expression.ArrayAccess
      {
        tags = p4info_tpc;
        array = mk_named_expression_member hydra_header expr1;
        index = transform_expr expr2 symbol_t;
      }
  in
  Petr4.Surface.Expression.ExpressionMember
    { tags = p4info_tpc; expr = array_access; name = mk_p4string "value" }

and transform_keyword (keyword : keyword) : Petr4.Surface.Expression.t =
  Printf.printf "%s\n"
    (match keyword with
    | Path -> "Path"
    | Path_length -> "Path_length"
    | Packet_length -> "Packet_length"
    | Last_hop -> "Last hop"
    | First_hop -> "first_hop"
    | To_be_dropped -> "to be dropped");
  failwith "keywords unimplemented"

and transform_in expr1 list_expr symbol_t =
  let list =
    match list_expr with
    | Var id -> id
    | Keyword Path -> "path"
    | _ -> failwith "in must operate on list or path keyword"
  in

  let equals_check iter =
    let validity = check_valid_list iter list in
    let expr1_p4 = transform_expr expr1 symbol_t in
    let equals =
      Surface.Expression.BinaryOp
        {
          tags = p4info_tpc;
          op = Surface.Op.Eq { tags = p4info_tpc };
          args = (expr1_p4, mk_array_access iter list);
        }
    in
    Surface.Expression.BinaryOp
      {
        tags = p4info_tpc;
        op = Surface.Op.And { tags = p4info_tpc };
        args = (validity, equals);
      }
  in
  let length =
    match get_var_typ symbol_t list with
    | List (_, length) -> length
    | _ -> failwith "impossible for for loop to not be list"
  in
  let rec combine_checks iter =
    if iter = length - 1 then equals_check iter
    else
      Surface.Expression.BinaryOp
        {
          tags = p4info_tpc;
          op = Surface.Op.Or { tags = p4info_tpc };
          args = (equals_check iter, combine_checks (iter + 1));
        }
  in
  combine_checks 0

and transform_expr (expr : expr) symbol_t : Petr4.Surface.Expression.t =
  let open Petr4.Surface in
  match expr with
  | Value (Int n) -> Expression.Int { tags = p4info_tpc; x = mk_p4int n }
  | Value (Bool_const true) -> Expression.True { tags = p4info_tpc }
  | Value (Bool_const false) -> Expression.False { tags = p4info_tpc }
  | Value (List_const l) -> failwith "list constants unimplemented"
  | Var id ->
      (*TODO: this should depend on the id net_type*)
      (* Surface.Expression.Name
         { tags = p4info_tpc; name = BareName (mk_p4string id) } *)
      get_var_name symbol_t id
  | Binop (In, expr1, expr2) -> transform_in expr1 expr2 symbol_t
  | Binop (bop, expr1, expr2) -> transform_binop bop expr1 expr2 symbol_t
  | Uop (uop, expr) -> transform_uop uop expr symbol_t
  | ListIndex (expr1, expr2) -> transform_list_idx expr1 expr2 symbol_t
  | DictLookup (id, _) -> mk_named_expression_member "hydra_metadata" id
  | Keyword keyword -> transform_keyword keyword

let transform_assignment id expr symbol_t : Surface.Statement.t =
  (*check if LHS is sensor and if so change it to sensor.write(0, transform_expr(exp)) statement*)
  match get_net_typ symbol_t id with
  | Sensor ->
      Surface.Statement.MethodCall
        {
          tags = p4info_tpc;
          func = Name { tags = p4info_tpc; name = mk_p4name (id ^ ".write") };
          type_args = [];
          args =
            [
              Surface.Argument.Expression
                {
                  tags = p4info_tpc;
                  value =
                    Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int 0 };
                };
              Surface.Argument.Expression
                { tags = p4info_tpc; value = transform_expr expr symbol_t };
            ];
        }
  | (exception Not_found) | _ ->
      Surface.Statement.Assignment
        {
          tags = p4info_tpc;
          (*TODO: this should depend on var type*)
          lhs = get_var_name symbol_t id;
          rhs = transform_expr expr symbol_t;
        }

let transform_type symbol_t = function
  | Bit n ->
      Surface.Type.BitType
        { tags = p4info_tpc; expr = transform_expr (Value (Int n)) symbol_t }
  | Bool -> Surface.Type.Bool { tags = p4info_tpc }
  | List (typ, n) -> failwith "Impossible for List to be declared"
  | Set typ -> failwith "Impossible for set to be declared"
  | Dict (typ1, typ2) -> failwith "Impossible for set to be declared"

let transform_local_dec typ id expr (symbol_t : (net_type * 'a) SymbolTable.t) =
  Surface.Statement.DeclarationStatement
    {
      tags = p4info_tpc;
      decl =
        Surface.Declaration.Variable
          {
            tags = p4info_tpc;
            annotations = [];
            typ = transform_type symbol_t typ;
            name = mk_p4string id;
            init = Some (transform_expr expr symbol_t);
          };
    }

let transform_push id expr symbol_t =
  let push_front =
    Surface.Statement.MethodCall
      {
        tags = p4info_tpc;
        func =
          Name
            {
              tags = p4info_tpc;
              name = mk_p4name (hydra_header ^ "." ^ id ^ ".push_front");
            };
        type_args = [];
        args =
          [
            Surface.Argument.Expression
              {
                tags = p4info_tpc;
                value =
                  Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int 1 };
              };
          ];
      }
  in
  let set_valid =
    Surface.Statement.MethodCall
      {
        tags = p4info_tpc;
        func =
          Name
            {
              tags = p4info_tpc;
              name = mk_p4name (hydra_header ^ "." ^ id ^ "[0].setValid");
            };
        type_args = [];
        args = [];
      }
  in
  let assignment =
    Surface.Statement.Assignment
      {
        tags = p4info_tpc;
        lhs =
          Surface.Expression.Name
            {
              tags = p4info_tpc;
              name = mk_p4name (hydra_header ^ "." ^ id ^ "[0].value");
            };
        rhs = transform_expr expr symbol_t;
      }
  in
  let inc_preamble =
    Surface.Statement.Assignment
      {
        tags = p4info_tpc;
        lhs =
          Surface.Expression.Name
            {
              tags = p4info_tpc;
              name =
                mk_p4name
                  (Printf.sprintf "hydra_header.%s_preamble.num_items_%s" id id);
            };
        rhs =
          Surface.Expression.BinaryOp
            {
              tags = p4info_tpc;
              op = Surface.Op.Plus { tags = p4info_tpc };
              args =
                ( Surface.Expression.Name
                    {
                      tags = p4info_tpc;
                      name =
                        mk_p4name
                          (Printf.sprintf
                             "hydra_header.%s_preamble.num_items_%s" id id);
                    },
                  Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int 1 }
                );
            };
      }
  in
  [ push_front; set_valid; assignment; inc_preamble ]

let mk_pre_dict_assignment symbol_t lkp idx var =
  Surface.Statement.Assignment
    {
      tags = p4info_tpc;
      lhs =
        mk_named_expression_member "hydra_metadata"
          (Printf.sprintf "%s_var%d" lkp idx);
      rhs = get_var_name symbol_t var;
    }

let mk_pre_dict_lookup symbol_t = function
  | DictLookup (id, tup) ->
      let apply =
        Surface.Statement.DirectApplication
          {
            tags = p4info_tpc;
            typ =
              Surface.Type.TypeName
                {
                  tags = p4info_tpc;
                  name = mk_p4name ("tbl_lkp_cp_dict_" ^ id);
                };
            args = [];
          }
      in
      let assignments = List.mapi (mk_pre_dict_assignment symbol_t id) tup in
      assignments @ [ apply ]
  | _ -> failwith "Impossible. Must be DictLookup "

let mk_sensor_read sensor =
  Surface.Statement.MethodCall
    {
      tags = p4info_tpc;
      func = mk_named_expression_member sensor "read";
      type_args = [];
      args =
        [
          Surface.Argument.Expression
            {
              tags = p4info_tpc;
              value =
                Surface.Expression.Name
                  {
                    tags = p4info_tpc;
                    name = BareName (mk_p4string ("hydra_metadata." ^ sensor));
                  };
            };
          Surface.Argument.Expression
            {
              tags = p4info_tpc;
              value =
                Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int 0 };
            };
        ];
    }
(*TODO*)

let rec transform_for vars loops codeblock symbol_t =
  let decl_var id list =
    let var_t =
      match get_var_typ symbol_t list with
      | List (var_t, _) -> var_t
      | _ -> failwith "impossible for for loop to not be list"
    in
    Surface.Statement.DeclarationStatement
      {
        tags = p4info_tpc;
        decl =
          Surface.Declaration.Variable
            {
              tags = p4info_tpc;
              annotations = [];
              typ = transform_type symbol_t var_t;
              name = mk_p4string id;
              init = None;
            };
      }
  in
  let decls = List.map2 decl_var vars loops in
  let length =
    match get_var_typ symbol_t (List.hd loops) with
    | List (_, length) -> length
    | _ -> failwith "impossible for for loop to not be list"
  in

  (* for loop from 0 to length-1 do the if and then transform codeblock but add in assignment to beginning*)
  let rec transform_validity_checks = function
    | [] -> failwith "impossible to have empty list"
    | [ check ] -> check
    | check :: t ->
        let open Surface in
        Expression.BinaryOp
          {
            tags = p4info_tpc;
            op = Op.And { tags = p4info_tpc };
            args = (check, transform_validity_checks t);
          }
  in
  let assignments var_list loop_list iter =
    let assignment iter var loop =
      Surface.Statement.Assignment
        {
          tags = p4info_tpc;
          lhs =
            Surface.Expression.Name
              { tags = p4info_tpc; name = BareName (mk_p4string var) };
          rhs = mk_array_access iter loop;
        }
    in
    List.map2 (assignment iter) var_list loop_list
  in
  let rec unroll_loop iter =
    let validity_checks = List.map (check_valid_list iter) loops in
    let validity_expression = transform_validity_checks validity_checks in

    (*check to make sure its less than length*)
    Surface.Statement.Conditional
      {
        tags = p4info_tpc;
        cond = validity_expression;
        tru =
          Surface.Statement.BlockStatement
            {
              tags = p4info_tpc;
              block =
                {
                  tags = p4info_tpc;
                  annotations = [];
                  statements =
                    (let stmts =
                       List.flatten
                         [
                           assignments vars loops iter;
                           List.flatten
                             (List.map
                                (fun x -> transform_statement x symbol_t)
                                codeblock);
                         ]
                     in
                     if iter + 1 < length then
                       stmts @ [ unroll_loop (iter + 1) ]
                     else stmts);
                };
            };
        fls = None;
      }
  in
  List.flatten [ decls; [ unroll_loop 0 ] ]

and transform_statement (stmt : statement) symbol_t :
    Petr4.Surface.Statement.t list =
  let lookups = Ast_util.st_contains_dict_lookup stmt in
  let lookup_statements =
    List.flatten (List.map (mk_pre_dict_lookup symbol_t) lookups)
  in
  let sensors_read = Ast_util.statement_contains_sensor stmt symbol_t in
  let sensor_read_statements =
    List.map mk_sensor_read sensors_read
    (*TODO: Same thing with sensor. Lookup which ones are in the statement and then add the read for the metadata variable*)
  in
  let statements =
    match stmt with
    (*need to do lookahead for dictionary lookups*)
    | Pass -> failwith "Pass Unimplemented"
    | Push (id, expr) -> transform_push id expr symbol_t
    | Local_dec (var_type, id, expr) ->
        [ transform_local_dec var_type id expr symbol_t ]
    | Assignment (id, expr) -> [ transform_assignment id expr symbol_t ]
    | For (pair1, pair2, codeblock) ->
        transform_for pair1 pair2 codeblock symbol_t
    | Branch (expr, codeblock, elifs, els) ->
        [ transform_branch expr codeblock els symbol_t ]
    | Exception Report -> failwith "Report Unimplemented"
    | Exception Reject ->
        [
          transform_assignment "hydra_metadata.reject0"
            (Value (Bool_const true)) symbol_t;
        ]
  in
  sensor_read_statements @ lookup_statements @ statements

and transform_block (block : codeblock) (control : bool) symbol_t :
    Surface.Block.t =
  let bit2str = function
    | Bit n -> Printf.sprintf "bit<%d>" n
    | _ -> failwith "sensor must be of type bit<n>"
  in
  let mk_register_decl name : Surface.Statement.t =
    let typ = Ast_util.get_var_typ symbol_t name in
    Surface.Statement.DeclarationStatement
      {
        tags = p4info_tpc;
        decl =
          Surface.Declaration.Variable
            {
              tags = p4info_tpc;
              annotations = [];
              typ =
                Surface.Type.TypeName
                  {
                    tags = p4info_tpc;
                    name =
                      mk_p4name (Printf.sprintf "register<%s>(1)" (bit2str typ));
                  };
              name = mk_p4string name;
              init = None;
            };
      }
  in
  let sensors = Ast_util.get_codeblock_sensors block symbol_t in
  let sensor_decls =
    if control then List.map mk_register_decl sensors else []
  in
  (*look at sensors here and include the register<type>(1) var initialization, only if it's a control block*)
  {
    tags = p4info_tpc;
    annotations = [];
    statements =
      sensor_decls
      @ List.flatten (List.map (fun x -> transform_statement x symbol_t) block);
  }

and transform_branch expr codeblock els symbol_t =
  let open Surface.Statement in
  Conditional
    {
      tags = p4info_tpc;
      cond = transform_expr expr symbol_t;
      tru =
        BlockStatement
          {
            tags = p4info_tpc;
            block = transform_block codeblock false symbol_t;
          };
      fls =
        (match els with
        | Some code ->
            Some
              (BlockStatement
                 {
                   tags = p4info_tpc;
                   block = transform_block code false symbol_t;
                 })
        | None -> None);
    }

let mk_parameter (dir : Surface.Direction.t) (typ_name : string) (name : string)
    : Surface.Parameter.t =
  {
    tags = p4info_tpc;
    annotations = [];
    direction = Some dir;
    typ = TypeName { tags = p4info_tpc; name = BareName (mk_p4string typ_name) };
    variable = mk_p4string name;
    opt_value = None;
  }

let mk_action_parameter typ name : Surface.Parameter.t =
  {
    tags = p4info_tpc;
    annotations = [];
    direction = None;
    typ;
    variable = mk_p4string name;
    opt_value = None;
  }

let mk_parameter_list : Surface.Parameter.t list =
  [
    mk_parameter
      (Surface.Direction.InOut { tags = p4info_tpc })
      "hydra_header_t" "hydra_header";
    mk_parameter
      (Surface.Direction.InOut { tags = p4info_tpc })
      "hydra_metadata_t" "hydra_metadata";
  ]

let mk_control_init_action symbol_t =
  let init_vars = Ast_util.get_cp_non_dict symbol_t in
  if List.length init_vars = 0 then None
  else
    let mk_action_param (name, (net_t, var_t)) =
      let typ = transform_type symbol_t var_t in
      mk_action_parameter typ name
    in
    let names = List.map (fun (name, (_, _)) -> name) init_vars in
    let mk_assignment name =
      Surface.Statement.Assignment
        {
          tags = p4info_tpc;
          lhs = mk_named_expression_member "hydra_metadata" name;
          rhs = Name { tags = p4info_tpc; name = mk_p4name name };
        }
    in
    let params = List.map mk_action_param init_vars in
    let assignments = List.map mk_assignment names in
    Some
      (Surface.Declaration.Action
         {
           tags = p4info_tpc;
           annotations = [];
           name = mk_p4string "init_cp_vars";
           params;
           body =
             { tags = p4info_tpc; annotations = []; statements = assignments };
         })

let mk_control_init_tb =
  Petr4.Surface.Declaration.Table
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string "tb_init_cp_vars";
      properties =
        [
          Key
            {
              tags = p4info_tpc;
              keys =
                [
                  {
                    tags = p4info_tpc;
                    annotations = [];
                    key =
                      mk_named_expression_member2 hydra_header "eth_type"
                        "isValid()";
                    match_kind = mk_p4string "exact";
                  };
                ];
            };
          Actions
            {
              tags = p4info_tpc;
              actions =
                [
                  {
                    tags = p4info_tpc;
                    annotations = [];
                    name = BareName { tags = p4info_tpc; str = "init_cp_vars" };
                    args = [];
                  };
                ];
            };
          Custom
            {
              tags = p4info_tpc;
              annotations = [];
              const = false;
              name = mk_p4string "size";
              value = mk_const_int_expression 2;
            };
        ];
    }

let mk_control_init_apply =
  Surface.Statement.DirectApplication
    {
      tags = p4info_tpc;
      typ =
        Surface.Type.TypeName
          { tags = p4info_tpc; name = mk_p4name "tb_init_cp_vars" };
      args = [];
    }

let mk_dict_action name out_typ symbol_t =
  (*typ comes from output type of dict *)
  let typ = transform_type symbol_t out_typ in
  let param = mk_action_parameter typ name in
  let assignment =
    Surface.Statement.Assignment
      {
        tags = p4info_tpc;
        lhs = mk_named_expression_member "hydra_metadata" name;
        rhs = Name { tags = p4info_tpc; name = mk_p4name name };
      }
  in
  Surface.Declaration.Action
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string ("lkp_cp_dict_" ^ name);
      params = [ param ];
      body =
        { tags = p4info_tpc; annotations = []; statements = [ assignment ] };
    }

let mk_dict_table name keys =
  Petr4.Surface.Declaration.Table
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string ("tbl_lkp_cp_dict_" ^ name);
      properties =
        [
          Key { tags = p4info_tpc; keys };
          Actions
            {
              tags = p4info_tpc;
              actions =
                [
                  {
                    tags = p4info_tpc;
                    annotations = [];
                    name =
                      BareName
                        { tags = p4info_tpc; str = "lkp_cp_dict_" ^ name };
                    args = [];
                  };
                ];
            };
          Custom
            {
              tags = p4info_tpc;
              annotations = [];
              const = false;
              name = mk_p4string "size";
              value = mk_const_int_expression 64;
            };
        ];
    }

let insert_stmts_block stmts (block : Surface.Block.t) : Surface.Block.t =
  match block with
  | { tags; annotations; statements = _statements } ->
      { tags; annotations; statements = stmts @ _statements }

let insert_stmts_block_end stmts (block : Surface.Block.t) : Surface.Block.t =
  match block with
  | { tags; annotations; statements = _statements } ->
      { tags; annotations; statements = _statements @ stmts }

let mk_tele_var_assignment lhs_name rhs =
  Surface.Statement.Assignment
    {
      tags = p4info_tpc;
      lhs = mk_named_expression_member "hydra_header" lhs_name;
      rhs;
    }

let mk_tele_var_assignment_name lhs_name rhs_name =
  let rhs =
    Surface.Expression.Name { tags = p4info_tpc; name = mk_p4name rhs_name }
  in
  mk_tele_var_assignment lhs_name rhs

let mk_valid var =
  Surface.Statement.MethodCall
    {
      tags = p4info_tpc;
      func = mk_named_expression_member2 "hydra_header" var "setValid";
      type_args = [];
      args = [];
    }

let mk_push_variables symbol_t =
  (* make this into an action ?*)
  (* let tele_vars = Ast_util.get_tele_vars symbol_t in *)
  let list_vars = Ast_util.get_list_vars symbol_t in
  let eth_typ_valid = mk_valid "eth_type" in
  let eth_typ_assignment =
    mk_tele_var_assignment_name "eth_type.value" "ETHERTYPE_CHECKER"
  in
  let variables_valid = mk_valid "variables" in
  let preamble_assignments =
    List.map
      (fun x ->
        mk_tele_var_assignment
          (Printf.sprintf "%s_preamble.num_items_%s" x x)
          (Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int 0 }))
      list_vars
  in
  (* let variables_assignment =
       List.map
         (fun x ->
           mk_tele_var_assignment ("variables." ^ x)
             (Surface.Expression.Int { tags = p4info_tpc; x = mk_p4int 0 }))
         tele_vars
     in *)
  [ eth_typ_valid; eth_typ_assignment; variables_valid ] @ preamble_assignments

let mk_invalid var =
  Surface.Statement.MethodCall
    {
      tags = p4info_tpc;
      func = mk_named_expression_member2 "hydra_header" var "setInvalid";
      type_args = [];
      args = [];
    }

let mk_strip_telemetry symbol_t =
  let list_vars = Ast_util.get_list_vars symbol_t in
  let eth_type_invalid = mk_invalid "eth_type" in
  let variables_invalid = mk_invalid "variables" in
  let preamble_invalids =
    List.map (fun x -> mk_invalid (Printf.sprintf "%s_preamble" x)) list_vars
  in
  let invalidate_list id =
    let rec range n = if n <= 0 then [] else (n - 1) :: range (n - 1) in
    let invalidate_index idx = mk_invalid (Printf.sprintf "%s[%d]" id idx) in
    match Ast_util.get_var_typ symbol_t id with
    | List (name, n) -> List.map invalidate_index (List.rev (range n))
    | _ -> failwith "impossible. Must be a list"
  in
  let list_invalidates = List.map invalidate_list list_vars in
  [ eth_type_invalid; variables_invalid ]
  @ preamble_invalids
  @ List.flatten list_invalidates

let mk_tb_lkp_key lkp idx typ : Surface.Table.key =
  {
    tags = p4info_tpc;
    annotations = [];
    key =
      mk_named_expression_member "hydra_metadata"
        (Printf.sprintf "%s_var%d" lkp idx);
    match_kind = mk_p4string "exact";
  }

let mk_dict_declarations codeblock symbol_t =
  let decls = Ast_util.get_codeblock_lookups codeblock in
  let uniq_dicts =
    List.map
      (function
        | DictLookup (id, _) -> id
        | _ -> failwith "Impossible to not be DictLookup")
      decls
    |> Ast_util.remove_duplicates
  in
  if List.length uniq_dicts = 0 then None
  else
    let mk_dict_declaration symbol_t lkp =
      let in_types, out_type =
        match Ast_util.get_var_typ symbol_t lkp with
        | Dict (in_types, out_type) -> (in_types, out_type)
        | _ -> failwith "Impossible. Must be Dict type"
      in
      let keys = List.mapi (mk_tb_lkp_key lkp) in_types in
      let table = mk_dict_table lkp keys in
      let action = mk_dict_action lkp out_type symbol_t in
      [ action; table ]
    in
    Some (List.flatten (List.map (mk_dict_declaration symbol_t) uniq_dicts))

(*Returns a Control block, containing the init code*)
let transform_init (Init init_block) symbol_t : Petr4.Surface.Declaration.t =
  let control_non_dict_action = mk_control_init_action symbol_t in
  let control_dict_decls = mk_dict_declarations init_block symbol_t in
  let locals =
    match (control_non_dict_action, control_dict_decls) with
    | None, None -> []
    | Some action, None -> [ action; mk_control_init_tb ]
    | None, Some action -> action
    | Some action1, Some action2 -> [ action1; mk_control_init_tb ] @ action2
  in
  let push_variables = mk_push_variables symbol_t in
  let block =
    transform_block init_block true symbol_t
    |> insert_stmts_block push_variables
  in
  Control
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string "initControl";
      type_params = [];
      params = mk_parameter_list;
      constructor_params = [];
      locals;
      apply =
        (match control_non_dict_action with
        | None -> block
        | Some _ -> insert_stmts_block [ mk_control_init_apply ] block);
    }

(* Returns a Control block, containing the Telemetry code*)
let transform_telemetry (Telemetry tele_block) symbol_t :
    Petr4.Surface.Declaration.t =
  let control_non_dict_action = mk_control_init_action symbol_t in
  let control_dict_decls = mk_dict_declarations tele_block symbol_t in
  let locals =
    match (control_non_dict_action, control_dict_decls) with
    | None, None -> []
    | Some action, None -> [ action; mk_control_init_tb ]
    | None, Some action -> action
    | Some action1, Some action2 -> [ action1; mk_control_init_tb ] @ action2
  in
  Control
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string "telemetryControl";
      type_params = [];
      params = mk_parameter_list;
      constructor_params = [];
      locals;
      apply =
        (match control_non_dict_action with
        | None -> transform_block tele_block true symbol_t
        | Some _ ->
            insert_stmts_block [ mk_control_init_apply ]
              (transform_block tele_block true symbol_t));
    }

let transform_checker (Check checker_block : check) symbol_t :
    Petr4.Surface.Declaration.t =
  let control_non_dict_action = mk_control_init_action symbol_t in
  let control_dict_decls = mk_dict_declarations checker_block symbol_t in
  let locals =
    match (control_non_dict_action, control_dict_decls) with
    | None, None -> []
    | Some action, None -> [ action; mk_control_init_tb ]
    | None, Some action -> action
    | Some action1, Some action2 -> [ action1; mk_control_init_tb ] @ action2
  in
  let strip_variables = mk_strip_telemetry symbol_t in
  let block =
    transform_block checker_block true symbol_t
    |> insert_stmts_block_end strip_variables
  in
  Control
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string "checkerControl";
      type_params = [];
      params = mk_parameter_list;
      constructor_params = [];
      locals;
      apply =
        (match control_non_dict_action with
        | None -> block
        | Some _ -> insert_stmts_block [ mk_control_init_apply ] block);
    }
