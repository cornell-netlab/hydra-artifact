%{
open Ast     

let path = ref false
let path_length = ref false
let packet_length = ref false
let last_hop = ref false
let first_hop = ref false
let to_be_dropped = ref false
%}

(* TODO: 
 * deal with Hexadecimal and binary
*)


%token <Info.t> INIT
%token <Info.t> TELEMETRY
%token <Info.t> CHECK
%token <Info.t * string> IDENT
%token <Info.t * int> INT 
%token <Info.t * string> HEADER_LOC
// %token <Info.t * int> HEXADECIMAL (*TODO: should we parse as int in tree?*)
// %token <Info.t * int> BINARY 
%token <Info.t * bool> BOOLEAN_CONST 
%token <Info.t> PASS
(*types*)
%token <Info.t> BOOLEAN 
%token <Info.t> BIT 
%token <Info.t> SET
%token <Info.t> DICT 

(*net types*)
%token <Info.t> TELE
%token <Info.t> SENSOR
%token <Info.t> CONTROL
%token <Info.t> HEADER
(*Arithmetic operators*)
%token <Info.t> PLUS
%token <Info.t> MINUS
%token <Info.t> TIMES
%token <Info.t> DIVIDE
%token <Info.t> MODULUS
%token <Info.t> BOR
%token <Info.t> BAND
%token <Info.t> BNOT
%token <Info.t> BXOR
(*Relational Operators*)
%token <Info.t> LT
%token <Info.t> GT
%token <Info.t> LE
%token <Info.t> GE
%token <Info.t> EQ
%token <Info.t> NE
(*Assignment*)
%token <Info.t> EQUALS
(*Various Syntax elements*)
%token <Info.t> LBLOCK
%token <Info.t> RBLOCK
%token <Info.t> LBRACKET
%token <Info.t> RBRACKET
%token <Info.t> LPAREN
%token <Info.t> RPAREN
%token <Info.t> SEMICOLON
// %token <Info.t> COLON
%token <Info.t> COMMA
%token <Info.t> DOT
(*Logical Operator Keywords*)
%token <Info.t> LAND
%token <Info.t> LOR
%token <Info.t> LNOT
(*Computational keywords*)
%token <Info.t> MIN
%token <Info.t> MAX
%token <Info.t> ABS
%token <Info.t> LENGTH
%token <Info.t> PUSH
(*Branch Keywords*)
%token <Info.t> IF
%token <Info.t> ELSE
%token <Info.t> ELIF
(*Loop Keywords*)
%token <Info.t> FOR
%token <Info.t> IN
%token <Info.t> NOT
(*List Keywords
%token <Info.t> ANY
%token <Info.t> ALL
%token <Info.t> APPEND
%token <Info.t> MAP
%token <Info.t> FOLD
%token <Info.t> LAMBDA *)

(*TPC Keywords*)
%token <Info.t> REJECT
%token <Info.t> REPORT
// %token <Info.t> SWITCH
%token <Info.t> PATH
(*Special variables*)
%token <Info.t> PATH_LENGTH
%token <Info.t> FIRST_HOP
%token <Info.t> LAST_HOP
// %token <Info.t> NOW
%token <Info.t> PACKET_LENGTH
%token <Info.t> TO_BE_DROPPED

%token <Info.t > EOF

%nonassoc NOT IN
%left LOR LAND BOR BXOR BAND
%left EQ NE GT GE LT LE
%left PLUS MINUS
%left TIMES DIVIDE MODULUS
%right BNOT LNOT
%nonassoc LENGTH ABS 


%type <Ast.expr> expression
%type <Ast.statement> statement
%type <Ast.keyword> keyword

%start<Ast.program * built_ins> program
%start<unit> dummy

%%


program:
  | d=decl* i=init t=telemetry c=check EOF
    {(Program(d, i, t, c) , {
  path = !path;
  path_length = !path_length;
  packet_length = !packet_length;
  last_hop = !last_hop;
  first_hop = !first_hop;
  to_be_dropped = !to_be_dropped;
})}

init:
  | INIT c=codeblock {Init c}

telemetry:
  | TELEMETRY c=codeblock {Telemetry c}

