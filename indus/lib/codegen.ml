open Ast
(* open Petr4.Unix *)

exception Error of string
exception UnsupportedError of string

let cfg =
  Petr4.Pass.
    {
      cfg_infile = "examples/complete_checker.tna.p4";
      cfg_includes = [ "examples"; "examples/fabric-tna/p4src/shared" ];
      cfg_verbose = false;
    }

(* let result = Driver.run_parser cfg *)
(* let surface_program = Petr4.Common.handle_error result *)

let get_decl_list surface_program =
  match surface_program with Petr4.Surface.Program decls -> decls

(* let decl_list = get_decl_list surface_program *)

let get_fname_from_decl0 decl : string option * Petr4.Surface.Declaration.t =
  let open Petr4.Surface.Declaration in
  let open Petr4.P4info in
  match decl with
  | Constant { tags; _ }
  | Instantiation { tags; _ }
  | Parser { tags; _ }
  | Control { tags; _ }
  | Function { tags; _ }
  | ExternFunction { tags; _ }
  | Variable { tags; _ }
  | ValueSet { tags; _ }
  | Action { tags; _ }
  | Table { tags; _ }
  | Header { tags; _ }
  | HeaderUnion { tags; _ }
  | Struct { tags; _ }
  | Enum { tags; _ }
  | SerializableEnum { tags; _ }
  | ExternObject { tags; _ }
  | TypeDef { tags; _ }
  | NewType { tags; _ }
  | ControlType { tags; _ }
  | ParserType { tags; _ }
  | PackageType { tags; _ }
  | Error { tags; _ }
  | MatchKind { tags; _ } ->
      let filename_opt =
        match tags with I i -> Some i.filename | M m -> None
      in
      (filename_opt, decl)

(* All possible sub types of the [Declaration.t] type using Obj.magic *)
let get_fname_from_decl1 (decl : Petr4.Surface.Declaration.t) =
  let outer_record = Obj.magic decl in
  match outer_record.contents with
  | Petr4.P4info.I i -> (Some i.filename, decl)
  | Petr4.P4info.M m -> (None, decl)

(* let decl_fnames = List.map get_fname_from_decl1 decl_list *)

let filter_decl_fnames (fname_s : string)
    (decl_fnames : (string option * Petr4.Surface.Declaration.t) list) =
  let filter_f item =
    match fst item with
    | Some fname_t -> String.equal fname_s fname_t
    | None -> false
  in
  List.filter filter_f decl_fnames

(* let filtered_decl_fnames =
   filter_decl_fnames "examples/complete_checker.tna.p4" decl_fnames *)

let find_p4decl_type (decl : Petr4.Surface.Declaration.t) =
  let open Petr4.Surface.Declaration in
  match decl with
  | Constant { tags; _ } -> "constant"
  | Instantiation { tags; _ } -> "instantiation"
  | Parser { tags; _ } -> "parser"
  | Control { tags; _ } -> "control"
  | Function { tags; _ } -> "function"
  | ExternFunction { tags; _ } -> "externfunction"
  | Variable { tags; _ } -> "variable"
  | ValueSet { tags; _ } -> "valueset"
  | Action { tags; _ } -> "action"
  | Table { tags; _ } -> "table"
  | Header { tags; _ } -> "header"
  | HeaderUnion { tags; _ } -> "headerunion"
  | Struct { tags; _ } -> "struct"
  | Enum { tags; _ } -> "enum"
  | SerializableEnum { tags; _ } -> "serializableenum"
  | ExternObject { tags; _ } -> "externobject"
  | TypeDef { tags; _ } -> "typedef"
  | NewType { tags; _ } -> "newtype"
  | ControlType { tags; _ } -> "controltype"
  | ParserType { tags; _ } -> "parsertype"
  | PackageType { tags; _ } -> "packagetype"
  | Error { tags; _ } -> "error"
  | MatchKind { tags; _ } -> "matchkind"

