# Building the Indus compiler.

The Indus compiler is written in OCaml and only has a few dependencies, notably [Petr4](https://github.com/verified-network-toolchain/petr4), which it uses to generate P4 code.

## Base Image

In principle, it should be possible to build and install the Indus compiler on any platform that the [OCaml Package Manager](https://opam.ocaml.org/) supports. These instructions have been tested on Ubuntu 20.04 and take about 15-20 minutes depending on the capabilities of the machine.

Note that some of the steps below may prompt you with questions. You can generally answer `Y` to all such questions. The one exception is that you may not want to permanently update your dot-files with OCaml enviornment variables. 

## Installing OCaml

Install `opam`.
```bash
apt install opam
```

Use `opam` to install version 4.14.0 of the OCaml compiler. 
```bash
opam init --compiler=4.14.0
eval $(opam env)
```

## Install Petr4 from source 

Install dependencies for Petr4.
```bash
sudo apt-get install m4 libgmp-dev
```

Install [p4pp](https://github.com/cornell-netlab/p4pp) from source.
```bash
git clone git@github.com:cornell-netlab/p4pp.git
opam pin add p4pp pp
```

Install Coq and `bignum`.
```bash
opam install coq
opam install bignum
```

Update `opam` with additional Coq libraries.
```bash
opam repo add coq-released https://coq.inria.fr/opam/released
opam pin add coq-vst-zlist https://github.com/PrincetonUniversity/VST.git
```

Clone, build, and install Petr4 using `dune`.
```bash
git clone git@github.com:verified-network-toolchain/petr4.git
cd petr4
opam install . --deps-only
opam exec -- dune build
dune install
cd ..
```

## Install Indus from source

```bash
cd indus
opam install . --deps-only
opam exec -- dune build
dune install
cd ..
```

## Check that Indus was built and installed successfully

If you issue the command,
```
tpc -help
```
you should get a usage message such as the following:
```
TPC: Tiny Packet Checkers

  tpc TPC_FILE TOP_FILE

=== flags ===

  [-verbose]                 . Verbose mode
  [-build-info]              . print info about this build and exit
  [-version]                 . print the version of this build and exit
  [-help], -?                . print this help text and exit
```