check:
  | CHECK c=codeblock {Check c}

codeblock: 
  | LBLOCK st=statement* RBLOCK {st}

statement: 
  | PASS SEMICOLON {Pass}
  | t=var_type id=IDENT EQUALS e=expression SEMICOLON {Local_dec (t, snd id, e)}
  | id=IDENT EQUALS e=expression SEMICOLON {Assignment (snd id, e)}
  | IF LPAREN e=expression RPAREN c=codeblock ef=elif* el=_else? {Branch (e, c, ef, el)}
  | FOR LPAREN id=separated_list(COMMA, id) IN e=separated_list(COMMA, id) RPAREN c=codeblock {For (id, e, c)}
  | id=IDENT DOT PUSH LPAREN e=expression RPAREN SEMICOLON {Push (snd id, e)}
  | REPORT SEMICOLON {Exception (Report)}
  | REJECT SEMICOLON {Exception (Reject)}
id: 
  | i=IDENT {snd i}
elif: 
  | ELIF LPAREN e=expression RPAREN c=codeblock {Elif (e,c)}
_else:
  | ELSE c=codeblock {c}

expression:
  | LPAREN e=expression RPAREN {e}
  | id=IDENT {Var (snd id)}
  | v=value {Value v}
  | b=binary_expr {b}
  | u=uop e=expression {Uop (u, e)}
  | id=IDENT LBRACKET LPAREN tup=separated_list(COMMA, id) RPAREN RBRACKET {DictLookup (snd id, tup)}
  | id=IDENT LBRACKET e2=expression RBRACKET {ListIndex (snd id, e2)}
  | k=keyword {Keyword k}
  | b=built_in {b}

keyword:
  | PATH {path := true; Path}
  | PACKET_LENGTH {packet_length := true; Packet_length}
  | PATH_LENGTH {path_length := true; Path_length}
  | LAST_HOP {last_hop := true; Last_hop}
  | FIRST_HOP {first_hop := true; First_hop}
  | TO_BE_DROPPED {to_be_dropped := true; To_be_dropped}
  /* TODO: list indexing */

%inline binary_expr:
  | e1=expression b=binop e2=expression {Binop (b, e1, e2)}

%inline binop:
  | PLUS {Plus}
  | MINUS {Minus}
  | TIMES {Times}
  | DIVIDE {Divide}
  | MODULUS {Mod}
  | BAND {Band}
  | BOR {Bor}
  | EQ {Equals}
  | NE {NEqual}
  | LT {Lt}
  | LE {Le}
  | GE {Ge}
  | GT {Gt}
  | LAND {Land}
  | LOR  {Lor}
  | BXOR {Bxor}
  | NOT IN {Notin}
  | IN {In}

%inline uop:
  | BNOT {Bnot}
  | LNOT {Lnot}
  | ABS {Abs}
  | LENGTH {Length}

built_in:
  | MIN LPAREN e1=expression COMMA e2=expression RPAREN {Binop (Min, e1, e2)}
  | MAX LPAREN e1=expression COMMA e2=expression RPAREN {Binop (Max, e1, e2)}
  


value: 
  | i=INT {Int (snd i)}
  | b=BOOLEAN_CONST {Bool_const (snd b)} 
  | LBRACKET; vl=separated_list(COMMA,value); RBRACKET {List_const (vl)}

decl: 
  | nt = net_type t=var_type var=IDENT SEMICOLON { Decl (nt, t, snd var)}

net_type: 
  | TELE { Tele}
  | SENSOR {Sensor}
  | HEADER l=HEADER_LOC {Header (snd l)} 
  | CONTROL {Control} 

var_type: 
  | BIT LT i=INT GT 
    {Bit(snd i)}
  | b = BOOLEAN {Bool}
  | t=var_type LBRACKET i=INT RBRACKET {List(t,snd i)}
  | SET LT t=var_type GT {Set (t)} 
  |  DICT LT LPAREN k=separated_list(COMMA,var_type) RPAREN COMMA v=var_type GT {Dict (k, v)}
  | DICT LT k=var_type COMMA v=var_type GT {Dict ([k], v)} 

dummy:
  | INT { () }
  | IDENT { () }