let p4info_tpc = Petr4.P4info.M "tpc"

let mk_p4string (p4string : string) : Petr4.P4string.t =
  { Poulet4.P4String.tags = p4info_tpc; str = p4string }

let mk_p4int p4_int : Petr4.P4int.t =
  (* Figure out how to construct a bigint *)
  {
    Poulet4.P4Int.tags = p4info_tpc;
    value = Bigint.of_int p4_int;
    (*janesreet Bigint module*)
    width_signed = None;
  }

let mk_p4int_width p4_int width : Petr4.P4int.t =
  (* Figure out how to construct a bigint *)
  {
    Poulet4.P4Int.tags = p4info_tpc;
    value = Bigint.of_int p4_int;
    (*janesreet Bigint module*)
    width_signed = Some (Bigint.of_int width, false);
  }

let mk_p4name p4_name : Petr4.P4name.t = BareName (mk_p4string p4_name)

let mk_const_int_expression n : Petr4.Surface.Expression.t =
  Petr4.Surface.Expression.Int
    {
      tags = p4info_tpc;
      x =
        {
          Poulet4.P4Int.tags = p4info_tpc;
          value = Bigint.of_int n;
          width_signed = None;
        };
    }

let mk_named_expression_member (s : string) (t : string) :
    Petr4.Surface.Expression.t =
  Petr4.Surface.Expression.ExpressionMember
    {
      tags = p4info_tpc;
      expr =
        Petr4.Surface.Expression.Name
          { tags = p4info_tpc; name = Poulet4.Typed.BareName (mk_p4string s) };
      name = mk_p4string t;
    }

let mk_named_expression_member2 (s : string) (t : string) (u : string) :
    Petr4.Surface.Expression.t =
  Petr4.Surface.Expression.ExpressionMember
    {
      tags = p4info_tpc;
      expr =
        Petr4.Surface.Expression.ExpressionMember
          {
            tags = p4info_tpc;
            expr =
              Petr4.Surface.Expression.Name
                {
                  tags = p4info_tpc;
                  name = Poulet4.Typed.BareName (mk_p4string s);
                };
            name = mk_p4string t;
          };
      name = mk_p4string u;
    }

let mk_decl_field_bool (var_name : string) : Petr4.Surface.Declaration.field =
  {
    tags = p4info_tpc;
    annotations = [];
    typ = Petr4.Surface.Type.Bool { tags = p4info_tpc };
    name = mk_p4string var_name;
  }

let mk_decl_field_bitn (n : int) (var_name : string) :
    Petr4.Surface.Declaration.field =
  {
    tags = p4info_tpc;
    annotations = [];
    typ =
      Petr4.Surface.Type.BitType
        { tags = p4info_tpc; expr = mk_const_int_expression n };
    name = mk_p4string var_name;
  }

let mk_decl_field_barename (type_bare_name : string) (var_name : string) :
    Petr4.Surface.Declaration.field =
  {
    tags = p4info_tpc;
    annotations = [];
    typ =
      Petr4.Surface.Type.TypeName
        {
          tags = p4info_tpc;
          name = Poulet4.Typed.BareName (mk_p4string type_bare_name);
        };
    name = mk_p4string var_name;
  }

let mk_decl_field_barename_headerstack (stack_size : int) (var_name : string) :
    Petr4.Surface.Declaration.field =
  let type_barename = String.cat var_name "_item_t" in
  {
    tags = p4info_tpc;
    annotations = [];
    typ =
      Petr4.Surface.Type.HeaderStack
        {
          tags = p4info_tpc;
          header =
            Petr4.Surface.Type.TypeName
              {
                tags = p4info_tpc;
                name = Poulet4.Typed.BareName (mk_p4string type_barename);
              };
          size = mk_const_int_expression stack_size;
        };
    name = mk_p4string var_name;
  }

