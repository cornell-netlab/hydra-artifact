# Examples

This directory contains Indus programs for each of the properties listed in Section 6.1, Table 1. It is organized into sub-directories, with one sub-directory per example. Note that the Application Filtering program is given in `studies/aether` rather than here, as it goes with that case study.

There is also a `misc/` sub-directory with a few extra Indus programs, and a `basic_topology.json` file with a single-node topology that can be used for testing. 

## Running the Indus Compiler

To run the Indus compiler, execute the following commands
```bash
tpc <path_to_tpc_program> <path_to_topology_json>
```
Note that the executable is named `tpc` for "Tiny Packet Checkers," which was an older name for the compiler.

When the compiler finishes, it will create (and clobber!) a directory named `generated_p4` in the same directory as the `tpc` program with the snippets of P4 code for the data types, initialization, telemetry, and checking code in the original program. This generated code can be "linked" with a base forwarding program -- see the discussion in `studies/valley_free` for instructions on how to do this linking. 

## V1Model Programs

We provide versions of P4 programs for the V1Model architecture for each example in a sub-sub-directory named `v1model`. 

## TNA Programs

We also provide versions of P4 programs for the Tofino Native Architecture (TNA) for each example in a sub-sub-directory named `tna`. Currently some of these programs are tweaked by hand to allow them to compile to the Tofino switch.
