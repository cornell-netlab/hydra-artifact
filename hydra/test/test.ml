open Tpc
open Core

exception TypeError
exception UndeclaredVar
exception DuplicateDecl

let dir = "test_examples/"
let exc_dir = dir ^ "type_errors/"

let exception_tests =
  let tests =
    [
      ("assignment", TypeError);
      ("assignment2", TypeError);
      ("binop", TypeError);
      ("binop2", TypeError);
      ("binop3", TypeError);
      ("dict", TypeError);
      ("dict2", TypeError);
      ("duplDecl", DuplicateDecl);
      ("for", TypeError);
      ("for2", TypeError);
      ("if", TypeError);
      ("list_index", TypeError);
      ("list_index2", TypeError);
      ("local_dec_dup", DuplicateDecl);
      ("local_dec_dup2", DuplicateDecl);
      ("local_dec_for", DuplicateDecl);
      ("local_dec_for2", DuplicateDecl);
      ("local_dec", TypeError);
      ("undeclared_var", UndeclaredVar);
      ("undeclared_var2", UndeclaredVar);
      ("undeclared_var_for", UndeclaredVar);
      ("empty_list", TypeError);
      ("list", TypeError);
      ("list_push", TypeError);
      ("list_push2", TypeError);
      ("list_push3", TypeError);
      ("dec_invalid_types", TypeError);
      ("header_assignment", TypeError);
    ]
  in
  Caml.List.map (function name, exc -> (exc_dir ^ name ^ ".tpc", exc)) tests

let success_tests =
  let tests =
    [
      "assignment";
      "comment";
      "declaration";
      "dict";
      "dict2";
      "empty";
      "for_pair";
      "for";
      "for2";
      "if";
      "list_index";
      "list_operators";
      "local_dec_scope";
      "local_dec_scope2";
      "local_dec";
      "operators";
    ]
  in
  Caml.List.map (fun name -> dir ^ name ^ ".tpc") tests

let map_exception = function
  | Type_checker.TypeError s -> TypeError
  | Type_checker.UndeclaredVar s -> UndeclaredVar
  | Type_checker.DuplicateDecl s -> DuplicateDecl
  | _ -> failwith "Impossible"

let type_check file =
  Lexer.reset ();
  Lexer.set_filename file;
  let string = In_channel.(with_file file ~f:input_all) in
  let lexbuf = Lexing.from_string string in
  let prog, built_ins = Parser.program Lexer.token lexbuf in
  try Type_checker.check_program prog with exc -> raise (map_exception exc)

let create_exn_test test =
  match test with
  | file_name, exn ->
      Alcotest.test_case file_name `Quick (fun () ->
          Alcotest.check_raises "same exception" exn (fun () ->
              type_check file_name))

let create_suc_test file_name =
  Alcotest.test_case file_name `Quick (fun () ->
      Alcotest.(check unit) "No exception" () (type_check file_name))

let () =
  let exception_tests = Caml.List.map create_exn_test exception_tests in
  let success_tests = Caml.List.map create_suc_test success_tests in
  Alcotest.run "Typechecking Alcotest Suite"
    [ ("Exception test", exception_tests); ("Success tests", success_tests) ]