type base_p4header_type =
  | BBool
  | BBit of int
  | BBareName of string
  | BBareNameStack of int * string

let mk_p4header_decl (var_type_and_name : base_p4header_type * string) =
  let var_type = fst var_type_and_name in
  let var_name = snd var_type_and_name in
  match var_type with
  | BBool -> mk_decl_field_bool var_name
  | BBit n -> mk_decl_field_bitn n var_name
  | BBareName var_type -> mk_decl_field_barename var_type var_name
  | BBareNameStack (m, _) -> mk_decl_field_barename_headerstack m var_name

let mk_p4header (vars : (base_p4header_type * string) list)
    (header_name : string) =
  let padded_vars =
    let sum_bits =
      let nbits (args : base_p4header_type * string) =
        match fst args with BBool -> 1 | BBit n -> n | _ -> 0
      in
      List.fold_left ( + ) 0 (List.map nbits vars)
    in
    let pad = (8 - (sum_bits mod 8)) mod 8 in
    let is_pad_needed = pad != 0 in
    if is_pad_needed then List.append vars [ (BBit pad, "_pad") ] else vars
  in
  Petr4.Surface.Declaration.Header
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string header_name;
      fields = List.map mk_p4header_decl padded_vars;
    }

let mk_p4struct (vars : (base_p4header_type * string) list)
    (header_name : string) =
  Petr4.Surface.Declaration.Struct
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string header_name;
      fields = List.map mk_p4header_decl vars;
    }

let mk_p4type (typ : base_p4header_type) : Petr4.Surface.Type.t =
  match typ with
  | BBool -> Petr4.Surface.Type.Bool { tags = p4info_tpc }
  | BBit n ->
      Petr4.Surface.Type.BitType
        { tags = p4info_tpc; expr = mk_const_int_expression n }
  | BBareName vn ->
      Petr4.Surface.Type.TypeName
        { tags = p4info_tpc; name = Poulet4.Typed.BareName (mk_p4string vn) }
  | BBareNameStack _ -> failwith "unsupported stack type in control"

let mk_p4parameter_generic (dir : Petr4.Surface.Direction.t option)
    (param : base_p4header_type * string) : Petr4.Surface.Parameter.t =
  {
    tags = p4info_tpc;
    annotations = [];
    direction = dir;
    typ = mk_p4type (fst param);
    variable = mk_p4string (snd param);
    opt_value = None;
  }

let get_header_decl_for_variables_header (tpc_decls : decl list) (b : built_ins)
    =
  let path_length_decl =
    if b.path_length then [ (BBit 8, "path_length") ] else []
  in
  let to_p4header_decl (decl : decl) =
    match decl with
    | Decl (Tele, Bool, var_name) -> [ (BBool, var_name) ]
    | Decl (Tele, Bit n, var_name) -> [ (BBit n, var_name) ]
    | _ -> []
  in
  let p4variables_hdr_decls =
    List.append
      (List.flatten (List.map to_p4header_decl tpc_decls))
      path_length_decl
  in
  mk_p4header p4variables_hdr_decls "variables_t"

let get_header_decls_for_list_var (list_item_type : base_p4header_type)
    (list_var_name : string) =
  let preamble_header =
    [
      mk_p4header
        [ (BBit 8, "num_items_" ^ list_var_name) ]
        (list_var_name ^ "_preamble_t");
    ]
  in
  let list_item_header =
    match list_item_type with
    | BBit n ->
        [ mk_p4header [ (BBit n, "value") ] (list_var_name ^ "_item_t") ]
    | BBool -> [ mk_p4header [ (BBool, "value") ] (list_var_name ^ "_item_t") ]
    | _ -> []
  in
  List.append preamble_header list_item_header

