{
open Lexing
open Parser

exception LexingError of Info.t * string 

let current_line = ref 1
let current_fname = ref ""
let line_start = ref 1

let reset () =
  current_line := 1;
  current_fname := "";
  line_start := 1

let line_number () =
  !current_line

let filename () =
  !current_fname

let start_of_line () =
  !line_start

let set_line n =
  current_line  :=  n

let set_start_of_line c =
  line_start := c

let set_filename s =
  current_fname := s

let newline lexbuf =
  current_line := line_number() + 1 ;
  set_start_of_line (lexeme_end lexbuf)

let str2bool = function 
  | "true" -> true
  | "false" -> false
  | _ -> failwith "bad value in str2bool"

let info lexbuf : Info.t = 
  let f = filename () in
  let c1 = lexeme_start lexbuf in
  let c2 = lexeme_end lexbuf in
  let c = start_of_line () in
  let l = line_number() in
  Info.I { filename=f; line_start=l; line_end=None; col_start=c1-c; col_end=c2-c }

let parse_int = Core.Int.of_string
}
let digit = ['0'-'9']
let int = '-'? digit+
let whitespace = [' ' '\t']+
let ident = ['A'-'Z' 'a'-'z' '_'] ['A'-'Z' 'a'-'z' '0'-'9' '_']*
let header_loc = ['@'] ['A'-'Z' 'a'-'z' '_'] ['A'-'Z' 'a'-'z' '0'-'9' '_' '.' '(' ')']*
let newline = '\r' | '\n' | "\r\n"
let boolean = "true" | "false"

rule token = parse
| "//"
  { singleline_comment lexbuf; token lexbuf }
| newline
  { newline lexbuf; token lexbuf }
| whitespace
  { token lexbuf } 
| "init"
  { INIT (info lexbuf) }
| "telemetry"
  { TELEMETRY (info lexbuf) }
| "check"
  { CHECK (info lexbuf) }
| int as n
  {INT (info lexbuf, parse_int n) }
| boolean as b 
  {BOOLEAN_CONST (info lexbuf, str2bool b)}
| "bit" 
  {BIT (info lexbuf)}
| "bool" 
  {BOOLEAN (info lexbuf)}
| "set" 
  {SET (info lexbuf)}
| "dict" 
  {DICT (info lexbuf)}
|  "+" 
  {PLUS (info lexbuf)}
|  "-" 
  {MINUS (info lexbuf)}
|  "*" 
  {TIMES (info lexbuf)}
|  "/" 
  {DIVIDE (info lexbuf)}
|  "%" 
  {MODULUS (info lexbuf)}
|  "|" 
  {BOR (info lexbuf)}
|  "&" 
  {BAND (info lexbuf)}
|  "~" 
  {BNOT (info lexbuf)}
|  "^" 
  {BXOR (info lexbuf)}
|  "<" 
  {LT (info lexbuf)}
| ">" 
  {GT (info lexbuf)}
| "<="
  {LE (info lexbuf)}
| ">="
  {GE (info lexbuf)}
| "=="
  {EQ (info lexbuf)}
| "!="
  {NE (info lexbuf)}
| "="
  {EQUALS(info lexbuf)}
| "{" 
  {LBLOCK (info lexbuf)}
| "}" 
  {RBLOCK (info lexbuf)}
| "[" 
  {LBRACKET (info lexbuf)}
| "]" 
  {RBRACKET (info lexbuf)}
| "(" 
  {LPAREN (info lexbuf)}
| ")" 
  {RPAREN (info lexbuf)}
| ";" 
  {SEMICOLON (info lexbuf)}
(* | ":" 
  {COLON (info lexbuf)} *)
| "," 
  {COMMA (info lexbuf)}
| "." 
  {DOT  (info lexbuf)}
| "&&" 
  {LAND  (info lexbuf)}
| "||" 
  {LOR  (info lexbuf)}
| "!" 
  {LNOT (info lexbuf)}
| "max" 
  {MAX (info lexbuf)}
| "min" 
  {MIN (info lexbuf)}
| "abs" 
  {ABS (info lexbuf)}
| "push"
  {PUSH (info lexbuf)}
| "if" 
  {IF (info lexbuf)}
| "else" 
  {ELSE (info lexbuf)}
| "elif" 
  {ELIF (info lexbuf)}
| "for" 
  {FOR (info lexbuf)}
| "in" 
  {IN (info lexbuf)}
| "not" 
  {NOT (info lexbuf)}
| "reject" 
  {REJECT (info lexbuf)}
| "path" 
  {PATH (info lexbuf)}
| "length"
  {LENGTH (info lexbuf)}
| "path_length" 
  {PATH_LENGTH (info lexbuf)}
| "first_hop" 
  {FIRST_HOP (info lexbuf)}
| "last_hop" 
  {LAST_HOP (info lexbuf)}
(* | "now" 
  {NOW (info lexbuf)} *)
| "packet_length" 
  {PACKET_LENGTH (info lexbuf)}
| "to_be_dropped" 
  {TO_BE_DROPPED (info lexbuf)}
| "tele" 
  {TELE (info lexbuf)}
| "sensor" 
  {SENSOR (info lexbuf)}
| "control" 
  {CONTROL (info lexbuf)}
| "header" 
  {HEADER (info lexbuf)}
| "pass"
  {PASS (info lexbuf)}
| ident as i 
  { IDENT (info lexbuf, i) } 
| header_loc as h 
  { HEADER_LOC (info lexbuf, h)}
| eof
  { EOF(info lexbuf) }
| _ { raise (LexingError (info lexbuf, "Character not allowed in source text: '" ^ Lexing.lexeme lexbuf ^ "'")) }

and singleline_comment = parse
| '\n'
  { newline lexbuf }
| eof
  { () }
| _
  { singleline_comment lexbuf }
