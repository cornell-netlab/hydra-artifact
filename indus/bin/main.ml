(* Copyright 2023-present Cornell University
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *)

open Core
open Command.Let_syntax
open Tpc
open Topology_parser

let create_formatted_program
    (Ast.Program (decs, init, telemetry, checker) as prog) built_ins is_leaf =
  let symbol_t = Ast_util.symbol_table prog in
  let parser_decls = Codegen.to_p4_decls decs built_ins in
  let petr4_telemetry = Programgen.transform_telemetry telemetry symbol_t in
  let program =
    Petr4.Surface.Program
      (parser_decls
      @
      if not is_leaf then [ petr4_telemetry ]
      else
        let petr4_init = Programgen.transform_init init symbol_t in
        let petr4_checker = Programgen.transform_checker checker symbol_t in
        [ petr4_init; petr4_telemetry; petr4_checker ])
  in
  Petr4.Pretty.format_program program

(* let create_directory file =
   let change_directory_to_file_directory filepath =
     let directory = Filename.dirname filepath in
     Sys.chdir directory
   in
   () *)

let generate_from_topology prog built_ins tpc_file topology : unit =
  match topology with
  | { title; switches; topology = topo } ->
      let open Stdlib in
      Core_unix.chdir (Filename.dirname tpc_file);
      Printf.printf "Generating P4 files for %s and %d switches\n" title
        switches;
      let formatted_programs =
        List.map (fun (i, b) -> create_formatted_program prog built_ins b) topo
      in
      let directory = "generated_p4" in
      if Sys.file_exists directory then (
        (* The directory already exists, so delete it and create a new one *)
        let command = "rm -rf " ^ directory in
        ignore (Core_unix.system command);
        Sys.mkdir directory 0o777)
      else
        (* The directory does not exist, so create it *)
        Sys.mkdir directory 0o777;
      (* Change the current working directory to the newly created directory *)
      Core_unix.chdir directory;
      let print_file idx fmt_prog =
        let open_file =
          open_out (Printf.sprintf "hydra.v1model_%d.p4" (idx + 1))
        in
        let formatter = Format.formatter_of_out_channel open_file in
        Format.fprintf formatter "@[%a@]@\n" Pp.to_fmt fmt_prog;
        Format.pp_print_flush formatter ();
        close_out open_file
        (* Print the formatted string to the file *)
      in
      ignore (List.mapi print_file formatted_programs)

let generate_print_p4 prog built_ins : unit =
  let symbol_t = Ast_util.symbol_table prog in
  match prog with
  | Program (decs, init, telemetry, checker) ->
      (* let parser_decls = Codegen.to_p4_decls decs in *)
      let parser_decls = [] in
      let petr4_init = Programgen.transform_init init symbol_t in
      let petr4_telemetry = Programgen.transform_telemetry telemetry symbol_t in
      let petr4_checker = Programgen.transform_checker checker symbol_t in
      let program =
        Petr4.Surface.Program
          (parser_decls @ [ petr4_init; petr4_telemetry; petr4_checker ])
      in
      let formatted_prog = Petr4.Pretty.format_program program in
      Format.printf "@[%a@]@\n" Pp.to_fmt formatted_prog

let go verbose tpc_file topology_file : unit =
  Lexer.reset ();
  Lexer.set_filename tpc_file;
  let string = In_channel.(with_file tpc_file ~f:input_all) in
  let lexbuf = Lexing.from_string string in
  try
    let topology = Topology_parser.json2topology topology_file in
    Topology_parser.print_topology topology;
    let prog, built_ins = Parser.program Lexer.token lexbuf in
    Printf.printf "Successfully Parsed\n";
    Format.printf "@[%a@]@\n" Pp.to_fmt (Pretty.format_program prog);
    Type_checker.check_program prog;
    Format.printf "Succesfully Typechecked\n";
    (* generate_print_p4 prog built_ins *)
    generate_from_topology prog built_ins tpc_file topology
  with
  | Lexer.LexingError (info, s) -> Printf.printf "Lexing Error: %s\n" s
  | Type_checker.TypeError s -> Printf.printf "Type Error: %s\n" s
  | Type_checker.UndeclaredVar s -> Printf.printf "Undeclared Var Error: %s\n" s
  | Type_checker.DuplicateDecl s ->
      Printf.printf "Duplicate Declaration Error: %s\n" s
  | Failure s -> Printf.printf "Failure: %s\n" s
  | Sys_error s -> Printf.printf "Sys error: %s\n" s
  | _ ->
      Printf.eprintf "Parsing error\n%s: line %d\n" (Lexer.filename ())
        (Lexer.line_number ())

let command =
  Command.basic ~summary:"TPC: Tiny Packet Checkers"
    [%map_open
      let verbose = flag "-verbose" no_arg ~doc:"Verbose mode"
      and file = anon ("tpc_file" %: string)
      and top_file = anon ("top_file" %: string) in
      fun () -> go verbose file top_file]

let () = Command_unix.run ~version:"0.0.1" command