let get_header_decls_for_list_vars (tpc_decls : decl list) =
  let is_list_var (tele_decl : decl) =
    match tele_decl with Decl (Tele, List (_, _), _) -> true | _ -> false
  in
  let list_vars = List.filter is_list_var tpc_decls in
  let mk_p4headers (decl : decl) =
    match decl with
    | Decl (_, List (Bool, _), vn) -> get_header_decls_for_list_var BBool vn
    | Decl (_, List (Bit n, _), vn) -> get_header_decls_for_list_var (BBit n) vn
    | _ -> []
  in
  List.flatten (List.map mk_p4headers list_vars)

let get_struct_decl_for_hydra_metadata (tpc_decls : decl list) =
  let is_list_var (tele_decl : decl) =
    match tele_decl with Decl (Tele, List (_, _), _) -> true | _ -> false
  in
  let list_vars = List.filter is_list_var tpc_decls in
  let symbol_t = Ast_util.symbol_table_decl_list tpc_decls in
  let control_vars = Ast_util.get_control_vars symbol_t in
  let dict_vars = Ast_util.get_dict_vars symbol_t in
  let type_to_struct_decl typ var =
    match typ with
    | Bit n -> (BBit n, var)
    | Bool -> (BBool, var)
    | Dict (_, typ) -> (
        match typ with
        | Bit n -> (BBit n, var)
        | Bool -> (BBool, var)
        | _ -> failwith "impossible. Type must be bit or bool")
    | _ -> failwith "Impossible. cannot be list or set"
  in
  let to_struct_decl var =
    type_to_struct_decl (Ast_util.get_var_typ symbol_t var) var
  in
  let dict_helper_decls dict =
    let rec range n = if n <= 0 then [] else (n - 1) :: range (n - 1) in
    match Ast_util.get_var_typ symbol_t dict with
    | Dict (var_types, _) ->
        let names =
          List.map
            (fun x -> Printf.sprintf "%s_var%d" dict x)
            (List.rev (range (List.length var_types)))
        in
        List.map2 type_to_struct_decl var_types names
    | _ -> failwith "Impossible. Must be dict"
  in
  let p4struct_decls =
    (BBool, "reject0")
    ::
    (if List.length list_vars > 0 then [ (BBit 8, "num_list_items") ] else [])
    @ List.map to_struct_decl control_vars
    @ List.flatten (List.map dict_helper_decls dict_vars)
  in
  mk_p4struct p4struct_decls "hydra_metadata_t"

let get_struct_decl_for_hydra_header (tpc_decls : decl list) (b : built_ins) =
  let p4struct_decls =
    let base_decls =
      [
        (BBareName "eth_type2_t", "eth_type");
        (BBareName "variables_t", "variables");
      ]
    in
    let path_decls =
      if b.path then
        [
          (BBareName "hops_preamble_t", "hops_preamble");
          (BBareNameStack (4, "hop"), "hops");
        ]
      else []
    in
    let list_size_decls =
      let to_bare_name_stack (decl : decl) =
        match decl with
        | Decl (Tele, List (_, m), vn) ->
            [
              (BBareName (vn ^ "_preamble_t"), vn ^ "_preamble");
              (BBareNameStack (m, vn), vn);
            ]
        | _ -> []
      in
      List.flatten (List.map to_bare_name_stack tpc_decls)
    in
    List.append base_decls (List.append path_decls list_size_decls)
  in
  mk_p4struct p4struct_decls "hydra_header_t"

