open Ast
open Pp
open Pp.O

let format_id = function id -> text id

let rec format_pair = function
  | [] -> text ""
  | [ id ] -> format_id id
  | id :: t -> format_id id ++ text ", " ++ format_pair t

let format_net_type = function
  | Tele -> text "tele"
  | Sensor -> text "sensor"
  | Header loc -> text ("header" ^ loc)
  | Control -> text "control"

let rec format_var_type = function
  | Bit n -> text "bit<" ++ text (string_of_int n) ++ text ">"
  | Bool -> text "bool"
  | List (v, n) ->
      format_var_type v ++ text "[" ++ text (string_of_int n) ++ text "]"
  | Set v -> text "set<" ++ format_var_type v ++ text ">"
  | Dict (k, v) ->
      text "dict<(" ++ format_vartype_pair k ++ text "), " ++ format_var_type v
      ++ text ">"

and format_vartype_pair = function
  | [] -> text ""
  | [ v ] -> format_var_type v
  | v :: t -> format_var_type v ++ text ", " ++ format_vartype_pair t

let rec format_values = function
  | [] -> text "]"
  | value :: values -> format_value value ++ format_values values

and format_value = function
  | Int n -> text (string_of_int n)
  | Bool_const b -> text (if b then "true" else "false")
  | List_const vs ->
      Pp.hbox
        (text "["
        ++ Pp.concat_map ~sep:(text "," ++ Pp.space) vs ~f:format_value
        ++ text "]")

let format_bop = function
  | Plus -> text "+"
  | Minus -> text "-"
  | Times -> text "*"
  | Divide -> text "/"
  | Mod -> text "%"
  | Band -> text "&"
  | Bor -> text "|"
  | Bxor -> text "^"
  | Equals -> text "=="
  | NEqual -> text "!="
  | Lt -> text "<"
  | Le -> text "<="
  | Gt -> text ">"
  | Ge -> text ">="
  | Land -> text "&&"
  | Lor -> text "||"
  | In -> text "in"
  | Notin -> text "not in"
  | Min -> text "min"
  | Max -> text "max"

let format_uop = function
  | Bnot -> text "~"
  | Lnot -> text "!"
  | Abs -> text "abs"
  | Length -> text "length" ++ Pp.space

let format_keyword = function
  | Path -> text "path"
  | Path_length -> text "path_length"
  | Packet_length -> text "packet_length"
  | Last_hop -> text "last_hop"
  | First_hop -> text "first_hop"
  | To_be_dropped -> text "to_be_dropped"

let rec format_expr = function
  | Var id -> format_id id
  | Value value -> format_value value
  | Binop (bop, e1, e2) ->
      box
        (format_expr e1 ++ Pp.space ++ format_bop bop ++ Pp.space
       ++ format_expr e2)
  | Uop (uop, e) -> format_uop uop ++ format_expr e
  | ListIndex (id, e2) ->
      box (format_id id ++ text "[" ++ format_expr e2 ++ text "]")
  | DictLookup (id, pair) ->
      box (format_id id ++ text "[(" ++ format_pair pair ++ text ")]")
  | Keyword k -> format_keyword k

let format_exn = function Reject -> text "reject" | Report -> text "report"

let rec format_statements = function
  | statements ->
      text "{" ++ Pp.newline ++ Pp.space ++ Pp.space
      ++ Pp.vbox (Pp.concat_map ~sep:Pp.space statements ~f:format_statement)
      ++ Pp.newline ++ text "}"

and format_statement = function
  | Pass -> text "pass" ++ text ";"
  | Push (id, expr) ->
      format_id id ++ text ".push(" ++ format_expr expr ++ text ");"
  | Exception exn -> format_exn exn ++ text ";"
  | Local_dec (typ, id, expr) ->
      Pp.hbox
        (format_var_type typ ++ Pp.space ++ format_id id ++ Pp.space ++ text "="
       ++ Pp.space ++ format_expr expr ++ text ";")
  | Assignment (id, expr) ->
      Pp.hbox
        (format_id id ++ Pp.space ++ Pp.text "=" ++ Pp.space ++ format_expr expr
       ++ text ";")
  | For (p1, p2, statements) ->
      Pp.hbox
        (text "for (" ++ format_pair p1 ++ Pp.space ++ text "in" ++ Pp.space
       ++ format_pair p2 ++ text ")" ++ Pp.space
        ++ format_statements statements)
  | Branch (expr, statements, elifs, else_option) ->
      Pp.hbox
        (text "if" ++ Pp.space ++ text "(" ++ format_expr expr ++ text ")"
       ++ Pp.space
        ++ format_statements statements
        ++ Pp.space ++ format_elifs elifs ++ Pp.space ++ format_else else_option
        )

and format_elifs = function
  | elifs -> Pp.concat_map ~sep:Pp.space elifs ~f:format_elif

and format_elif = function
  | Elif (expr, statements) ->
      Pp.hbox
        (text "elif" ++ Pp.space ++ text "(" ++ format_expr expr ++ text ")")
      ++ Pp.space
      ++ format_statements statements

and format_else = function
  | None -> text ""
  | Some statements -> text "else" ++ Pp.space ++ format_statements statements

let rec format_declarations = function
  | declarations ->
      Pp.concat_map ~sep:Pp.newline declarations ~f:format_declaration
      ++ Pp.newline

and format_declaration = function
  | Decl (nt, vt, id) ->
      Pp.hbox
        (format_net_type nt ++ Pp.space ++ format_var_type vt ++ Pp.space
       ++ format_id id ++ text ";")

let format_init = function
  | Init statements -> text "init" ++ Pp.space ++ format_statements statements

let format_tele = function
  | Telemetry statements ->
      text "tele" ++ Pp.space ++ format_statements statements

let format_check = function
  | Check statements -> text "check" ++ Pp.space ++ format_statements statements

let format_program = function
  | Program (declarations, init, tele, check) ->
      box
        (format_declarations declarations
        ++ Pp.newline ++ format_init init ++ Pp.newline ++ format_tele tele
        ++ Pp.newline ++ format_check check ++ Pp.newline)
