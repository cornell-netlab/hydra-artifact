type id = string
type tuple = id list
type net_type = Tele | Sensor | Header of id | Control

type keyword =
  | Path
  | Path_length
  | Packet_length
  | Last_hop
  | First_hop
  | To_be_dropped

type var_type =
  | Bit of int
  | Bool
  | List of var_type * int
  | Set of var_type
  | Dict of var_type list * var_type

type value = Int of int | Bool_const of bool | List_const of value list

type bop =
  | Plus
  | Minus
  | Times
  | Divide
  | Mod
  | Band
  | Bor
  | Bxor
  | Equals
  | NEqual
  | Lt
  | Le
  | Gt
  | Ge
  | Land
  | Lor
  | In
  | Notin
  | Min
  | Max

type uop = Bnot | Lnot | Abs | Length

type expr =
  | Var of id
  | Value of value
  | Binop of bop * expr * expr
  | Uop of uop * expr
  | ListIndex of id * expr
  | DictLookup of id * tuple
  | Keyword of keyword

type exn = Report | Reject

type statement =
  | Pass
  | Push of id * expr
  | Local_dec of var_type * id * expr
  | Assignment of id * expr
  | For of tuple * tuple * codeblock
  | Branch of expr * codeblock * elif list * _else option
  | Exception of exn

and _else = codeblock
and elif = Elif of expr * codeblock
and codeblock = statement list

type decl = Decl of net_type * var_type * id
type init = Init of codeblock
type telemetry = Telemetry of codeblock
type check = Check of codeblock
type program = Program of decl list * init * telemetry * check

type built_ins = {
  path : bool;
  path_length : bool;
  packet_length : bool;
  last_hop : bool;
  first_hop : bool;
  to_be_dropped : bool;
}