let get_parser (tpc_decls : decl list) (b : built_ins) =
  let basic_parser_state_wrapper (var : string) (tr_var : string) :
      Petr4.Surface.Parser.state =
    {
      tags = p4info_tpc;
      annotations = [];
      name =
        (if var = "start" then mk_p4string var else mk_p4string ("parse_" ^ var));
      statements =
        [
          Petr4.Surface.Statement.MethodCall
            {
              tags = p4info_tpc;
              func = mk_named_expression_member "packet" "extract";
              type_args = [];
              args =
                [
                  Petr4.Surface.Argument.Expression
                    {
                      tags = p4info_tpc;
                      value =
                        mk_named_expression_member "hydra_header"
                          (if var = "start" then "eth_type" else var);
                    };
                ];
            };
        ];
      transition =
        Petr4.Surface.Parser.Direct
          { tags = p4info_tpc; next = mk_p4string tr_var };
    }
  in
  let list_preamble_parser_state_wrapper (var : string) (tr_var : string) :
      Petr4.Surface.Parser.state =
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string ("parse_" ^ var ^ "_preamble");
      statements =
        [
          Petr4.Surface.Statement.MethodCall
            {
              tags = p4info_tpc;
              func = mk_named_expression_member "packet" "extract";
              type_args = [];
              args =
                [
                  Petr4.Surface.Argument.Expression
                    {
                      tags = p4info_tpc;
                      value =
                        mk_named_expression_member "hydra_header"
                          (var ^ "_preamble");
                    };
                ];
            };
          Petr4.Surface.Statement.Assignment
            {
              tags = p4info_tpc;
              lhs = mk_named_expression_member "hydra_metadata" "num_list_items";
              rhs =
                mk_named_expression_member2 "hydra_header" (var ^ "_preamble")
                  ("num_items_" ^ var);
            };
        ];
      transition =
        Petr4.Surface.Parser.Select
          {
            tags = p4info_tpc;
            exprs =
              [ mk_named_expression_member "hydra_metadata" "num_list_items" ];
            cases =
              [
                {
                  tags = p4info_tpc;
                  matches =
                    [
                      Petr4.Surface.Match.Expression
                        { tags = p4info_tpc; expr = mk_const_int_expression 0 };
                    ];
                  next = mk_p4string tr_var;
                };
                {
                  tags = p4info_tpc;
                  matches =
                    [ Petr4.Surface.Match.Default { tags = p4info_tpc } ];
                  next = mk_p4string ("parse_" ^ var);
                };
              ];
          };
    }
  in
  let list_item_parser_state_wrapper (var : string) (tr_var : string) :
      Petr4.Surface.Parser.state =
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string ("parse_" ^ var);
      statements =
        [
          Petr4.Surface.Statement.MethodCall
            {
              tags = p4info_tpc;
              func = mk_named_expression_member "packet" "extract";
              type_args = [];
              args =
                [
                  Petr4.Surface.Argument.Expression
                    {
                      tags = p4info_tpc;
                      value =
                        mk_named_expression_member2 "hydra_header" var "next";
                    };
                ];
            };
          Petr4.Surface.Statement.Assignment
            {
              tags = p4info_tpc;
              lhs = mk_named_expression_member "hydra_metadata" "num_list_items";
              rhs =
                Petr4.Surface.Expression.BinaryOp
                  {
                    tags = p4info_tpc;
                    op = Petr4.Surface.Op.Minus { tags = p4info_tpc };
                    args =
                      ( mk_named_expression_member "hydra_metadata"
                          "num_list_items",
                        mk_const_int_expression 1 );
                  };
            };
        ];
      transition =
        Petr4.Surface.Parser.Select
          {
            tags = p4info_tpc;
            exprs =
              [ mk_named_expression_member "hydra_metadata" "num_list_items" ];
            cases =
              [
                {
                  tags = p4info_tpc;
                  matches =
                    [
                      Petr4.Surface.Match.Expression
                        { tags = p4info_tpc; expr = mk_const_int_expression 0 };
                    ];
                  next = mk_p4string tr_var;
                };
                {
                  tags = p4info_tpc;
                  matches =
                    [ Petr4.Surface.Match.Default { tags = p4info_tpc } ];
                  next = mk_p4string ("parse_" ^ var);
                };
              ];
          };
    }
  in
  let list_var_names =
    let path_item = if b.path then [ "hops" ] else [] in
    let get_list_preamble_var (decl : decl) =
      match decl with Decl (Tele, List _, vn) -> [ vn ] | _ -> []
    in
    List.append path_item
      (List.flatten (List.map get_list_preamble_var tpc_decls))
  in
  let tr_var_from_variables =
    if List.length list_var_names == 0 then "accept"
    else "parse_" ^ List.hd list_var_names ^ "_preamble"
  in
  let list_preamble_parser_states =
    let prepare_var (s : string) = "parse_" ^ s ^ "_preamble" in
    let tr_vars = List.map prepare_var list_var_names in
    List.map2 list_preamble_parser_state_wrapper list_var_names
      (List.tl (List.append tr_vars [ "accept" ]))
  in
  let list_item_parser_states =
    let prepare_var (s : string) = "parse_" ^ s ^ "_preamble" in
    let tr_vars = List.map prepare_var list_var_names in
    List.map2 list_item_parser_state_wrapper list_var_names
      (List.tl (List.append tr_vars [ "accept" ]))
  in
  let parser_states =
    (* let vars = [ "eth_type"; "variables" ] in *)
    let vars = [ "start"; "variables" ] in
    let tr_vars = [ "parse_variables"; tr_var_from_variables ] in
    List.flatten
      [
        List.map2 basic_parser_state_wrapper vars tr_vars;
        list_preamble_parser_states;
        list_item_parser_states;
      ]
  in
  Petr4.Surface.Declaration.Parser
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string "CheckerHeaderParser";
      type_params = [];
      params =
        [
          mk_p4parameter_generic None (BBareName "packet_in", "packet");
          mk_p4parameter_generic
            (Some (Petr4.Surface.Direction.Out { tags = p4info_tpc }))
            (BBareName "hydra_header_t", "hydra_header");
          mk_p4parameter_generic
            (Some (Petr4.Surface.Direction.InOut { tags = p4info_tpc }))
            (BBareName "hydra_metadata_t", "hydra_metadata");
        ];
      constructor_params = [];
      locals = [];
      states = parser_states;
    }

