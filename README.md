# hydra-artifact

This repo contains the necesarry code and instructions to recreate the findings in our paper. 

Each result lives in its own directory. 
* hydra contains the source code for the compiler and the examples directory contains the Indus programs from the paper
* valley_free contains the mininet example for valley free source routing in figure 7 of the paper

**TODO:** 
* Directory for TNA examples (Sundar/Nate)
* Figure 12 (Joon)



# Instructions to build Hydra compiler

This tutorial requires an Ubuntu 20.04 install. 

## Installing OCaml

install opam 
```bash
apt install opam
```
initialize opam with the 4.14.0 OCaml compiler. 
```bash
opam init --compiler=4.14.0
```

### Install Petr4 from source 

clone the Petr4 repo
```bash
git clone git@github.com:verified-network-toolchain/petr4.git
```
install external dependencies
```bash
sudo apt-get install m4 libgmp-dev
```

install [p4pp](https://github.com/cornell-netlab/p4pp) from source
```bash
git clone git@github.com:cornell-netlab/p4pp.git
opam pin add p4pp <path to root of p4pp repo>
```

install coq and bignum
```bash
opam install coq
opam install bignum
```
build bundled dependencies
```bash
opam repo add coq-released https://coq.inria.fr/opam/released
opam pin add coq-vst-zlist https://github.com/PrincetonUniversity/VST.git
```
build and install with dune, inside the petr4 directory
```bash
opam install . --deps-only
opam exec -- dune build
dune install
```

install Hydra dependencies with opam inside the hydra directory
```bash
opam install . --deps-only
```