let get_deparser (tpc_decls : decl list) (b : built_ins) =
  let emits =
    let base_emits = [ "eth_type"; "variables" ] in
    let path_emits = if b.path then [ "hops_preamble"; "hops" ] else [] in
    let list_emits =
      let list_emit (decl : decl) =
        match decl with
        | Decl (Tele, List _, vn) -> [ vn ^ "_preamble"; vn ]
        | _ -> []
      in
      List.append path_emits (List.flatten (List.map list_emit tpc_decls))
    in
    List.append base_emits list_emits
  in
  let emit_stmt_wrapper (emit : string) =
    Petr4.Surface.Statement.MethodCall
      {
        tags = p4info_tpc;
        func = mk_named_expression_member "packet" "emit";
        type_args = [];
        args =
          [
            Petr4.Surface.Argument.Expression
              {
                tags = p4info_tpc;
                value = mk_named_expression_member "hydra_header" emit;
              };
          ];
      }
  in
  Petr4.Surface.Declaration.Control
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string "CheckerHeaderDeparser";
      type_params = [];
      params =
        [
          mk_p4parameter_generic None (BBareName "packet_out", "packet");
          mk_p4parameter_generic
            (Some (Petr4.Surface.Direction.In { tags = p4info_tpc }))
            (BBareName "hydra_header_t", "hydra_header");
        ];
      constructor_params = [];
      locals = [];
      apply =
        {
          tags = p4info_tpc;
          annotations = [];
          statements = List.map emit_stmt_wrapper emits;
        };
    }

let get_first_or_last_hop_action is_first =
  let last_hop_act_name = "set_last_hop" in
  let last_hop_var = "last_hop" in
  let first_hop_act_name = "set_first_hop" in
  let first_hop_var = "first_hop" in
  let act_name = if is_first then first_hop_act_name else last_hop_act_name in
  let var = if is_first then first_hop_var else last_hop_var in
  Petr4.Surface.Declaration.Action
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string act_name;
      params = [];
      body =
        {
          tags = p4info_tpc;
          annotations = [];
          statements =
            [
              Assignment
                {
                  tags = p4info_tpc;
                  lhs = mk_named_expression_member "hydra_metadata" var;
                  rhs = True { tags = p4info_tpc };
                };
            ];
        };
    }

let get_first_or_last_hop_table is_first =
  let last_hop_act_name = "set_last_hop" in
  let last_hop_table_name = "tb_check_last_hop" in
  let last_hop_port_ref = "egress_port" in
  let first_hop_act_name = "set_first_hop" in
  let first_hop_table_name = "tb_check_first_hop" in
  let first_hop_port_ref = "ingress_port" in
  let act_name = if is_first then first_hop_act_name else last_hop_act_name in
  let table_name =
    if is_first then first_hop_table_name else last_hop_table_name
  in
  let port_ref = if is_first then first_hop_port_ref else last_hop_port_ref in
  Petr4.Surface.Declaration.Table
    {
      tags = p4info_tpc;
      annotations = [];
      name = mk_p4string table_name;
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
                      mk_named_expression_member "standard_metadata" port_ref;
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
                    annotations =
                      [
                        {
                          tags = p4info_tpc;
                          name = mk_p4string "defaultonly";
                          body = Empty { tags = p4info_tpc };
                        };
                      ];
                    name = BareName { tags = p4info_tpc; str = "NoAction" };
                    args = [];
                  };
                  {
                    tags = p4info_tpc;
                    annotations = [];
                    name = BareName { tags = p4info_tpc; str = act_name };
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
              value = mk_const_int_expression 512;
            };
        ];
    }

let tpc_decls =
  [
    Decl (Tele, Bool, "a");
    Decl (Tele, Bit 3, "b");
    Decl (Tele, List (Bool, 10), "c");
    Decl (Tele, List (Bit 4, 3), "d");
    Decl (Tele, Bit 8, "e");
    Decl (Tele, List (Bit 6, 3), "f");
  ]

let b : built_ins =
  {
    path = false;
    path_length = false;
    packet_length = false;
    last_hop = false;
    first_hop = false;
    to_be_dropped = false;
  }

let to_p4_decls (tpc_decls : decl list) (built_ins : built_ins) =
  let header_decls =
    let list_header_decls = get_header_decls_for_list_vars tpc_decls in
    let base_header_decls =
      [
        mk_p4header [ (BBit 16, "value") ] "eth_type2_t";
        get_header_decl_for_variables_header tpc_decls built_ins;
      ]
    in
    List.append base_header_decls list_header_decls
  in
  let builtin_decls =
    let sub_builtin_decls1 =
      match built_ins.first_hop with
      | true ->
          [
            get_first_or_last_hop_action true; get_first_or_last_hop_table true;
          ]
      | false -> []
    in
    let sub_builtin_decls2 =
      match built_ins.last_hop with
      | true ->
          [
            get_first_or_last_hop_action false;
            get_first_or_last_hop_table false;
          ]
      | false -> []
    in
    List.append sub_builtin_decls1 sub_builtin_decls2
  in
  List.append
    (List.append header_decls
       [
         get_struct_decl_for_hydra_header tpc_decls b;
         get_struct_decl_for_hydra_metadata tpc_decls;
         get_parser tpc_decls b;
         get_deparser tpc_decls b;
       ])
    builtin_decls

let formatted_program =
  Petr4.Pretty.format_program (Petr4.Surface.Program (to_p4_decls tpc_decls b))

(*
TODOs:
- Sensor
  - locals
  - reads and writes
- Dictionary lkp metadata variables
- Think about reports and how that would work on v1model
- Specify the length of the path somewhere
- Optimize the path_length field to be the hops preamble field whenever both builtins are used
- optimization: instead of having one list_preamble header for each list variable, try to pack
    as many as possible into one preamble header which can be made to be long (e.g., 32 bits)
*)
